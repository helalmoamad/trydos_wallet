import '../api/api.dart';
import '../config/trydos_wallet_config.dart';

/// خدمة المصادقة (تسجيل الخروج).
class AuthApiService {
  AuthApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  /// تسجيل الخروج (POST). يهمنا فقط نجاح أو فشل الطلب.
  Future<ApiResult<void>> logout() {
    return _client.post<void>(ApiPaths.authLogout);
  }
}
