import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

/// بارامترات استعلام العملات.
class CurrenciesQueryParams {
  const CurrenciesQueryParams({
    this.page = 0,
    this.limit = 10,
    this.orderDirection,
    this.search,
  });

  final int page;
  final int limit;
  final String? orderDirection;
  final String? search;

  Map<String, dynamic> toQuery() {
    final map = <String, dynamic>{'page': page, 'limit': limit};
    if (orderDirection != null) map['orderDirection'] = orderDirection;
    if (search != null && search!.isNotEmpty) map['search'] = search;
    return map;
  }
}

/// خدمة API للعملات.
class CurrenciesApiService {
  CurrenciesApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<PaginatedResponse<Currency>>> getCurrencies(
    CurrenciesQueryParams params,
  ) async {
    return _client.get<PaginatedResponse<Currency>>(
      ApiPaths.currencies,
      queryParameters: params.toQuery(),
      fromJson: (d) {
        final map = d as Map<String, dynamic>;

        // New response shape:
        // { "currencies": [...], "metals": [...] }
        if (map.containsKey('currencies') || map.containsKey('metals')) {
          final currenciesRaw = map['currencies'] as List<dynamic>? ?? const [];
          final metalsRaw = map['metals'] as List<dynamic>? ?? const [];

          final items = <Currency>[
            ...currenciesRaw.whereType<Map<String, dynamic>>().map(
              Currency.fromJson,
            ),
            ...metalsRaw.whereType<Map<String, dynamic>>().map(
              (metal) => Currency.fromJson(metal),
            ),
          ];

          return PaginatedResponse<Currency>(
            items: items,
            total: items.length,
            page: map['page'] as int? ?? 0,
            limit: map['limit'] as int? ?? items.length,
            totalPages: map['totalPages'] as int? ?? 1,
            hasNext: map['hasNext'] as bool? ?? false,
            hasPrevious: map['hasPrevious'] as bool? ?? false,
          );
        }

        return PaginatedResponse<Currency>.fromJson(
          map,
          (e) => Currency.fromJson(e as Map<String, dynamic>),
        );
      },
    );
  }
}
