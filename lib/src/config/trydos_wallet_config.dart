import 'dart:async';
import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// Library config - passed when initializing from the consuming app.
///
/// Contains baseURL, token, language, and app version.
class TrydosWalletConfig {
  TrydosWalletConfig({
    required this.baseUrl,
    this.kycBaseUrl,
    this.token,
    this.refreshToken,
    this.languageCode = 'ar',
    this.isKurdish = false,
    this.applicationVersion = '1.0.0',
    this.debug = false,
    this.firstName = 'M*****',
    this.lastName = 'A*****',
    this.email,
    this.phoneNumber,
    this.accountNumber,
    this.profileImageUrl,
    this.userSubtitle,
    this.clientIp,
    this.displayId,
    this.isVerified = false,
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
  final String? refreshToken;
  final String? token;
  final String languageCode;
  final bool isKurdish;
  final String applicationVersion;
  final bool debug;
  final String? displayId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? clientIp;
  final String? phoneNumber;
  final String? accountNumber;
  final String? profileImageUrl;
  final String? userSubtitle;
  final bool isVerified;
  final bool isPhoneVerified;
  final bool isAccountActive;
  final bool isTwoFactorEnabled;
  final DateTime? memberSince;
  final bool allowBadCertificate;
  final bool skipSplash;
  final bool disableWalletOverscrollIndicator;

  ApiHeadersConfig get headersConfig => ApiHeadersConfig(
    languageCode: languageCode,
    clientIp: clientIp ?? '',
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
  static const String _profileImageUrlPrefKey =
      'trydos_wallet_profile_image_url';
  static const String _fcmTokenPrefKey = 'trydos_wallet_fcm_token';

  /// In-memory cache of the last known FCM token (synchronous access).
  static String? _fcmToken;
  static TrydosWalletConfig? _config;
  static ApiClient? _apiClient;
  static ApiClient? _kycApiClient;
  static final StreamController<TrydosWalletConfig> _configChangesController =
      StreamController<TrydosWalletConfig>.broadcast();

  static Stream<TrydosWalletConfig> get configChanges =>
      _configChangesController.stream;

  /// Incoming session-approval requests delivered out-of-band by the HOST app
  /// (e.g. a Firebase push `approval_request` opened from a closed app). The
  /// WalletBloc listens to this and shows the approve/reject dialog.
  static final StreamController<Map<String, dynamic>>
  _sessionApprovalController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Buffers an approval that arrives before the WalletBloc has subscribed
  /// (cold start from a notification tap). Drained once via
  /// [consumePendingSessionApproval].
  static Map<String, dynamic>? _pendingSessionApproval;

  static Stream<Map<String, dynamic>> get sessionApprovalRequests =>
      _sessionApprovalController.stream;

  /// HOST entry point: call when a push notification carrying a session
  /// `approval_request` is received/opened. Pass the request payload (the same
  /// shape the WebSocket `session:approval_request` event delivers). If the
  /// wallet isn't mounted yet (cold start) the payload is buffered and replayed
  /// when the WalletBloc comes up.
  static void handleSessionApprovalRequest(Map<String, dynamic> payload) {
    if (_sessionApprovalController.hasListener) {
      _sessionApprovalController.add(payload);
    } else {
      _pendingSessionApproval = payload;
    }
  }

  /// Returns and clears any buffered cold-start approval payload.
  static Map<String, dynamic>? consumePendingSessionApproval() {
    final pending = _pendingSessionApproval;
    _pendingSessionApproval = null;
    return pending;
  }

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
    unawaited(_restorePersistedProfileImageUrl());
    unawaited(loadFcmToken());
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
        refreshToken: _config!.refreshToken,
        lastName: _config!.lastName,
        email: _config!.email,
        clientIp: _config!.clientIp,
        phoneNumber: _config!.phoneNumber,
        profileImageUrl: _config!.profileImageUrl,
        userSubtitle: _config!.userSubtitle,
        isVerified: _config!.isVerified,
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
        refreshToken: _config!.refreshToken,
        firstName: _config!.firstName,
        lastName: _config!.lastName,
        email: _config!.email,
        phoneNumber: _config!.phoneNumber,
        profileImageUrl: _config!.profileImageUrl,
        userSubtitle: _config!.userSubtitle,
        clientIp: _config!.clientIp,
        isVerified: _config!.isVerified,
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
    String? displayId,
    String? email,
    String? clientIp,
    String? phoneNumber,
    String? refreshToken,
    String? profileImageUrl,
    String? userSubtitle,
    bool? isVerified,
    bool? isPhoneVerified,
    bool? isAccountActive,
    bool? isTwoFactorEnabled,
    DateTime? memberSince,
  }) {
    if (_config == null) return;
    final resolvedProfileImageUrl = profileImageUrl ?? _config!.profileImageUrl;
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
        displayId: displayId ?? _config!.displayId,
        lastName: lastName ?? _config!.lastName,
        refreshToken: refreshToken ?? _config!.refreshToken,
        email: email ?? _config!.email,
        phoneNumber: phoneNumber ?? _config!.phoneNumber,
        profileImageUrl: resolvedProfileImageUrl,
        userSubtitle: userSubtitle ?? _config!.userSubtitle,
        clientIp: clientIp ?? _config!.clientIp,
        isVerified: isVerified ?? _config!.isVerified,
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

    unawaited(_persistProfileImageUrl(resolvedProfileImageUrl));
  }

  /// Last known FCM token (in-memory). Returns null until [setFcmToken] runs or
  /// [loadFcmToken] restores it from storage.
  static String? get fcmToken => _fcmToken;

  /// HOST entry point: call whenever Firebase creates or refreshes the FCM
  /// token (`onTokenRefresh` / after `getToken()`). Persists it to
  /// SharedPreferences and caches it in memory. Pass null/empty to clear it
  /// (e.g. on logout).
  static Future<void> setFcmToken(String? token) async {
    final normalized = token?.trim();
    _fcmToken = (normalized == null || normalized.isEmpty) ? null : normalized;

    final prefs = await SharedPreferences.getInstance();
    if (_fcmToken == null) {
      await prefs.remove(_fcmTokenPrefKey);
    } else {
      await prefs.setString(_fcmTokenPrefKey, _fcmToken!);
    }
  }

  /// Reads the persisted FCM token from SharedPreferences into the in-memory
  /// cache and returns it (null if none stored).
  static Future<String?> loadFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_fcmTokenPrefKey)?.trim();
    _fcmToken = (stored == null || stored.isEmpty) ? null : stored;
    return _fcmToken;
  }

  static Future<void> _persistProfileImageUrl(String? profileImageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedValue = profileImageUrl?.trim();
    if (normalizedValue == null || normalizedValue.isEmpty) {
      await prefs.remove(_profileImageUrlPrefKey);
      return;
    }

    await prefs.setString(_profileImageUrlPrefKey, normalizedValue);
  }

  static Future<void> _restorePersistedProfileImageUrl() async {
    if (_config == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_profileImageUrlPrefKey)) return;

    final persistedValue = prefs.getString(_profileImageUrlPrefKey);
    final normalizedValue =
        (persistedValue == null || persistedValue.trim().isEmpty)
        ? null
        : persistedValue.trim();

    if (_config!.profileImageUrl == normalizedValue) return;

    _applyConfig(
      TrydosWalletConfig(
        baseUrl: _config!.baseUrl,
        kycBaseUrl: _config!.kycBaseUrl,
        token: _config!.token,
        refreshToken: _config!.refreshToken,
        languageCode: _config!.languageCode,
        isKurdish: _config!.isKurdish,
        applicationVersion: _config!.applicationVersion,
        debug: _config!.debug,
        firstName: _config!.firstName,
        lastName: _config!.lastName,
        email: _config!.email,
        phoneNumber: _config!.phoneNumber,
        clientIp: _config!.clientIp,
        profileImageUrl: normalizedValue,
        userSubtitle: _config!.userSubtitle,
        isVerified: _config!.isVerified,
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
}
