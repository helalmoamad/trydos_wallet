import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/trydos_wallet.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// ignore: unnecessary_import, implementation_imports
import 'package:trydos_wallet/src/config/trydos_wallet_config.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/constent/constant_design.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/constent/theme/app_theme.dart';

/// Credentials come from the build environment, never from source.
///
/// Run the example with:
///
/// ```
/// flutter run \
///   --dart-define=WALLET_TOKEN=<jwt> \
///   --dart-define=WALLET_REFRESH_TOKEN=<jwt> \
///   --dart-define=WALLET_BASE_URL=https://... \
///   --dart-define=WALLET_KYC_BASE_URL=https://...
/// ```
///
/// Or keep them out of your shell history in `example/.env.json` (gitignored)
/// and pass `--dart-define-from-file=.env.json`.
const String _kToken = String.fromEnvironment('WALLET_TOKEN');
const String _kRefreshToken = String.fromEnvironment('WALLET_REFRESH_TOKEN');
const String _kBaseUrl = String.fromEnvironment(
  'WALLET_BASE_URL',
  defaultValue: 'https://trydos_wallet_develop.ramaaz.dev/',
);
const String _kKycBaseUrl = String.fromEnvironment(
  'WALLET_KYC_BASE_URL',
  defaultValue: 'https://api.ramaaz-digital-bank.online/',
);

void main() {
  if (_kToken.isEmpty) {
    debugPrint(
      '[example] No WALLET_TOKEN provided — the app will start signed out. '
      'Pass --dart-define=WALLET_TOKEN=<jwt> to authenticate.',
    );
  }

  // Library init - required before any API call
  TrydosWallet.init(
    TrydosWalletConfig(
      baseUrl: _kBaseUrl,
      kycBaseUrl: _kKycBaseUrl,
      token: _kToken.isEmpty ? null : _kToken,
      refreshToken: _kRefreshToken.isEmpty ? null : _kRefreshToken,
      languageCode: 'en',
      isKurdish: false,
      applicationVersion: '1.0.0',
      debug: kDebugMode,
      firstName: 'هلال',
      lastName: 'محمد',
      clientIp: '192.168.1.2',
      email: 'phone_963934330889@trydos-otp.local',
      phoneNumber: '963934330889',
      userSubtitle: 'registered',
      isPhoneVerified: true,
      isAccountActive: true,
      isTwoFactorEnabled: false,
      memberSince: DateTime(2026, 1, 27),
      // DNS name. `trydos_wallet_develop.ramaaz.dev` has underscores, which
      // RFC 1123 disallows in hostnames, so BoringSSL (Dart/Flutter's TLS
      // stack) refuses to match it against the `*.ramaaz.dev` wildcard and
      // fails with CERTIFICATE_VERIFY_FAILED: Hostname mismatch. curl and
      // browsers are more lenient, which is why it only breaks in the app.
      // Once `trydos-wallet-develop.ramaaz.dev` (hyphens) exists, switch the
      // baseUrl over and drop this flag entirely.
      allowBadCertificate: true,
    ),
  );
  runApp(const TrydosWalletExampleApp());
}

/// Example app for the wallet library.
class TrydosWalletExampleApp extends StatefulWidget {
  const TrydosWalletExampleApp({super.key});

  @override
  State<TrydosWalletExampleApp> createState() => _TrydosWalletExampleAppState();
}

class _TrydosWalletExampleAppState extends State<TrydosWalletExampleApp> {
  StreamSubscription? _logoutSubscription;
  StreamSubscription? _languageSubscription;
  StreamSubscription? _lockSubscription;
  StreamSubscription? _switchSubscription;
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to logout events emitted by the library.
    _logoutSubscription = logoutEvents.listen((event) {
      debugPrint('[App] Logout event received: ${event.reason}');
    });

    _switchSubscription = switchEvents.listen((event) {
      debugPrint('[App] Switch event received: ${event.toString()}');
    });

    // Listen to language change events emitted by the library.
    _languageSubscription = languageChangeEvents.listen((event) {
      debugPrint('[App] Language change event: ${event.languageCode}');
    });
    _lockSubscription = lockEvents.listen((event) {
      debugPrint('[App] Lock event received: ${event.toString()}');
    });

    // Listen to API error events emitted by the library (e.g. 400s, KYC
    // compare/submit failures). The library's ApiErrorListener already shows
    // them on screen; this hook lets the host app log/handle them too.
    _errorSubscription = errorEvents.listen((event) {
      debugPrint(
        '[App] API error event: ${event.message} (status: ${event.statusCode})',
      );
    });
  }

  @override
  void dispose() {
    _logoutSubscription?.cancel();
    _languageSubscription?.cancel();
    _lockSubscription?.cancel();
    _switchSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WalletBloc>(
      create: (context) =>
          WalletBloc()
            ..add(WalletLanguageChanged(TrydosWallet.config.languageCode)),
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return ScreenUtilInit(
            designSize: kDesignSize,
            minTextAdapt: true,
            builder: (context, child) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                scaffoldMessengerKey: scaffoldMessengerKey,
                title: 'Wallet - Example 1.0.0',
                debugShowCheckedModeBanner: false,
                locale: Locale(TrydosWallet.config.languageCode),
                theme: AppTheme.light,
                builder: (context, child) => ApiErrorListener(child: child!),
                home: const TrydosWalletWelcomeScreen(),

                // const FirstPageKyc(),

                //
              );
            },
          );
        },
      ),
    );
  }
}
