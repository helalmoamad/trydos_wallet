import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

/// خدمة API لأرصدة المحفظة حسب العملة.
class BalancesApiService {
  BalancesApiService({ApiClient? client})
      : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<Balance>> getBalance(
    String assetId, {
    String accountSubtype = 'MAIN',
    String assetType = 'CURRENCY',
  }) async {
    return _client.get<Balance>(
      ApiPaths.balance(assetId),
      queryParameters: {
        'accountSubtype': accountSubtype,
        'assetType': assetType,
      },
      fromJson: (d) => Balance.fromJson(d as Map<String, dynamic>),
    );
  }
}
