import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/kyc/kyc_compare_face_response.dart';

/// API service for KYC face comparison.
class KycCompareFaceApiService {
  KycCompareFaceApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.kycApiClient;

  final ApiClient _client;

  Future<ApiResult<KycCompareFaceResponse>> compareFace({
    required String selfieImageData,
    required String idFaceImageData,
  }) {
    return _client.post<KycCompareFaceResponse>(
      ApiPaths.kycCompareFace,
      data: {
        'selfieImageData': selfieImageData,
        'idFaceImageData': idFaceImageData,
      },
      fromJson: (d) =>
          KycCompareFaceResponse.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }
}
