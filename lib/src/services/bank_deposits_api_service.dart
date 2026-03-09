import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

/// API service for bank deposits.
class BankDepositsApiService {
  BankDepositsApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  /// Calculate deposit fees and taxes.
  Future<ApiResult<DepositFeesResult>> calculateFees({
    required String bankId,
    required String currencyId,
    required double amount,
  }) async {
    return _client.post<DepositFeesResult>(
      ApiPaths.bankDepositsCalculateFees,
      data: {'bankId': bankId, 'currencyId': currencyId, 'amount': amount},
      fromJson: (d) => DepositFeesResult.fromJson(d as Map<String, dynamic>),
    );
  }

  /// Get user deposit requests (paginated).
  Future<ApiResult<PaginatedResponse<BankDepositRequest>>> getDepositRequests({
    int page = 0,
    int limit = 10,
  }) async {
    return _client.get<PaginatedResponse<BankDepositRequest>>(
      ApiPaths.bankDeposits,
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (d) => PaginatedResponse<BankDepositRequest>.fromJson(
        d as Map<String, dynamic>,
        (e) => BankDepositRequest.fromJson(e as Map<String, dynamic>),
      ),
    );
  }

  /// Create bank deposit request.
  Future<ApiResult<BankDepositResponse>> createDeposit({
    required String bankId,
    required String currencyId,
    required double amount,
    required String transferImageUrl,
    String? transactionReference,
    required String idempotencyKey,
  }) async {
    final data = <String, dynamic>{
      'bankId': bankId,
      'currencyId': currencyId,
      'amount': amount,
      'transferImageUrl': transferImageUrl,
      'idempotencyKey': idempotencyKey,
    };
    if (transactionReference != null && transactionReference.isNotEmpty) {
      data['transactionReference'] = transactionReference;
    }
    return _client.post<BankDepositResponse>(
      ApiPaths.bankDeposits,
      data: data,
      fromJson: (d) => BankDepositResponse.fromJson(d as Map<String, dynamic>),
    );
  }
}
