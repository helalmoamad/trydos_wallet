import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/api/api_redaction.dart';

/// Redaction is a security control: if it silently stops matching, bearer
/// tokens start reaching logcat again with no visible symptom. These tests
/// pin the behaviour.
void main() {
  const jwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjEyMyJ9.abcdWXYZ';

  group('redactHeaders', () {
    test('redacts the bearer credential but keeps the scheme', () {
      final out = redactHeaders({'Authorization': 'Bearer $jwt'});
      final value = out['Authorization'] as String;

      expect(value, startsWith('Bearer '));
      expect(value, isNot(contains(jwt)));
      expect(value, contains('REDACTED'));
    });

    test('matches header names case-insensitively', () {
      for (final name in ['authorization', 'AUTHORIZATION', 'Authorization']) {
        final out = redactHeaders({name: 'Bearer $jwt'});
        expect(out[name], isNot(contains(jwt)), reason: 'leaked via $name');
      }
    });

    test('redacts cookies and api keys', () {
      final out = redactHeaders({
        'Cookie': 'session=supersecretvalue',
        'X-Api-Key': 'k-abcdef123456',
      });
      expect(out['Cookie'], isNot(contains('supersecretvalue')));
      expect(out['X-Api-Key'], isNot(contains('abcdef123456')));
    });

    test('leaves non-sensitive headers untouched', () {
      final out = redactHeaders({
        'Content-Type': 'application/json',
        'Accept-Language': 'ar',
      });
      expect(out['Content-Type'], 'application/json');
      expect(out['Accept-Language'], 'ar');
    });

    test('keeps a distinguishable tail so two tokens differ in logs', () {
      final a = redactHeaders({'Authorization': 'Bearer ${jwt}AAAA'});
      final b = redactHeaders({'Authorization': 'Bearer ${jwt}BBBB'});
      expect(a['Authorization'], isNot(b['Authorization']));
    });
  });

  group('redactData', () {
    test('redacts secret-looking keys in a flat map', () {
      final out = redactData({
        'token': jwt,
        'password': 'hunter2000',
        'otp': '123456',
        'amount': 500,
      }) as Map;

      expect(out['token'], isNot(contains(jwt)));
      expect(out['password'], isNot(contains('hunter2000')));
      expect(out['otp'], isNot('123456'));
      expect(out['amount'], 500, reason: 'non-secret fields must survive');
    });

    test('recurses into nested maps and lists', () {
      final out = redactData({
        'data': {
          'session': {'refreshToken': jwt},
          'items': [
            {'apiKey': 'k-secret-value'},
          ],
        },
      }) as Map;

      final session = (out['data'] as Map)['session'] as Map;
      expect(session['refreshToken'], isNot(contains(jwt)));

      final items = (out['data'] as Map)['items'] as List;
      expect((items.first as Map)['apiKey'], isNot(contains('secret-value')));
    });

    test('passes through primitives and null unchanged', () {
      expect(redactData(null), isNull);
      expect(redactData(42), 42);
      expect(redactData('plain body'), 'plain body');
    });

    test('does not mutate the caller\'s map', () {
      final original = {'token': jwt};
      redactData(original);
      expect(original['token'], jwt);
    });
  });
}
