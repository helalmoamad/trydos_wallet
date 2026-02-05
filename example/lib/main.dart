import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  // تهيئة المكتبة - ضروري قبل أي استدعاء للـ API
  TrydosWallet.init(
    TrydosWalletConfig(
      baseUrl:
          'https://trydos_wallet_develop.ramaaz.dev/', // استبدل برابط الـ API الفعلي
      token:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5Nzg3OTBiODVjNGVlZWEyYWUxMzhkNSIsImVtYWlsIjoicGhvbmVfOTYzOTM0MzMwODg5QHRyeWRvcy1vdHAubG9jYWwiLCJ0eXBlIjoidXNlciIsImxhbmciOiJlbiIsImt5Y1N0YXR1cyI6Im5vdF9zdWJtaXR0ZWQiLCJpYXQiOjE3NzAyODE3NzAsImV4cCI6MTc3MDI4NTM3MH0.72oOk8bb9uq3C6l_Xxr4dyf7oEgq--gKREEWxU4brQ4", // أو 'your-jwt-token' بعد تسجيل الدخول
      languageCode: 'en', // ar, en, etc.
      isKurdish: false,
      applicationVersion: '1.0.0',
      debug: kDebugMode, // يطبع الطلبات في الكونسول
      allowBadCertificate: true, // للتطوير فقط - عند خطأ Hostname mismatch
    ),
  );
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
