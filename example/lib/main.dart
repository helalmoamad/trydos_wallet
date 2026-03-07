import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  // Library init - required before any API call
  TrydosWallet.init(
    TrydosWalletConfig(
      baseUrl: 'https://trydos_wallet_develop.ramaaz.dev///',
      token:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5Nzg3OTBiODVjNGVlZWEyYWUxMzhkNSIsImVtYWlsIjoicGhvbmVfOTYzOTM0MzMwODg5QHRyeWRvcy1vdHAubG9jYWwiLCJ0eXBlIjoidXNlciIsImxhbmciOiJlbiIsImt5Y1N0YXR1cyI6Im5vdF9zdWJtaXR0ZWQiLCJpYXQiOjE3NzA4MDMwNDAsImV4cCI6MTc3MzM5NTA0MH0.svpbwuEeXlGa3G-MltoFaUw6FoXgxY5jDJ_AjZVTysE",
      languageCode: 'en',
      isKurdish: false,
      applicationVersion: '1.0.0',
      debug: kDebugMode,
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
    return BlocProvider<LocalizationBloc>(
      create: (context) => LocalizationBloc(initialLanguageCode: 'ar'),
      child: BlocBuilder<LocalizationBloc, LocalizationState>(
        builder: (context, locState) {
          return MaterialApp(
            title: 'Wallet - Example',
            debugShowCheckedModeBanner: false,
            locale: Locale(locState.languageCode),
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
              fontFamily: 'packages/trydos_wallet/Quicksand',
            ),
            home: const TrydosWalletWelcomeScreen(),
          );
        },
      ),
    );
  }
}
