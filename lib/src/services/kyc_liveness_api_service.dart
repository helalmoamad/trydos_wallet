import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/kyc/kyc_aws_liveness.dart';
import '../models/kyc/kyc_liveness_response.dart';

/// API service for KYC liveness.
///
/// Two paths live here. [createAwsSession] / [awsCredentials] / [awsResult]
/// drive AWS Face Liveness, which is the path enrolment should use: AWS judges
/// the person and returns a confidence NestJS can threshold.
///
/// [liveness] is the older single-frame head-pose check. It is kept for the
/// screens still on it, but its `metrics.confidence` is face-*detection*
/// confidence (~99 whatever the subject is) and must never be submitted as
/// `livenessConfidence` — doing so silently disables the backend's liveness
/// threshold.
class KycLivenessApiService {
  KycLivenessApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.kycApiClient;

  final ApiClient _client;

  /// Opens an AWS Face Liveness session for the native detector to run.
  ///
  /// Sends no body and needs no KYC session — it is [awsCredentials] that is
  /// tied to one. A session is single-use: create a new one for every retry.
  Future<ApiResult<KycAwsLivenessSession>> createAwsSession() {
    return _client.post<KycAwsLivenessSession>(
      ApiPaths.kycAwsLiveness,
      fromJson: (d) =>
          KycAwsLivenessSession.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }

  /// Mints ~900 s STS credentials for the native detector.
  ///
  /// [kycSessionId] is validated against the backend first, so a `401` here
  /// means the KYC session is spent or expired: drop it, open a new one, and
  /// retry once.
  Future<ApiResult<KycAwsCredentials>> awsCredentials({
    required String kycSessionId,
  }) {
    return _client.post<KycAwsCredentials>(
      ApiPaths.kycAwsLivenessCredentials,
      data: {'kycSessionId': kycSessionId},
      fromJson: (d) =>
          KycAwsCredentials.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }

  /// Reads the verdict for an AWS session.
  ///
  /// Call this only after the detector's completion callback — before that it
  /// answers `CREATED` / `IN_PROGRESS`.
  Future<ApiResult<KycAwsLivenessResult>> awsResult({
    required String sessionId,
  }) {
    return _client.get<KycAwsLivenessResult>(
      ApiPaths.kycAwsLiveness,
      queryParameters: {'sessionId': sessionId},
      fromJson: (d) =>
          KycAwsLivenessResult.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }

  /// Single-frame head-pose check. See the class doc before using its
  /// confidence for anything.
  Future<ApiResult<KycLivenessResponse>> liveness({
    required String faceImageData,
    required String challengeStep,
    bool crop = true,
  }) {
    return _client.post<KycLivenessResponse>(
      ApiPaths.kycLiveness,
      data: {
        'faceImageData': faceImageData,
        'challengeStep': challengeStep,
        'crop': crop,
      },
      fromJson: (d) =>
          KycLivenessResponse.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }
}
