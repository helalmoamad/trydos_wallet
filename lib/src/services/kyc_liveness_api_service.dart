import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/kyc/kyc_liveness_response.dart';

/// API service for KYC Liveness detection.
class KycLivenessApiService {
  KycLivenessApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.kycApiClient;

  final ApiClient _client;

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
