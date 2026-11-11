import 'package:flutter_test/flutter_test.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  group('KycAwsLivenessSession', () {
    test('يقرأ الجلسة والمنطقة', () {
      final session = KycAwsLivenessSession.fromJson(const {
        'sessionId': 'f1a2b3c4',
        'region': 'us-east-1',
      });
      expect(session.sessionId, 'f1a2b3c4');
      expect(session.region, 'us-east-1');
      expect(session.isValid, isTrue);
    });

    test('جلسة ناقصة ليست صالحة', () {
      expect(
        KycAwsLivenessSession.fromJson(const {'region': 'us-east-1'}).isValid,
        isFalse,
      );
      expect(
        KycAwsLivenessSession.fromJson(const {'sessionId': 'x'}).isValid,
        isFalse,
      );
    });
  });

  group('KycAwsCredentials', () {
    KycAwsCredentials creds({String? expiration}) {
      return KycAwsCredentials.fromJson(<String, dynamic>{
        'accessKeyId': 'ASIAEXAMPLE',
        'secretAccessKey': 'secret',
        'sessionToken': 'token',
        if (expiration != null) 'expiration': expiration,
      });
    }

    test('يقرأ الاعتمادات ووقت الانتهاء', () {
      final c = creds(expiration: '2030-01-01T00:00:00Z');
      expect(c.accessKeyId, 'ASIAEXAMPLE');
      expect(c.isComplete, isTrue);
      expect(c.isExpired, isFalse);
    });

    test('اعتمادات منتهية', () {
      expect(creds(expiration: '2020-01-01T00:00:00Z').isExpired, isTrue);
    });

    test('غياب وقت الانتهاء يُعامل كمنتهٍ', () {
      // Safer than assuming they live forever: the provider refetches instead
      // of opening a session on credentials it cannot vouch for.
      expect(creds().isExpired, isTrue);
    });

    test('خريطة القناة تحمل ISO-8601', () {
      final map = creds(expiration: '2030-01-01T12:30:00Z').toChannelMap();
      expect(map['accessKeyId'], 'ASIAEXAMPLE');
      expect(map['secretAccessKey'], 'secret');
      expect(map['sessionToken'], 'token');
      expect(map['expiration'], '2030-01-01T12:30:00.000Z');
    });

    test('خريطة القناة تحذف وقت انتهاء غائب', () {
      expect(creds().toChannelMap().containsKey('expiration'), isFalse);
    });
  });

  group('KycAwsLivenessResult', () {
    KycAwsLivenessResult result(String status, {String? image}) {
      return KycAwsLivenessResult.fromJson(<String, dynamic>{
        'status': status,
        'confidence': 97.3,
        if (image != null) 'livenessImageData': image,
      });
    }

    test('النجاح يحمل الثقة والصورة', () {
      final r = result('SUCCEEDED', image: 'data:image/jpeg;base64,AAA');
      expect(r.succeeded, isTrue);
      expect(r.isUsable, isTrue);
      expect(r.confidence, 97.3);
    });

    test('نجاح بلا صورة ليس قابلاً للاستعمال', () {
      // compare-face and submit both need the reference image.
      expect(result('SUCCEEDED').isUsable, isFalse);
    });

    test('CREATED و IN_PROGRESS قيد التنفيذ لا فشل', () {
      expect(result('CREATED').isPending, isTrue);
      expect(result('IN_PROGRESS').isPending, isTrue);
      expect(result('CREATED').succeeded, isFalse);
    });

    test('FAILED و EXPIRED ليسا قيد التنفيذ ولا ناجحين', () {
      for (final status in ['FAILED', 'EXPIRED']) {
        expect(result(status).isPending, isFalse, reason: status);
        expect(result(status).succeeded, isFalse, reason: status);
      }
    });

    test('الثقة الغائبة صفر لا null', () {
      final r = KycAwsLivenessResult.fromJson(const {'status': 'SUCCEEDED'});
      expect(r.confidence, 0);
    });
  });
}
