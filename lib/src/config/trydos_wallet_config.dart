import 'dart:async';
import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_headers.dart';
import '../api/api_interceptors.dart';

/// Library config - passed when initializing from the consuming app.
///
/// Contains baseURL, token, language, and app version.
class TrydosWalletConfig {
  TrydosWalletConfig({
    required this.baseUrl,
    this.kycBaseUrl,
    this.token,
    this.languageCode = 'ar',
    this.isKurdish = false,
    this.applicationVersion = '1.0.0',
    this.debug = false,
    this.firstName = 'M*****',
    this.lastName = 'A*****',
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.userSubtitle,
    this.isPhoneVerified = false,
    this.isAccountActive = true,
    this.isTwoFactorEnabled = false,
    this.memberSince,
    this.allowBadCertificate = false,
    this.skipSplash = false,
    this.disableWalletOverscrollIndicator = true,
  });

  final String baseUrl;
  final String? kycBaseUrl;
  final String? token;
  final String languageCode;
  final bool isKurdish;
  final String applicationVersion;
  final bool debug;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? userSubtitle;
  final bool isPhoneVerified;
  final bool isAccountActive;
  final bool isTwoFactorEnabled;
  final DateTime? memberSince;
  final bool allowBadCertificate;
  final bool skipSplash;
  final bool disableWalletOverscrollIndicator;

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

  ApiClient createKycApiClient() => ApiClient(
    baseUrl: kycBaseUrl ?? baseUrl,
    headersConfig: headersConfig,
    debug: debug,
    allowBadCertificate: allowBadCertificate,
  );
}

/// Global config store - set once at app startup.
class TrydosWallet {
  static TrydosWalletConfig? _config;
  static ApiClient? _apiClient;
  static ApiClient? _kycApiClient;
  static final StreamController<TrydosWalletConfig> _configChangesController =
      StreamController<TrydosWalletConfig>.broadcast();

  static Stream<TrydosWalletConfig> get configChanges =>
      _configChangesController.stream;

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

  static ApiClient get kycApiClient {
    if (_kycApiClient == null) {
      throw StateError(
        'TrydosWallet not initialized. Call TrydosWallet.init(config) first.',
      );
    }
    return _kycApiClient!;
  }

  /// Initialize the library - call in main() or at app startup.
  static void init(TrydosWalletConfig config) {
    final previousConfig = _config;
    final languageChanged =
        previousConfig != null &&
        (previousConfig.languageCode != config.languageCode ||
            previousConfig.isKurdish != config.isKurdish);

    _applyConfig(config, emitLanguageChanged: languageChanged);
  }

  static void _applyConfig(
    TrydosWalletConfig config, {
    bool emitLanguageChanged = false,
  }) {
    _config = config;

    if (_apiClient == null) {
      _apiClient = config.createApiClient();
    } else {
      _apiClient!
        ..updateBaseUrl(config.baseUrl)
        ..updateHeaders(config.headersConfig)
        ..updateAllowBadCertificate(config.allowBadCertificate);
    }

    if (_kycApiClient == null) {
      _kycApiClient = config.createKycApiClient();
    } else {
      _kycApiClient!
        ..updateBaseUrl(config.kycBaseUrl ?? config.baseUrl)
        ..updateHeaders(config.headersConfig)
        ..updateAllowBadCertificate(config.allowBadCertificate);
    }

    if (emitLanguageChanged) {
      emitLanguageChangeEvent(
        LanguageChangeEvent(
          config.languageCode,
          languageName:
              const {
                'en': 'English',
                'ar': 'Arabic',
                'ku': 'Kurdish',
                'tr': 'Turkish',
              }[config.languageCode] ??
              config.languageCode,
        ),
      );
    }

    _configChangesController.add(config);
  }

  /// Trigger logout event for the host app.
  static void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    emitLogoutEvent(LogoutEvent('user_logout'));
  }

  /// Update the token later (e.g. after login).
  static void updateToken(String? token) {
    if (_config == null) return;
    _applyConfig(
      TrydosWalletConfig(
        baseUrl: _config!.baseUrl,
        kycBaseUrl: _config!.kycBaseUrl,
        token: token,
        languageCode: _config!.languageCode,
        isKurdish: _config!.isKurdish,
        applicationVersion: _config!.applicationVersion,
        debug: _config!.debug,
        firstName: _config!.firstName,
        lastName: _config!.lastName,
        email: _config!.email,
        phoneNumber: _config!.phoneNumber,
        profileImageUrl: _config!.profileImageUrl,
        userSubtitle: _config!.userSubtitle,
        isPhoneVerified: _config!.isPhoneVerified,
        isAccountActive: _config!.isAccountActive,
        isTwoFactorEnabled: _config!.isTwoFactorEnabled,
        memberSince: _config!.memberSince,
        allowBadCertificate: _config!.allowBadCertificate,
        skipSplash: _config!.skipSplash,
        disableWalletOverscrollIndicator:
            _config!.disableWalletOverscrollIndicator,
      ),
    );
  }

  /// Update the language later.
  static void updateLanguage(String languageCode, {bool? isKurdish}) {
    if (_config == null) return;
    final kurdish = isKurdish ?? (languageCode == 'ku');
    _applyConfig(
      TrydosWalletConfig(
        baseUrl: _config!.baseUrl,
        kycBaseUrl: _config!.kycBaseUrl,
        token: _config!.token,
        languageCode: languageCode,
        isKurdish: kurdish,
        applicationVersion: _config!.applicationVersion,
        debug: _config!.debug,
        firstName: _config!.firstName,
        lastName: _config!.lastName,
        email: _config!.email,
        phoneNumber: _config!.phoneNumber,
        profileImageUrl: _config!.profileImageUrl,
        userSubtitle: _config!.userSubtitle,
        isPhoneVerified: _config!.isPhoneVerified,
        isAccountActive: _config!.isAccountActive,
        isTwoFactorEnabled: _config!.isTwoFactorEnabled,
        memberSince: _config!.memberSince,
        allowBadCertificate: _config!.allowBadCertificate,
        skipSplash: _config!.skipSplash,
        disableWalletOverscrollIndicator:
            _config!.disableWalletOverscrollIndicator,
      ),
      emitLanguageChanged: true,
    );
  }

  /// Update user info later.
  static void updateUserInfo({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? userSubtitle,
    bool? isPhoneVerified,
    bool? isAccountActive,
    bool? isTwoFactorEnabled,
    DateTime? memberSince,
  }) {
    if (_config == null) return;
    _applyConfig(
      TrydosWalletConfig(
        baseUrl: _config!.baseUrl,
        kycBaseUrl: _config!.kycBaseUrl,
        token: _config!.token,
        languageCode: _config!.languageCode,
        isKurdish: _config!.isKurdish,
        applicationVersion: _config!.applicationVersion,
        debug: _config!.debug,
        firstName: firstName ?? _config!.firstName,
        lastName: lastName ?? _config!.lastName,
        email: email ?? _config!.email,
        phoneNumber: phoneNumber ?? _config!.phoneNumber,
        profileImageUrl: profileImageUrl ?? _config!.profileImageUrl,
        userSubtitle: userSubtitle ?? _config!.userSubtitle,
        isPhoneVerified: isPhoneVerified ?? _config!.isPhoneVerified,
        isAccountActive: isAccountActive ?? _config!.isAccountActive,
        isTwoFactorEnabled: isTwoFactorEnabled ?? _config!.isTwoFactorEnabled,
        memberSince: memberSince ?? _config!.memberSince,
        allowBadCertificate: _config!.allowBadCertificate,
        skipSplash: _config!.skipSplash,
        disableWalletOverscrollIndicator:
            _config!.disableWalletOverscrollIndicator,
      ),
    );
  }
}
