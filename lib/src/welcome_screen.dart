import 'package:flutter/material.dart';

/// صفحة البداية لمكتبة المحفظة - تعرض ترحيباً بالمستخدم.
///
/// يمكن استخدامها كصفحة رئيسية أو كأول شاشة عند فتح المحفظة.
class TrydosWalletWelcomeScreen extends StatelessWidget {
  const TrydosWalletWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'مرحبا بك في المحفظه',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
