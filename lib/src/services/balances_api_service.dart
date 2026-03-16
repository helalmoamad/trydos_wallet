import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

/// خدمة API لأرصدة المحفظة حسب العملة.
class BalancesApiService {
  BalancesApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<List<Balance>>> getBalances() async {
    return _client.get<List<Balance>>(
      ApiPaths.myAccounts,
      queryParameters: {"currencySymbol": "USD"},
      fromJson: (d) =>
          Balance.listFromMyAccountsJson(d as Map<String, dynamic>),
    );
  }
}
