import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  // Library init - required before any API call
  TrydosWallet.init(
    TrydosWalletConfig(
      baseUrl: 'https://trydos_wallet_develop.ramaaz.dev/',
      token:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5Nzg3OTBiODVjNGVlZWEyYWUxMzhkNSIsImVtYWlsIjoicGhvbmVfOTYzOTM0MzMwODg5QHRyeWRvcy1vdHAubG9jYWwiLCJ0eXBlIjoidXNlciIsImxhbmciOiJlbiIsImt5Y1N0YXR1cyI6Im5vdF9zdWJtaXR0ZWQiLCJ1c2VyVHlwZSI6InJlZ2lzdGVyZWQiLCJpYXQiOjE3NzMxMzc3NjQsImV4cCI6MTc3NTcyOTc2NH0.cig6iFl90gDYteCyWUCHA_cmvGhsTXesCLWEsTOQu-s",
      languageCode: 'en',
      isKurdish: false,
      applicationVersion: '1.0.0',
      debug: kDebugMode,
      firstName: "helal",
      lastName: "mohamad",
      allowBadCertificate: true,
    ),
  );
  runApp(const TrydosWalletExampleApp());
}

/// Example app for the wallet library.
class TrydosWalletExampleApp extends StatelessWidget {
  const TrydosWalletExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WalletBloc>(
      create: (context) =>
          WalletBloc()
            ..add(WalletLanguageChanged(TrydosWallet.config.languageCode)),
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            title: 'Wallet - Example 1.0.0',
            debugShowCheckedModeBanner: false,
            locale: Locale(TrydosWallet.config.languageCode),
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
              fontFamily: 'packages/trydos_wallet/Quicksand',
            ),
            builder: (context, child) => ApiErrorListener(child: child!),
            home: const TrydosWalletWelcomeScreen(),
          );
        },
      ),
    );
  }
}
