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
}
