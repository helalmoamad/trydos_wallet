import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

class TransfersApiService {
  TransfersApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<AccountLookupResult>> lookupAccount(String accountNumber) {
    return _client.get<AccountLookupResult>(
      ApiPaths.lookupAccount(accountNumber),
      fromJson: (d) => AccountLookupResult.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<ApiResult<TransferVerifyResult>> verifyTransfer({
    required String toAccountNumber,
    required String assetSymbol,
    required String assetType,
    required double amount,
  }) {
    final num bodyAmount = amount.truncateToDouble() == amount
        ? amount.toInt()
        : amount;
    final normalizedAssetType = assetType.toUpperCase() == 'METAL'
        ? 'METAL'
        : 'CURRENCY';

    return _client.post<TransferVerifyResult>(
      ApiPaths.verifyTransfer,
      data: {
        'toAccountNumber': toAccountNumber,
        'assetSymbol': assetSymbol,
        'assetType': normalizedAssetType,
        'amount': bodyAmount,
      },
      fromJson: (d) => TransferVerifyResult.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<ApiResult<TransferSendResult>> sendTransfer({
    required String toAccountNumber,
    required String assetSymbol,
    required String assetType,
    required double amount,
    required String purposeId,
    required String note,
    required String idempotencyKey,
    String inputMethod = 'MANUAL',
  }) {
    final num bodyAmount = amount.truncateToDouble() == amount
        ? amount.toInt()
        : amount;
    final normalizedAssetType = assetType.toUpperCase() == 'METAL'
        ? 'METAL'
        : 'CURRENCY';

    return _client.post<TransferSendResult>(
      ApiPaths.sendTransfer,
      data: {
        'toAccountNumber': toAccountNumber,
        'assetSymbol': assetSymbol,
        'amount': bodyAmount,
        'assetType': normalizedAssetType,
        'purposeId': purposeId,
        'note': note,
        'idempotencyKey': idempotencyKey,
        'inputMethod': inputMethod,
      },
      fromJson: (d) => TransferSendResult.fromJson(d as Map<String, dynamic>),
    );
  }
}
