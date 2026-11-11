/// §6.7 — does the back of the ID belong to the front already captured?
library;

import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/models/kyc/kyc_analyze_id_response.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/utils/id_side_verifier.dart';

void main() {
  KycExtractedData side({
    String? national,
    String? document,
    String? lastName,
  }) {
    return KycExtractedData(
      nationalNumber: national,
      documentNumber: document,
      lastName: lastName,
    );
  }

  IdSideVerdict check(KycExtractedData front, KycExtractedData back) =>
      verifyBackMatchesFront(front: front, back: back);

  group('الرقم الوطني — القاعدة الأولى', () {
    test('تطابق تام', () {
      final v = check(
        side(national: '03010112345'),
        side(national: '03010112345'),
      );
      expect(v.matched, isTrue);
      expect(v.field, IdSideField.nationalNumber);
    });

    test('فرق محرف واحد مقبول — خلط OCR بين 0 و 8', () {
      final v = check(
        side(national: '03010112345'),
        side(national: '03010112348'),
      );
      expect(v.matched, isTrue);
    });

    test('فرق محرفين مرفوض', () {
      final v = check(
        side(national: '03010112345'),
        side(national: '03010112399'),
      );
      expect(v.matched, isFalse);
      expect(v.field, IdSideField.nationalNumber);
    });

    test('بطاقة أخرى تماماً مرفوضة', () {
      final v = check(
        side(national: '03010112345'),
        side(national: '99887766554'),
      );
      expect(v.matched, isFalse);
    });

    test('الفواصل والمسافات تُهمَل', () {
      final v = check(
        side(national: '030-1011-2345'),
        side(national: '030 1011 2345'),
      );
      expect(v.matched, isTrue);
    });

    test('أقل من ٨ أرقام لا تُفعّل القاعدة', () {
      // Falls through to the document number instead.
      final v = check(
        side(national: '1234567', document: '123456'),
        side(national: '7654321', document: '123456'),
      );
      expect(v.field, IdSideField.documentNumber);
      expect(v.matched, isTrue);
    });
  });

  group('رقم الوثيقة — القاعدة الثانية', () {
    test('تُستعمل حين لا يوجد رقم وطني كافٍ', () {
      final v = check(side(document: 'A1234567'), side(document: 'A1234567'));
      expect(v.field, IdSideField.documentNumber);
      expect(v.matched, isTrue);
    });

    test('ستة أرقام هي الحد الأدنى', () {
      final v = check(
        side(document: '12345', lastName: 'OZTURK'),
        side(document: '99999', lastName: 'OZTURK'),
      );
      // Too short, so the last name decides instead.
      expect(v.field, IdSideField.lastName);
    });

    test('اختلاف حقيقي مرفوض', () {
      final v = check(side(document: '1234567'), side(document: '7654321'));
      expect(v.matched, isFalse);
    });
  });

  group('اسم العائلة — القاعدة الثالثة', () {
    test('تطابق', () {
      final v = check(side(lastName: 'OZTURK'), side(lastName: 'OZTURK'));
      expect(v.field, IdSideField.lastName);
      expect(v.matched, isTrue);
    });

    test('الحركات تُطوى — ÖZTÜRK = OZTURK', () {
      final v = check(side(lastName: 'ÖZTÜRK'), side(lastName: 'OZTURK'));
      expect(v.matched, isTrue);
    });

    test('حالة الأحرف لا تهم', () {
      final v = check(side(lastName: 'al-hassan'), side(lastName: 'ALHASSAN'));
      expect(v.matched, isTrue);
    });

    test('اسم مختلف مرفوض', () {
      final v = check(side(lastName: 'OZTURK'), side(lastName: 'YILMAZ'));
      expect(v.matched, isFalse);
    });

    test('حرف واحد لا يُفعّل القاعدة', () {
      final v = check(side(lastName: 'A'), side(lastName: 'B'));
      expect(v.field, IdSideField.none);
      expect(v.matched, isTrue);
    });
  });

  group('لا شيء قابل للمقارنة', () {
    test('ظهر بلا حقول مشتركة يُقبَل', () {
      // Common on cards whose MRZ repeats neither number nor name. Rejecting
      // would block valid documents; the server stays the authority.
      final v = check(side(national: '03010112345'), side());
      expect(v.matched, isTrue);
      expect(v.field, IdSideField.none);
      expect(v.wasComparable, isFalse);
    });

    test('جانبان فارغان يُقبلان', () {
      expect(check(side(), side()).matched, isTrue);
    });

    test('حقول فارغة نصّياً تُعامَل كغائبة', () {
      final v = check(
        side(national: '   ', document: '', lastName: '  '),
        side(national: '03010112345'),
      );
      expect(v.field, IdSideField.none);
      expect(v.matched, isTrue);
    });
  });

  test('القاعدة الأولى المنطبقة نهائية — لا تُراجَع بالقواعد التالية', () {
    // The national numbers disagree, so the matching last name must not
    // rescue it.
    final v = check(
      side(national: '03010112345', lastName: 'OZTURK'),
      side(national: '99887766554', lastName: 'OZTURK'),
    );
    expect(v.field, IdSideField.nationalNumber);
    expect(v.matched, isFalse);
  });
}
