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
| ~~`allowBadCertificate`~~ | `bool` | **مهمَل ومتجاهَل** — التحقق من الشهادات مفروض دائماً |

#### إعداد الشبكة على Android (HTTP + الشهادات)

Android 9 (API 28) فما فوق يحجب الاتصالات النصية `http://` افتراضياً، فإن كان
الـ `baseUrl` يشير إلى سيرفر تطوير بدون TLS ستفشل كل الطلبات قبل أن تصل
للمكتبة. أضف في تطبيقك المستضيف ملف
`android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

ثم اربطه في `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config"
    ... >
```

> `usesCleartextTraffic` يخدم API 23 فما دون، و`networkSecurityConfig` هو
> المعتمد من API 24 فصاعداً — لذلك يوضع الاثنان معاً.

للتفتيش على الطلبات عبر بروكسي (Charles / Proxyman / mitmproxy) ضع نسخة
بنفس الاسم تحت `android/app/src/debug/res/xml/` وأضف فيها
`<certificates src="user" />`، فتُطبَّق في بناء الـ debug وحده ويبقى بناء
الـ release معتمداً على شهادات النظام فقط. راجع
[`example/android/app/src/`](example/android/app/src/) للنموذج الكامل.

> 🔒 **التحقق من الشهادات مفروض دائماً ولا يمكن تعطيله.** أُزيل
> `badCertificateCallback` و`HttpOverrides` من المكتبة نهائياً، فأي شهادة
> مزيّفة أو منتهية أو غير مطابقة لاسم المضيف تُسقِط الاتصال بـ
> `HandshakeException`. البارامتر `allowBadCertificate` بقي مهمَلاً
> ومتجاهَلاً لئلا ينكسر بناء التطبيقات المضيفة.

#### النسخ الاحتياطي لبيانات المحفظة (اختياري — غير مفعّل في المثال)

`android:allowBackup` قيمته الافتراضية **`true`** عند عدم تحديدها، فيرفع Android
ملف `FlutterSharedPreferences.xml` — حيث تحفظ المكتبة توكن الإشعارات ورابط
صورة الحساب وخيار إخفاء الرصيد — إلى Google Drive، ويصبح متاحاً كذلك عبر
`adb backup`.

تطبيق المثال **يترك هذا على الوضع الافتراضي عمداً**، حتى تُستعاد تفضيلات
المستخدم عند نقل الهاتف. إن أردت منعه في تطبيقك، في `AndroidManifest.xml`:

```xml
<application
    android:allowBackup="false"
    android:fullBackupContent="@xml/backup_rules"
    android:dataExtractionRules="@xml/data_extraction_rules"
    ... >
```

> على Android 12 فأحدث (API 31) الـ `allowBackup="false"` يمنع النسخ السحابي
> **لكنه لا يمنع النقل بين الأجهزة** (device-to-device) — هذا يضبطه قسم
> `<device-transfer>` في `dataExtractionRules` وحده.

إن كان تطبيقك يحتاج النسخ الاحتياطي لبياناته هو، أبقِ `allowBackup="true"`
واستثنِ بيانات المحفظة فقط في `res/xml/data_extraction_rules.xml`:

```xml
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="sharedpref" path="FlutterSharedPreferences.xml" />
    </cloud-backup>
    <device-transfer>
        <exclude domain="sharedpref" path="FlutterSharedPreferences.xml" />
    </device-transfer>
</data-extraction-rules>
```

#### فحص أمني

قواعد Semgrep جاهزة في [`.semgrep/trydos-wallet.yaml`](.semgrep/trydos-wallet.yaml)،
وتشمل قواعد تكشف **غياب** هذه السمات لا وجودها فقط. لذلك تُبلّغ عن
`allowBackup` غير المحدَّد وعن مفتّش الشبكة المفتوح في الإنتاج — وهي
**مخاطر مقبولة بقرار الفريق**، تبقى ظاهرة في كل فحص بدل أن تُنسى:

```bash
semgrep --config .semgrep/trydos-wallet.yaml lib example test
```

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
