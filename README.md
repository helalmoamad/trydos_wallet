# trydos_wallet

مكتبة محفظة Trydos - سحب، إيداع، ومعاملات. API، BLoC عام، وواجهة جاهزة.

---

## خطوات استدعاء المكتبة من تطبيق آخر

### الخطوة 1: إضافة المكتبة في `pubspec.yaml`

**من Git (الإنتاج):**
```yaml
dependencies:
  trydos_wallet:
    git:
      url: https://gitlab.com/trydos_app/trydos_wallet.git
      ref: main
```

**من مسار محلي (أثناء التطوير):**
```yaml
dependencies:
  trydos_wallet:
    path: ../trydos_wallet
```

ثم نفّذ:
```bash
flutter pub get
```

---

### الخطوة 2: تهيئة المكتبة في `main()`

**يجب** استدعاء `TrydosWallet.init()` قبل `runApp()`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  TrydosWallet.init(TrydosWalletConfig(
    baseUrl: 'https://api.trydos.com',  // رابط الـ API
    token: 'your-jwt-token',            // أو null قبل تسجيل الدخول
    languageCode: 'ar',                 // ar, en, ku
    isKurdish: false,
    applicationVersion: '1.0.0',
    debug: kDebugMode,
    allowBadCertificate: false,         // true للتطوير فقط عند خطأ SSL
  ));
  runApp(const MyApp());
}
```

| البارامتر | النوع | الوصف |
|-----------|-------|-------|
| `baseUrl` | `String` | رابط أساس الـ API (مطلوب) |
| `token` | `String?` | توكن Bearer للـ Authorization |
| `languageCode` | `String` | كود اللغة (ar, en, ku) |
| `isKurdish` | `bool` | هل اللغة كردية عند ar |
| `applicationVersion` | `String` | إصدار التطبيق |
| `debug` | `bool` | طباعة الطلبات والردود |
| `allowBadCertificate` | `bool` | تجاوز التحقق من SSL (تطوير فقط) |

---

### الخطوة 3: استخدام شاشات المحفظة

#### أ) كصفحة البداية (ترحيب + رئيسية):
```dart
MaterialApp(
  home: const TrydosWalletWelcomeScreen(),
)
```

#### ب) الصفحة الرئيسية مباشرة:
```dart
MaterialApp(
  home: const TrydosWalletHomePage(),
)
```

#### ج) كصفحة داخل التطبيق:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TrydosWalletHomePage(),
  ),
);
```

---

### الخطوة 4: تحديث التوكن لاحقاً

```dart
TrydosWallet.updateToken('new-token-after-login');
```

---

### تشغيل التطبيق المثال للتجريب

```bash
cd example
flutter run
```

---

## الاستخدام المتقدم

### استخدام BLoC العام لـ API آخر

```dart
BlocProvider(
  create: (context) => PaginatedApiBloc<Transaction>(
    fetcher: (page, limit) => MyTransactionsService().getTransactions(page, limit),
    defaultErrorMessage: 'فشل تحميل المعاملات',
  )..add(const ApiLoadRequested()),
  child: MyTransactionsPage(),
)
```

### الأحداث العامة
- `ApiLoadRequested` — تحميل
- `ApiRefreshRequested` — إعادة تحميل
- `ApiLoadMoreRequested` — تحميل المزيد (pagination)

### الحالات العامة
- `ApiInitial<T>` — أولية
- `ApiLoading<T>` — جارٍ التحميل
- `ApiLoaded<T>` — محمّل (`items`, `hasNext`, `isLoadingMore`)
- `ApiError<T>` — خطأ
