import '../api/api.dart';
import '../config/trydos_wallet_config.dart';

/// خدمة المصادقة (تسجيل الخروج).
class AuthApiService {
  AuthApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  /// تسجيل الخروج (POST). يهمنا فقط نجاح أو فشل الطلب.
  ///
  /// يرسل الـ refreshToken الحالي في جسم الطلب كما يتطلبه الخادم.
  Future<ApiResult<void>> logout() {
    return _client.post<void>(
      ApiPaths.authLogout,
      data: {'refreshToken': TrydosWallet.config.refreshToken},
    );
  }

  /// إلغاء تسجيل جهاز من إشعارات الدفع (POST). يُرسَل قبل تسجيل الخروج.
  Future<ApiResult<void>> unregisterDevice(String fcmToken) {
    return _client.post<void>(
      ApiPaths.notificationsUnregisterDevice,
      data: {'fcmToken': fcmToken},
    );
  }
}
