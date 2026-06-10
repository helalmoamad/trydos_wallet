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

void main() {
  // Library init - required before any API call
  TrydosWallet.init(
    TrydosWalletConfig(
      baseUrl: 'https://trydos_wallet_develop.ramaaz.dev/',
      kycBaseUrl:
          "https://kyc-ai-ramaaz-digital-banking.yazan-adnof.workers.dev/",
      //   "https://kyc-verification-ramaaz-digital-banking.yazan-adnof.workers.dev/",
      token:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5ZDEyMDNiOTQxMjM4NWRmMWU5ZmIwYiIsImVtYWlsIjoicGhvbmVfOTYzOTM0MzMwODg5QHRyeWRvcy1vdHAubG9jYWwiLCJ0eXBlIjoidXNlciIsImxhbmciOiJlbiIsImt5Y1N0YXR1cyI6Im5vdF9zdWJtaXR0ZWQiLCJ1c2VyVHlwZSI6InJlZ2lzdGVyZWQiLCJzZXNzaW9uSWQiOiI2YTI5MmIwNDI2ZGM1ZjhmNzdjMzg5NDQiLCJpYXQiOjE3ODEwODI4ODYsImV4cCI6MTc4MTA4MzE4NiwiYXVkIjoidHJ5ZG9zLXVzZXIiLCJpc3MiOiJ0cnlkb3Mtd2FsbGV0IiwianRpIjoiMDQyZmE4ZTAtYjE2Yi00NTAwLTkwMTMtNGM0ZjFlYjQ4YzNkIn0.eXf6KKtNPdmZWd20bPr_HX7AD0M9x2O6bXHFcNYXt70",
      refreshToken: "dddddddddddddddddddddddddddddddddddd",
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
  }

  @override
  void dispose() {
    _logoutSubscription?.cancel();
    _languageSubscription?.cancel();
    _lockSubscription?.cancel();
    _switchSubscription?.cancel();
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
