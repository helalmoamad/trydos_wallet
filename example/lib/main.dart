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
import 'package:flutter/services.dart';

void main() {
  // Library init - required before any API call
  TrydosWallet.init(
    TrydosWalletConfig(
      baseUrl: 'https://trydos_wallet_develop.ramaaz.dev/',
      kycBaseUrl:
          "https://kyc-ai-ramaaz-digital-banking.yazan-adnof.workers.dev/",
      //   "https://kyc-verification-ramaaz-digital-banking.yazan-adnof.workers.dev/",
      token:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5ZDEyMDNiOTQxMjM4NWRmMWU5ZmIwYiIsImVtYWlsIjoicGhvbmVfOTYzOTM0MzMwODg5QHRyeWRvcy1vdHAubG9jYWwiLCJ0eXBlIjoidXNlciIsImxhbmciOiJlbiIsImt5Y1N0YXR1cyI6Im5vdF9zdWJtaXR0ZWQiLCJ1c2VyVHlwZSI6InJlZ2lzdGVyZWQiLCJpYXQiOjE3Nzc5Nzg5MDgsImV4cCI6MTc4MDU3MDkwOH0.VyDWJCXahMp4DRCADiJ8fPJU4Dw1RfghMKeDN-XIfqQ",
      languageCode: 'en',
      isKurdish: false,
      applicationVersion: '1.0.0',
      debug: kDebugMode,
      firstName: 'هلال',
      lastName: 'محمد',
      email: 'phone_963934330889@trydos-otp.local',
      phoneNumber: '963934330889',
      userSubtitle: 'registered',
      isPhoneVerified: true,
      isAccountActive: true,
      isTwoFactorEnabled: false,
      memberSince: DateTime(2026, 1, 27),
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

class _TrydosWalletExampleAppState extends State<TrydosWalletExampleApp>
    with WidgetsBindingObserver {
  StreamSubscription? _logoutSubscription;
  StreamSubscription? _languageSubscription;
  bool _isAppInBackground = false;

  @override
  void initState() {
    super.initState();

    // Register as lifecycle observer to monitor app background state
    WidgetsBinding.instance.addObserver(this);

    // Listen to logout events emitted by the library.
    _logoutSubscription = logoutEvents.listen((event) {
      debugPrint('[App] Logout event received: ${event.reason}');
    });

    // Listen to language change events emitted by the library.
    _languageSubscription = languageChangeEvents.listen((event) {
      debugPrint('[App] Language change event: ${event.languageCode}');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[App] Lifecycle state: $state');

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // When app goes to background, hide sensitive content at platform level
        _hideWindowContent();
        setState(() {
          _isAppInBackground = true;
        });
        break;
      case AppLifecycleState.resumed:
        // When app returns to foreground, show content again
        _showWindowContent();
        setState(() {
          _isAppInBackground = false;
        });
        break;
      case AppLifecycleState.inactive:
        // App is becoming inactive (temporary state)
        setState(() {
          _isAppInBackground = true;
        });
        break;
      case AppLifecycleState.hidden:
        // App is hidden (new state in newer Flutter)
        setState(() {
          _isAppInBackground = true;
        });
        break;
    }
  }

  Future<void> _hideWindowContent() async {
    try {
      const platform = MethodChannel(
        'com.example.trydos_wallet_example/security',
      );
      await platform.invokeMethod('hideContent');
      debugPrint('[App] Platform method: hideContent called');
    } catch (e) {
      debugPrint('[App] Error calling hideContent: $e');
    }
  }

  Future<void> _showWindowContent() async {
    try {
      const platform = MethodChannel(
        'com.example.trydos_wallet_example/security',
      );
      await platform.invokeMethod('showContent');
      debugPrint('[App] Platform method: showContent called');
    } catch (e) {
      debugPrint('[App] Error calling showContent: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoutSubscription?.cancel();
    _languageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show black screen when app is in background for security
    if (_isAppInBackground) {
      return MaterialApp(
        home: Scaffold(body: Container(color: Colors.black)),
        debugShowCheckedModeBanner: false,
      );
    }

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
