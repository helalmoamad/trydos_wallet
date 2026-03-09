import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

/// خدمة API للبنوك.
class BanksApiService {
  BanksApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  /// جلب قائمة البنوك مع pagination.
  /// [page] 0-indexed
  /// [limit] default 10, max 100
  Future<ApiResult<PaginatedResponse<Bank>>> getBanks({
    int page = 0,
    int limit = 10,
  }) async {
    return _client.get<PaginatedResponse<Bank>>(
      ApiPaths.banks,
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (d) => PaginatedResponse<Bank>.fromJson(
        d as Map<String, dynamic>,
        (e) => Bank.fromJson(e as Map<String, dynamic>),
      ),
    );
  }
}
