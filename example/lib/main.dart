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
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5YjY1ZWVmMDZhNTY2YWE4NTQxNmYwNyIsImVtYWlsIjoicGhvbmVfOTYzNTU1NTQ0NEB0cnlkb3Mtb3RwLmxvY2FsIiwidHlwZSI6InVzZXIiLCJsYW5nIjoiZW4iLCJreWNTdGF0dXMiOiJub3Rfc3VibWl0dGVkIiwidXNlclR5cGUiOiJyZWdpc3RlcmVkIiwiaWF0IjoxNzczNTU5NTM1LCJleHAiOjE3NzYxNTE1MzV9.BkssTOZlh7u0k33-uhJD23HOURyY5nnW-cYBqgN8Uyw",
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
      create: (context) => WalletBloc()..add(const WalletLanguageChanged('ar')),
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            title: 'Wallet - Example 1.0.0',
            debugShowCheckedModeBanner: false,
            locale: Locale(state.languageCode),
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
