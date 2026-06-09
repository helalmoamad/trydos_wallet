import 'package:trydos_wallet/trydos_wallet.dart';

class SessionsApiService {
  SessionsApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<List<WalletSession>>> getActiveSessions() {
    return _client.get<List<WalletSession>>(
      ApiPaths.sessionsActive,
      fromJson: (data) {
        final items = data as List<dynamic>;
        return items
            .map(
              (item) => WalletSession.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      },
    );
  }

  Future<ApiResult<void>> deleteSession(String sessionId) {
    return _client.delete<void>(
      ApiPaths.sessionById(sessionId),
      fromJson: (_) {},
    );
  }

  /// الرد على طلب موافقة تسجيل دخول جلسة. يهمنا فقط نجاح أو فشل الطلب.
  Future<ApiResult<void>> respondToApproval({
    required String requestId,
    required bool approve,
  }) {
    return _client.post<void>(
      ApiPaths.sessionApprovalRespond(requestId),
      data: {'action': approve ? 'approve' : 'reject'},
    );
  }
}
