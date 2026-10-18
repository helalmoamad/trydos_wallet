import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/utils/payment_request_crypto.dart';

void main() {
  const code = 'pr.88DqTiedSJmUbIKA-SmSkA';
  const account = '0000-0038';

  test('ينتج نفس صيغة الويب حرفياً', () {
    expect(
      PaymentRequestCrypto.build(code, account),
      'PAYREQ:pr.88DqTiedSJmUbIKA-SmSkA|0000-0038',
    );
  });

  test('يقرأ باركود الويب', () {
    // The exact string the web wallet renders.
    const webQr = 'PAYREQ:pr.88DqTiedSJmUbIKA-SmSkA|0000-0038';
    expect(PaymentRequestCrypto.readCode(webQr), code);
    expect(PaymentRequestCrypto.extractAccountNumber(webQr), account);
  });

  test('يقرأ ما ينتجه هو', () {
    final qr = PaymentRequestCrypto.build(code, account);
    expect(PaymentRequestCrypto.readCode(qr), code);
    expect(PaymentRequestCrypto.extractAccountNumber(qr), account);
  });

  test('ما زال يقرأ الصيغة المشفّرة القديمة', () {
    final legacyQr = PaymentRequestCrypto.encrypt(code, account);
    // Still the old shape: a base64 body, not the code itself.
    expect(legacyQr.contains(code), isFalse);
    expect(PaymentRequestCrypto.readCode(legacyQr), code);
  });

  test('مشفّر قديم بمفتاح خاطئ يُرفض بدل أن يُعاد كـ base64', () {
    final legacyQr = PaymentRequestCrypto.encrypt(code, account);
    // Same ciphertext, a different account number: the GCM tag fails. The
    // base64 body must not be handed back as though it were a plain code —
    // sending it on would spend one of the rate-limited lookup attempts.
    final tampered = legacyQr.replaceAll('|$account', '|0000-9999');
    expect(PaymentRequestCrypto.readCode(tampered), isNull);
  });

  test('جسم لا يحمل مساحة اسم معروفة يُرفض محلياً', () {
    expect(
      PaymentRequestCrypto.readCode('PAYREQ:hello-world|$account'),
      isNull,
    );
    expect(PaymentRequestCrypto.readCode('PAYREQ:pr.|$account'), isNull);
  });

  test('يقبل كود التاجر وكود العدّاد داخل الغلاف', () {
    expect(
      PaymentRequestCrypto.readCode('PAYREQ:mp.cwewkCUKhUSP|$account'),
      'mp.cwewkCUKhUSP',
    );
    expect(
      PaymentRequestCrypto.readCode('PAYREQ:4817302956|$account'),
      '4817302956',
    );
  });

  test('يرفض ما ليس بصيغة PAYREQ', () {
    expect(PaymentRequestCrypto.readCode('PAYREQ:no-pipe-here'), isNull);
    expect(PaymentRequestCrypto.readCode('PAYREQ:|$account'), isNull);
    expect(PaymentRequestCrypto.readCode('PAYREQ:$code|'), isNull);
  });

  test('isPayreqFormat يميّز الغلاف', () {
    expect(
      PaymentRequestCrypto.isPayreqFormat('PAYREQ:$code|$account'),
      isTrue,
    );
    expect(PaymentRequestCrypto.isPayreqFormat(code), isFalse);
    expect(PaymentRequestCrypto.isPayreqFormat('MERPAY:mp.abc'), isFalse);
  });

  test('يتسامح مع المسافات حول الكود ورقم الحساب', () {
    expect(
      PaymentRequestCrypto.build('  $code  ', '  $account  '),
      'PAYREQ:$code|$account',
    );
    expect(PaymentRequestCrypto.readCode('PAYREQ:$code| $account '), code);
  });
}
