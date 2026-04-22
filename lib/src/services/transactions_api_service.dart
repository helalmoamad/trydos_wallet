import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

/// خدمة API لمعاملات المحفظة (cursor pagination).
class TransactionsApiService {
  TransactionsApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<CursorPaginatedResponse<Transaction>>> getTransactions({
    int page = 0,
    String? cursor,
    int limit = 10,
    String? assetSymbol,
  }) async {
    final query = <String, dynamic>{'limit': 20, 'page': page};
    if (cursor != null && cursor.isNotEmpty) {
      final page = int.tryParse(cursor);
      if (page != null) {
        query['page'] = page;
      } else {
        query
          ..remove('page')
          ..['cursor'] = cursor;
      }
    }
    if (assetSymbol != null && assetSymbol.isNotEmpty) {
      query['assetSymbol'] = assetSymbol;
    }
    return _client.get<CursorPaginatedResponse<Transaction>>(
      ApiPaths.myTransactions,
      queryParameters: query,
      fromJson: (d) => CursorPaginatedResponse<Transaction>.fromJson(
        d as Map<String, dynamic>,
        (e) => Transaction.fromJson(e as Map<String, dynamic>),
      ),
    );
  }
}
