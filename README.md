# trydos_wallet

مكتبة محفظة Trydos - سحب، إيداع، ومعاملات. تعرض حالياً صفحة البداية للمحفظة.

## المميزات

- **صفحة البداية**: شاشة ترحيب "مرحبا بك في المحفظه" جاهزة للاستخدام في تطبيقاتك.

## التثبيت

أضف الحزمة في `pubspec.yaml` لتطبيقك:

### من Git

```yaml
dependencies:
  trydos_wallet:
    git:
      url: https://gitlab.com/trydos_app/trydos_wallet.git
      ref: main
```

### من مسار محلي (أثناء التطوير)

```yaml
dependencies:
  trydos_wallet:
    path: ../trydos_wallet
```

ثم نفّذ:

```bash
flutter pub get
```

## الاستخدام

عرض صفحة البداية في تطبيقك:

```dart
import 'package:flutter/material.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المحفظة',
      home: const TrydosWalletWelcomeScreen(),
    );
  }
}
```

أو كصفحة داخل التطبيق (مثلاً بعد الضغط على زر):

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TrydosWalletWelcomeScreen(),
  ),
);
```
