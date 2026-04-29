import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/kyc/kyc_analyze_id_response.dart';

/// API service for KYC ID analysis (front/back).
class KycApiService {
  KycApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<KycAnalyzeIdResponse>> analyzeId({
    required String imageData,
    required String side,
    String? sessionHint,
  }) {
    return _client.post<KycAnalyzeIdResponse>(
      ApiPaths.kycAnalyzeId,
      data: {
        'imageData': imageData,
        'side': side,
        if (sessionHint != null && sessionHint.isNotEmpty)
          'sessionHint': sessionHint,
      },
      fromJson: (d) =>
          KycAnalyzeIdResponse.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }
}
