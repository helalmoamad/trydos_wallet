/// Conformance tests for the KYC integration guide.
///
/// Each group names the section it pins down, so a future change that drifts
/// from the contract fails here with the clause it broke.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  group('§5.2 analyze-id — الأخطاء تصل بحالة HTTP 200', () {
    test('الخطأ يُقرأ من status/code لا من حالة HTTP', () {
      final response = KycAnalyzeIdResponse.fromJson(const {
        'status': 'error',
        'code': 'MISSING_CRITICAL_DATA',
        'message': "We couldn't read your full name and date of birth.",
        'side': 'front',
        'found': false,
        'missingFields': ['firstName', 'birthday'],
      });
      expect(response.isError, isTrue);
      expect(response.code, 'MISSING_CRITICAL_DATA');
      expect(response.missingFields, ['firstName', 'birthday']);
    });

    test('missingFields تغيب بسلام', () {
      final response = KycAnalyzeIdResponse.fromJson(const {
        'status': 'error',
        'code': 'NO_TEXT_DETECTED',
      });
      expect(response.missingFields, isEmpty);
    });

    test('وجه أمامي ناجح بلا صورة وجه = رفض', () {
      // The guide: the web rejects the front when idFaceImageData is absent.
      final response = KycAnalyzeIdResponse.fromJson(const {
        'status': 'success',
        'nextStep': 'REQUIRE_BACK',
        'side': 'front',
        'croppedImageData': 'data:image/jpeg;base64,CARD',
      });
      expect(response.isSuccess, isTrue);
      expect(response.hasIdFace, isFalse);
      expect(response.frontMissingIdFace, isTrue);
    });

    test('وجه أمامي ناجح مع صورة وجه = مقبول', () {
      final response = KycAnalyzeIdResponse.fromJson(const {
        'status': 'success',
        'nextStep': 'REQUIRE_BACK',
        'side': 'front',
        'idFaceImageData': 'data:image/jpeg;base64,FACE',
      });
      expect(response.frontMissingIdFace, isFalse);
      expect(response.hasIdFace, isTrue);
    });

    test('الظهر لا يُطالَب بصورة وجه', () {
      // Back success carries no idFaceImageData by design.
      final response = KycAnalyzeIdResponse.fromJson(const {
        'status': 'success',
        'nextStep': 'COMPLETE',
        'side': 'back',
      });
      expect(response.frontMissingIdFace, isFalse);
      expect(response.isPassport, isFalse);
    });

    test('COMPLETE على الوجه الأمامي = جواز سفر', () {
      final response = KycAnalyzeIdResponse.fromJson(const {
        'status': 'success',
        'nextStep': 'COMPLETE',
        'side': 'front',
        'idFaceImageData': 'data:image/jpeg;base64,FACE',
      });
      expect(response.isPassport, isTrue);
    });
  });

  group('§14.7 countryIso3 يُقرأ ويُعاد إرساله', () {
    test('مسار Textract يعطي ISO-3', () {
      final extracted = KycExtractedData.fromJson(const {
        'idType': 'passport',
        'country': 'Syria',
        'countryIso3': 'SYR',
      });
      expect(extracted.countryIso3, 'SYR');
      expect(extracted.toJson()['countryIso3'], 'SYR');
    });

    test('مسارات SY/TR/LB لا تعطيه فيُحذف من الحمولة', () {
      final extracted = KycExtractedData.fromJson(const {'country': 'Syria'});
      expect(extracted.countryIso3, isNull);
      expect(extracted.toJson().containsKey('countryIso3'), isFalse);
    });
  });

  group('§9 حالات التحقق', () {
    KycStatusResponse status(String value) =>
        KycStatusResponse.fromJson(<String, dynamic>{'status': value});

    test('approved و passed تُعامَلان كموثَّق', () {
      for (final value in ['verified', 'approved', 'passed']) {
        expect(status(value).isVerified, isTrue, reason: value);
        expect(status(value).canStartVerification, isFalse, reason: value);
      }
    });

    test('expired معروفة ولا تُخلط بالرفض', () {
      expect(status('expired').isExpired, isTrue);
      expect(status('expired').isRejected, isFalse);
      expect(status('expired').isNotSubmitted, isFalse);
      // The user must verify again.
      expect(status('expired').canStartVerification, isTrue);
    });

    test('pending لا يدخل التدفق', () {
      expect(status('pending').canStartVerification, isFalse);
    });

    test('حالة مجهولة أو غائبة تُعامَل كغير مُقدَّمة', () {
      expect(status('').isNotSubmitted, isTrue);
      expect(status('something_new').isNotSubmitted, isTrue);
      expect(status('something_new').canStartVerification, isTrue);
    });

    test('الحالة تُطبَّع إلى أحرف صغيرة', () {
      expect(status('VERIFIED').isVerified, isTrue);
      expect(status('  Pending ').isPending, isTrue);
    });
  });

  group('نجاح بلا بيانات حرجة — رخصة القيادة التركية', () {
    /// The real response a Turkish driving licence came back with: a success
    /// carrying a surname and a document number, and empty strings where the
    /// name, national number and birthday should be.
    KycAnalyzeIdResponse licence({String side = 'back'}) {
      return KycAnalyzeIdResponse.fromJson(<String, dynamic>{
        'status': 'success',
        'nextStep': 'COMPLETE',
        'side': side,
        'found': true,
        'croppedImageData': 'data:image/jpeg;base64,CARD',
        'extractedData': {
          'idType': 'DRIVER LICENSE FRONT',
          'idName': 'DRIVER LICENSE FRONT',
          'country': 'Turkey',
          'name': '',
          'nationalNumber': '',
          'birthday': '',
          'lastName': 'WICK',
          'documentNumber': 'A12Z34567',
        },
      });
    }

    test('تُرفض: لا اسم ولا تاريخ ميلاد', () {
      // Rendering this fills the summary with blank rows and submits a record
      // with nobody on it.
      expect(licence().isSuccess, isTrue);
      expect(licence().hasCriticalFields, isFalse);
    });

    test('الخادم يقول back على التقاط وجه أمامي', () {
      expect(licence().resolvedSide, 'back');
    });

    test('سجل كامل يمرّ', () {
      final full = KycAnalyzeIdResponse.fromJson(const {
        'status': 'success',
        'nextStep': 'REQUIRE_BACK',
        'side': 'front',
        'idFaceImageData': 'data:image/jpeg;base64,FACE',
        'extractedData': {
          'name': 'BARIS GURBUZ',
          'lastName': 'GURBUZ',
          'birthday': '12.09.2003',
          'nationalNumber': '40096016028',
        },
      });
      expect(full.hasCriticalFields, isTrue);
      expect(full.resolvedSide, 'front');
      expect(full.frontMissingIdFace, isFalse);
    });

    test('اسم عائلة وتاريخ ميلاد يكفيان', () {
      // A surname alone still names someone, so long as a birthday backs it.
      final surnameOnly = KycAnalyzeIdResponse.fromJson(const {
        'status': 'success',
        'side': 'front',
        'extractedData': {'lastName': 'WICK', 'birthday': '01.01.1990'},
      });
      expect(surnameOnly.hasCriticalFields, isTrue);
    });

    test('اسم بلا تاريخ ميلاد لا يكفي', () {
      final noBirthday = KycAnalyzeIdResponse.fromJson(const {
        'status': 'success',
        'side': 'front',
        'extractedData': {'name': 'JOHN WICK', 'birthday': '   '},
      });
      expect(noBirthday.hasCriticalFields, isFalse);
    });

    test('غياب extractedData كلياً', () {
      final bare = KycAnalyzeIdResponse.fromJson(const {
        'status': 'success',
        'side': 'front',
      });
      expect(bare.hasCriticalFields, isFalse);
      expect(bare.resolvedSide, 'front');
    });
  });

  group('§5.2 الظهر يُكمل الوجه الأمامي لا يُستبدل به', () {
    KycExtractedData data(Map<String, dynamic> json) =>
        KycExtractedData.fromJson(json);

    test('الظهر يملأ ما تركه الوجه الأمامي فارغاً', () {
      // A Turkish card whose number the front could not read; the TD1 MRZ on
      // the back carries it.
      final front = data(const {
        'name': 'BARIS GURBUZ',
        'birthday': '12.09.2003',
        'country': 'Turkey',
        'nationalNumber': '',
      });
      final back = data(const {
        'nationalNumber': '40096016028',
        'documentNumber': 'A11R81293',
        'lastName': 'GURBUZ',
      });

      final merged = front.mergedWith(back);
      expect(merged.nationalNumber, '40096016028');
      expect(merged.documentNumber, 'A11R81293');
      expect(merged.lastName, 'GURBUZ');
      // Untouched where the front already read something.
      expect(merged.name, 'BARIS GURBUZ');
      expect(merged.birthday, '12.09.2003');
      expect(merged.country, 'Turkey');
    });

    test('الوجه الأمامي يفوز دائماً عند الاختلاف', () {
      // A barcode disagreeing with the printed face is not a correction to
      // apply behind the user's back.
      final front = data(const {'nationalNumber': '11111111', 'name': 'REAL'});
      final back = data(const {'nationalNumber': '99999999', 'name': 'OTHER'});

      final merged = front.mergedWith(back);
      expect(merged.nationalNumber, '11111111');
      expect(merged.name, 'REAL');
    });

    test('الفراغات النصّية تُعامَل كغياب', () {
      final front = data(const {'documentNumber': '   ', 'lastName': ''});
      final back = data(const {'documentNumber': 'X99', 'lastName': 'WICK'});

      final merged = front.mergedWith(back);
      expect(merged.documentNumber, 'X99');
      expect(merged.lastName, 'WICK');
    });

    test('ظهر فارغ لا يمحو شيئاً', () {
      final front = data(const {
        'name': 'BARIS GURBUZ',
        'nationalNumber': '40096016028',
      });

      expect(front.mergedWith(null).name, 'BARIS GURBUZ');
      final mergedWithBlank = front.mergedWith(data(const {}));
      expect(mergedWithBlank.name, 'BARIS GURBUZ');
      expect(mergedWithBlank.nationalNumber, '40096016028');
    });

    test('الدمج يحفظ countryIso3', () {
      final merged = data(const {
        'country': 'Syria',
      }).mergedWith(data(const {'countryIso3': 'SYR'}));
      expect(merged.countryIso3, 'SYR');
      expect(merged.country, 'Syria');
    });
  });
}
