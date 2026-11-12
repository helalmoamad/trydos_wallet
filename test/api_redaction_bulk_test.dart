/// Logging must describe a payload, never reproduce it.
library;

import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/api/api_redaction.dart';

void main() {
  /// A data URL the size a real ID crop arrives at.
  String imageDataUrl({int kb = 300, String mime = 'image/jpeg'}) {
    final chars = (kb * 1024 * 4) ~/ 3;
    return 'data:$mime;base64,${'A' * chars}';
  }

  test('صورة base64 تُستبدل بوصفها لا بمحتواها', () {
    final body = {'frontImageData': imageDataUrl(kb: 300)};
    final logged = redactData(body) as Map;
    final value = logged['frontImageData'] as String;

    expect(value, startsWith('<image/jpeg'));
    expect(value, contains('KB>'));
    // The point of the whole exercise: none of the payload survives.
    expect(value.contains('AAAA'), isFalse);
    expect(value.length, lessThan(40));
  });

  test('الحجم المذكور قريب من الحقيقي', () {
    final value = redactData(imageDataUrl(kb: 300)) as String;
    final kb = int.parse(RegExp(r'~(\d+)KB').firstMatch(value)!.group(1)!);
    expect(kb, closeTo(300, 2));
  });

  test('نوع الوسائط يبقى — يفيد حين يرفض الخادم الصورة', () {
    expect(redactData(imageDataUrl(mime: 'image/png')), contains('image/png'));
  });

  test('سلسلة طويلة بلا data: تُوصف أيضاً', () {
    final value = redactData('B' * 5000) as String;
    expect(value, startsWith('<5000 chars'));
    expect(value.contains('BBBB'), isFalse);
  });

  test('النصوص القصيرة تمرّ كما هي', () {
    // Everything a reader actually parses by eye must stay readable.
    for (final text in ['pr.abc123', 'SUCCEEDED', 'syrian_national_id', '']) {
      expect(redactData(text), text);
    }
    expect(redactData('x' * 256), 'x' * 256);
    expect(redactData('x' * 257), isNot('x' * 257));
  });

  test('يعمل داخل الخرائط والقوائم المتداخلة', () {
    final body = {
      'kycSessionId': 'abc',
      'extracted': {'name': 'Tester', 'photo': imageDataUrl(kb: 120)},
      'images': [imageDataUrl(kb: 50), 'small'],
    };
    final logged = redactData(body) as Map;

    expect(logged['kycSessionId'], 'abc');
    final extracted = logged['extracted'] as Map;
    expect(extracted['name'], 'Tester');
    expect(extracted['photo'] as String, startsWith('<image/jpeg'));
    final images = logged['images'] as List;
    expect(images.first as String, startsWith('<image/jpeg'));
    expect(images.last, 'small');
  });

  test('الأسرار ما زالت تُحجب', () {
    // The pre-existing rule must survive the new one: a long credential is
    // redacted by key, not merely elided by length.
    const secret = 'HEADMIDDLEMIDDLEMIDDLEMIDDLETAIL';
    final logged = redactData({'token': 'Bearer $secret'}) as Map;
    final value = logged['token'] as String;

    expect(value, startsWith('Bearer'));
    // Only the documented 4-character tail survives, so two tokens stay
    // distinguishable without either being usable.
    expect(value.contains('HEAD'), isFalse);
    expect(value.contains('MIDDLE'), isFalse);
    expect(value.length, lessThan(secret.length));
  });

  test('الأرقام والمنطقيات لا تُمسّ', () {
    final logged =
        redactData({'selfieVsIdScore': 91.7, 'isPermanent': false}) as Map;
    expect(logged['selfieVsIdScore'], 91.7);
    expect(logged['isPermanent'], false);
  });
}
