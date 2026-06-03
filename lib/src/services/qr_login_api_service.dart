import 'package:trydos_wallet/trydos_wallet.dart';

class QrLoginApiService {
  QrLoginApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<WalletQrLoginRequest>> scanQrToken(String qrToken) {
    return _client.post<WalletQrLoginRequest>(
      ApiPaths.qrScan,
      data: {'qrToken': qrToken},
      fromJson: (data) =>
          WalletQrLoginRequest.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> approveQrLogin(String linkId) {
    return _client.post<Map<String, dynamic>>(
      ApiPaths.qrApprove,
      data: {'linkId': linkId},
      fromJson: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> rejectQrLogin(String linkId) {
    return _client.post<Map<String, dynamic>>(
      ApiPaths.qrReject,
      data: {'linkId': linkId},
      fromJson: (data) => Map<String, dynamic>.from(data as Map),
    );
  }
}
