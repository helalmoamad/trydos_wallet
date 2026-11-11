/// Models for the AWS Face Liveness path (`/api/kyc/liveness-aws`,
/// `/api/kyc/liveness-credentials`).
///
/// This is the path the integration guide calls the recommended one for
/// enrolment: the native Amplify UI detector streams video straight to AWS
/// Rekognition, and the Worker only mints the session and the credentials.
/// Nothing here judges the result — the confidence AWS returns is forwarded
/// untouched to NestJS, which applies `KYC_MIN_LIVENESS`.
library;

/// Response of `POST /api/kyc/liveness-aws` — a fresh AWS Face Liveness
/// session for the native detector to run.
///
/// Takes no request body and no KYC session: it is the credentials call that
/// is tied to the user's KYC session.
class KycAwsLivenessSession {
  const KycAwsLivenessSession({required this.sessionId, required this.region});

  /// AWS session id — handed to the native detector, then used to read the
  /// result back. Never reused after a failure.
  final String sessionId;

  /// AWS region the session lives in (e.g. `us-east-1`).
  final String region;

  bool get isValid => sessionId.isNotEmpty && region.isNotEmpty;

  factory KycAwsLivenessSession.fromJson(Map<String, dynamic> json) {
    return KycAwsLivenessSession(
      sessionId: (json['sessionId'] ?? '').toString(),
      region: (json['region'] ?? '').toString(),
    );
  }
}

/// Response of `POST /api/kyc/liveness-credentials` — temporary STS
/// credentials for the native detector's `AWSCredentialsProvider`.
///
/// Issued by `GetFederationToken` with a policy allowing only
/// `rekognition:StartFaceLivenessSession`, and they live ~900 seconds, so the
/// provider must re-fetch once [expiration] has passed.
class KycAwsCredentials {
  const KycAwsCredentials({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.sessionToken,
    this.expiration,
  });

  final String accessKeyId;
  final String secretAccessKey;
  final String sessionToken;

  /// When these credentials stop working. Null when the server omitted it —
  /// treat that as "refresh on the next use" rather than "never expires".
  final DateTime? expiration;

  bool get isComplete =>
      accessKeyId.isNotEmpty &&
      secretAccessKey.isNotEmpty &&
      sessionToken.isNotEmpty;

  /// True once [expiration] has passed. Unknown expiry counts as expired, so a
  /// detector never opens a session on credentials it cannot vouch for.
  bool get isExpired {
    final at = expiration;
    if (at == null) return true;
    return !DateTime.now().toUtc().isBefore(at.toUtc());
  }

  factory KycAwsCredentials.fromJson(Map<String, dynamic> json) {
    return KycAwsCredentials(
      accessKeyId: (json['accessKeyId'] ?? '').toString(),
      secretAccessKey: (json['secretAccessKey'] ?? '').toString(),
      sessionToken: (json['sessionToken'] ?? '').toString(),
      expiration: DateTime.tryParse((json['expiration'] ?? '').toString()),
    );
  }

  /// Shape handed across the platform channel to the native credentials
  /// provider. ISO-8601 so both SDKs can parse the expiry as a date.
  Map<String, dynamic> toChannelMap() => {
    'accessKeyId': accessKeyId,
    'secretAccessKey': secretAccessKey,
    'sessionToken': sessionToken,
    if (expiration != null) 'expiration': expiration!.toUtc().toIso8601String(),
  };
}

/// Response of `GET /api/kyc/liveness-aws?sessionId=…` — the verdict AWS
/// reached for one session.
///
/// Only read this after the native detector's completion callback; earlier it
/// answers `CREATED` or `IN_PROGRESS`.
class KycAwsLivenessResult {
  const KycAwsLivenessResult({
    required this.status,
    required this.confidence,
    this.livenessImageData,
  });

  /// `CREATED` | `IN_PROGRESS` | `SUCCEEDED` | `FAILED` | `EXPIRED`.
  final String status;

  /// AWS liveness confidence, 0–100. Forwarded to NestJS as
  /// `livenessConfidence` — never thresholded on the device.
  final double confidence;

  /// The reference image AWS captured, as a `data:image/jpeg;base64,…` URL.
  /// This is the selfie of record: it goes to compare-face and to submit, and
  /// the app never captures one of its own on this path.
  final String? livenessImageData;

  bool get succeeded => status.trim().toUpperCase() == 'SUCCEEDED';

  /// Still running — the detector has not finished, so poll again rather than
  /// treating it as a failure.
  bool get isPending {
    final value = status.trim().toUpperCase();
    return value == 'CREATED' || value == 'IN_PROGRESS';
  }

  /// A succeeded session that carries the image the rest of the flow needs.
  bool get isUsable => succeeded && (livenessImageData?.isNotEmpty ?? false);

  factory KycAwsLivenessResult.fromJson(Map<String, dynamic> json) {
    return KycAwsLivenessResult(
      status: (json['status'] ?? 'UNKNOWN').toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      livenessImageData: json['livenessImageData'] as String?,
    );
  }
}
