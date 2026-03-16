import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

class TransferPurposesApiService {
  TransferPurposesApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<List<TransferPurpose>>> getTransferPurposes({
    String type = 'ALL',
  }) async {
    return _client.get<List<TransferPurpose>>(
      ApiPaths.transferPurpose,
      queryParameters: {'type': type},
      fromJson: (d) {
        final list = (d as List?)?.cast<dynamic>() ?? const [];
        return list
            .map((e) => TransferPurpose.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }
}
