import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

import '../api/api_client.dart';
import '../api/api_headers.dart';

/// Library config - passed when initializing from the consuming app.
///
/// Contains baseURL, token, language, and app version.
class TrydosWalletConfig {
  TrydosWalletConfig({
    required this.baseUrl,
    this.token,
    this.languageCode = 'ar',
    this.isKurdish = false,
    this.applicationVersion = '1.0.0',
    this.debug = false,
    this.firstName = 'M*****',
    this.lastName = 'A*****',
    this.allowBadCertificate = false,
    this.skipSplash = false,
    this.onLogout,
    this.onLanguageChanged,
  });

  final String baseUrl;
  final String? token;
  final String languageCode;
  final bool isKurdish;
  final String applicationVersion;
  final bool debug;
  final String firstName;
  final String lastName;
  final bool allowBadCertificate;
  final bool skipSplash;
  final VoidCallback? onLogout;
  final void Function(String languageCode, bool isKurdish)? onLanguageChanged;

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

/// Global config store - set once at app startup.
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

  /// Initialize the library - call in main() or at app startup.
  static void init(TrydosWalletConfig config) {
    _config = config;
    _apiClient = config.createApiClient();
  }

  /// Trigger logout event for the host app.
  static void logout() {
    _config?.onLogout?.call();
  }

  /// Update the token later (e.g. after login).
  static void updateToken(String? token) {
    if (_config == null) return;
    _config = TrydosWalletConfig(
      baseUrl: _config!.baseUrl,
      token: token,
      languageCode: _config!.languageCode,
      isKurdish: _config!.isKurdish,
      applicationVersion: _config!.applicationVersion,
      debug: _config!.debug,
      firstName: _config!.firstName,
      lastName: _config!.lastName,
      allowBadCertificate: _config!.allowBadCertificate,
      skipSplash: _config!.skipSplash,
      onLogout: _config!.onLogout,
      onLanguageChanged: _config!.onLanguageChanged,
    );
    _apiClient?.updateHeaders(_config!.headersConfig);
  }

  /// Update the language later.
  static void updateLanguage(String languageCode, {bool? isKurdish}) {
    if (_config == null) return;
    final kurdish = isKurdish ?? (languageCode == 'ku');
    _config = TrydosWalletConfig(
      baseUrl: _config!.baseUrl,
      token: _config!.token,
      languageCode: languageCode,
      isKurdish: kurdish,
      applicationVersion: _config!.applicationVersion,
      debug: _config!.debug,
      firstName: _config!.firstName,
      lastName: _config!.lastName,
      allowBadCertificate: _config!.allowBadCertificate,
      skipSplash: _config!.skipSplash,
      onLogout: _config!.onLogout,
      onLanguageChanged: _config!.onLanguageChanged,
    );
    _apiClient?.updateHeaders(_config!.headersConfig);
    _config!.onLanguageChanged?.call(languageCode, kurdish);
  }

  /// Update user info later.
  static void updateUserInfo({String? firstName, String? lastName}) {
    if (_config == null) return;
    _config = TrydosWalletConfig(
      baseUrl: _config!.baseUrl,
      token: _config!.token,
      languageCode: _config!.languageCode,
      isKurdish: _config!.isKurdish,
      applicationVersion: _config!.applicationVersion,
      debug: _config!.debug,
      firstName: firstName ?? _config!.firstName,
      lastName: lastName ?? _config!.lastName,
      allowBadCertificate: _config!.allowBadCertificate,
      skipSplash: _config!.skipSplash,
      onLogout: _config!.onLogout,
      onLanguageChanged: _config!.onLanguageChanged,
    );
  }
}
