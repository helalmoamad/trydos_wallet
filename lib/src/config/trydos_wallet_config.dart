import 'dart:io' show Platform;

import '../api/api_client.dart';
import '../api/api_headers.dart';

/// تهيئة المكتبة - يُمرَّر عند استدعاء المكتبة من التطبيق المستهلك.
///
/// يحتوي على baseURL، التوكن، اللغة، وإصدار التطبيق.
class TrydosWalletConfig {
  TrydosWalletConfig({
    required this.baseUrl,
    this.token,
    this.languageCode = 'ar',
    this.isKurdish = false,
    this.applicationVersion = '1.0.0',
    this.debug = false,
    /// تجاوز التحقق من شهادة SSL (للتطوير فقط - لا تستخدمه في الإنتاج).
    this.allowBadCertificate = false,
  });

  final String baseUrl;
  final String? token;
  final String languageCode;
  final bool isKurdish;
  final String applicationVersion;
  final bool debug;
  final bool allowBadCertificate;

  ApiHeadersConfig get headersConfig => ApiHeadersConfig(
        languageCode: languageCode,
        isKurdish: isKurdish,
        applicationVersion: applicationVersion,
        token: token,
        isAndroid: Platform.isAndroid,
      );

  ApiClient createApiClient() => ApiClient(
        baseUrl: baseUrl,
        headersConfig: headersConfig,
        debug: debug,
        allowBadCertificate: allowBadCertificate,
      );
}

/// مخزن التهيئة العام - يُعيّن مرة واحدة عند بدء التطبيق.
class TrydosWallet {
  static TrydosWalletConfig? _config;
  static ApiClient? _apiClient;

  static TrydosWalletConfig get config {
    if (_config == null) {
      throw StateError(
        'TrydosWallet not initialized. Call TrydosWallet.init(config) first.',
      );
    }
    return _config!;
  }

  static ApiClient get apiClient {
    if (_apiClient == null) {
      throw StateError(
        'TrydosWallet not initialized. Call TrydosWallet.init(config) first.',
      );
    }
    return _apiClient!;
  }

  /// تهيئة المكتبة - استدعِها في main() أو عند بدء التطبيق.
  static void init(TrydosWalletConfig config) {
    _config = config;
    _apiClient = config.createApiClient();
  }

  /// تحديث التوكن لاحقاً (مثلاً بعد تسجيل الدخول).
  static void updateToken(String? token) {
    if (_config == null) return;
    _config = TrydosWalletConfig(
      baseUrl: _config!.baseUrl,
      token: token,
      languageCode: _config!.languageCode,
      isKurdish: _config!.isKurdish,
      applicationVersion: _config!.applicationVersion,
      debug: _config!.debug,
      allowBadCertificate: _config!.allowBadCertificate,
    );
    _apiClient?.updateHeaders(_config!.headersConfig);
  }
}
