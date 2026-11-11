import '../api/api.dart';
import '../models/kyc/kyc_aws_liveness.dart';
import 'face_liveness_detector.dart';
import 'kyc_api_service.dart';
import 'kyc_liveness_api_service.dart';

/// What one liveness attempt produced.
class FaceLivenessOutcome {
  const FaceLivenessOutcome._({
    required this.succeeded,
    this.confidence = 0,
    this.selfieImageData,
    this.status,
    this.errorKind,
    this.errorMessage,
  });

  const FaceLivenessOutcome.passed({
    required double confidence,
    required String selfieImageData,
  }) : this._(
         succeeded: true,
         confidence: confidence,
         selfieImageData: selfieImageData,
         status: 'SUCCEEDED',
       );

  const FaceLivenessOutcome.failed({
    String? status,
    FaceLivenessErrorKind? errorKind,
    String? errorMessage,
  }) : this._(
         succeeded: false,
         status: status,
         errorKind: errorKind,
         errorMessage: errorMessage,
       );

  final bool succeeded;

  /// AWS liveness confidence, 0–100. Submitted untouched as
  /// `livenessConfidence`; the device never thresholds it.
  final double confidence;

  /// The reference image AWS captured — the selfie of record for both
  /// compare-face and submit. Non-null whenever [succeeded].
  final String? selfieImageData;

  /// Raw AWS status when the run reached one (`FAILED`, `EXPIRED`, …).
  final String? status;

  final FaceLivenessErrorKind? errorKind;
  final String? errorMessage;
}

/// Runs one AWS Face Liveness attempt end to end.
///
/// The sequence, per the integration guide §7.1:
///
/// 1. ensure a KYC session exists (it is what the credentials call is bound to)
/// 2. `POST /liveness-aws` → the AWS session for the detector
/// 3. present the native detector; its credentials provider calls
///    `POST /liveness-credentials` with the KYC session
/// 4. after the detector completes, `GET /liveness-aws?sessionId=` for the
///    verdict and the reference image
///
/// Nothing here judges the person: a `SUCCEEDED` status is the only thing
/// checked, and the confidence travels on to the backend.
class FaceLivenessController {
  FaceLivenessController({
    required FaceLivenessDetector detector,
    KycLivenessApiService? livenessApi,
    KycApiService? kycApi,
  }) : _detector = detector,
       _livenessApi = livenessApi ?? KycLivenessApiService(),
       _kycApi = kycApi ?? KycApiService();

  final FaceLivenessDetector _detector;
  final KycLivenessApiService _livenessApi;
  final KycApiService _kycApi;

  /// Runs one attempt.
  ///
  /// [kycSessionId] is the session already open for this flow, or null to open
  /// one. [onSessionChanged] reports the id actually used — it changes when a
  /// session is opened here or renewed after a 401, and the caller must keep
  /// the new one for submit.
  ///
  /// Never throws: every failure comes back as a [FaceLivenessOutcome] so the
  /// screen has one thing to render.
  Future<FaceLivenessOutcome> run({
    required String? kycSessionId,
    required void Function(String? sessionId) onSessionChanged,
  }) async {
    var sessionId = kycSessionId;

    // 1. A KYC session has to exist before credentials can be minted.
    if (sessionId == null || sessionId.isEmpty) {
      sessionId = await _openSession();
      onSessionChanged(sessionId);
      if (sessionId == null) {
        return const FaceLivenessOutcome.failed(
          errorKind: FaceLivenessErrorKind.setupFailed,
          errorMessage: 'Could not open a verification session.',
        );
      }
    }

    // 2. A fresh AWS session for this attempt — never reuse one after a
    //    failure.
    final sessionResult = await _livenessApi.createAwsSession();
    final awsSession = sessionResult.data;
    if (!sessionResult.isSuccess || awsSession == null || !awsSession.isValid) {
      return FaceLivenessOutcome.failed(
        errorKind: FaceLivenessErrorKind.setupFailed,
        errorMessage: sessionResult.errorMessage,
      );
    }

    // 3. The detector owns the screen until the challenge ends.
    try {
      await _detector.present(
        sessionId: awsSession.sessionId,
        region: awsSession.region,
        credentialsProvider: () async {
          final credentials = await _credentials(
            kycSessionId: sessionId!,
            onRenewed: (renewed) {
              sessionId = renewed;
              onSessionChanged(renewed);
            },
          );
          if (credentials == null) {
            throw StateError('Could not issue liveness credentials.');
          }
          return credentials;
        },
      );
    } on FaceLivenessException catch (e) {
      return FaceLivenessOutcome.failed(
        errorKind: e.kind,
        errorMessage: e.message,
      );
    }

    // 4. Only now does the verdict exist; earlier it reads CREATED.
    final resultResponse = await _livenessApi.awsResult(
      sessionId: awsSession.sessionId,
    );
    final result = resultResponse.data;
    if (!resultResponse.isSuccess || result == null) {
      return FaceLivenessOutcome.failed(
        errorKind: FaceLivenessErrorKind.setupFailed,
        errorMessage: resultResponse.errorMessage,
      );
    }

    if (!result.isUsable) {
      // A SUCCEEDED verdict with no image is as unusable as a FAILED one:
      // compare-face and submit both need that image.
      return FaceLivenessOutcome.failed(status: result.status);
    }

    return FaceLivenessOutcome.passed(
      confidence: result.confidence,
      selfieImageData: result.livenessImageData!,
    );
  }

  /// Fetches STS credentials, renewing the KYC session once if it has been
  /// spent — the guide's prescribed recovery for a 401 here.
  Future<KycAwsCredentials?> _credentials({
    required String kycSessionId,
    required void Function(String sessionId) onRenewed,
  }) async {
    final first = await _livenessApi.awsCredentials(kycSessionId: kycSessionId);
    if (first.isSuccess && (first.data?.isComplete ?? false)) {
      return first.data;
    }

    if (!_isSessionRejected(first)) return null;

    final renewed = await _openSession();
    if (renewed == null) return null;
    onRenewed(renewed);

    final second = await _livenessApi.awsCredentials(kycSessionId: renewed);
    if (second.isSuccess && (second.data?.isComplete ?? false)) {
      return second.data;
    }
    return null;
  }

  /// A 401 from the credentials route means the KYC session is spent or
  /// expired — not that the user's own token is bad.
  bool _isSessionRejected(ApiResult<KycAwsCredentials> result) =>
      result.statusCode == 401;

  Future<String?> _openSession() async {
    final result = await _kycApi.startSession();
    final id = result.data?.sessionId;
    if (!result.isSuccess || id == null || id.isEmpty) return null;
    return id;
  }
}
