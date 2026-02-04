import 'package:flutter/material.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  runApp(const TrydosWalletExampleApp());
}

/// تطبيق مثال لتشغيل المحفظة أثناء التصميم.
class TrydosWalletExampleApp extends StatelessWidget {
  const TrydosWalletExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المحفظة - مثال',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        fontFamily: 'packages/trydos_wallet/Quicksand',
      ),
      home: const TrydosWalletWelcomeScreen(),
    );
  }
}
