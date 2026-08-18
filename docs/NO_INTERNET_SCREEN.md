# شاشة "لا يوجد اتصال بالإنترنت" — التوثيق الكامل

> هذا المستند مرجع كامل ومستقل لميزة كشف انقطاع الإنترنت وعرض شاشة تغطي التطبيق.
> الهدف: تسليمه لـ Claude في **مشروع التطبيق المضيف** لتطبيق نفس السلوك بالضبط.

---

## 1. ما الذي تفعله الميزة (السلوك المطلوب)

| الحالة | السلوك |
|---|---|
| انقطاع الإنترنت كلياً (لا واي فاي ولا بيانات) | تظهر شاشة كاملة تغطي كل شيء خلال ثوانٍ |
| **متصل بواي فاي لكن بدون إنترنت فعلي** (الحالة المهمة) | تظهر الشاشة أيضاً — لأن الكشف لا يعتمد على حالة الواجهة الشبكية بل على اتصال فعلي |
| عودة الإنترنت | تختفي الشاشة تلقائياً، ويُعاد تحميل البيانات وإعادة الاتصال بالـ WebSocket |
| محاولة المستخدم إغلاق الشاشة | غير ممكن — لا يوجد زر إغلاق ولا `Navigator.pop`، الشاشة طبقة `Positioned.fill` وليست Route |

الشاشة تحتوي على: أيقونة نابضة (Pulse animation)، عنوان، نص توضيحي، ومؤشر دائري "في انتظار إعادة الاتصال..." — بأربع لغات (`ar` / `ku` / `tr` / `en`) مع دعم RTL.

---

## 2. أين توجد الملفات في مكتبة `trydos_wallet`

| الملف | الدور |
|---|---|
| `lib/src/services/connectivity_service.dart` | خدمة singleton تكشف الاتصال الفعلي وتنشر `ValueNotifier<bool> isOnline` |
| `lib/src/screens/no_internet_screen.dart` | واجهة الشاشة (التصميم) |
| `lib/src/screens/home_page.dart` | نقطة الربط: `initState` يشغّل الخدمة، و`Stack` يعرض الشاشة عند `_isOffline` |
| `assets/svg/reload.svg` | أيقونة الشاشة |
| `pubspec.yaml` | `connectivity_plus: ^6.1.4` |

---

## 3. آلية العمل بالتفصيل

### 3.1 لماذا لا يكفي `connectivity_plus` وحده

`connectivity_plus` يخبرك فقط بـ **نوع الواجهة الشبكية** (wifi / mobile / none). إذا كنت متصلاً براوتر واي فاي مفصول عن الإنترنت، فإنه يعيد `wifi` ويظن التطبيق أن كل شيء بخير. لذلك نستخدمه فقط كـ **مُحفِّز فوري** (trigger)، والتحقق الحقيقي يتم عبر اتصال TCP.

### 3.2 التحقق الحقيقي — TCP Socket إلى `8.8.8.8:53`

```dart
final socket = await Socket.connect('8.8.8.8', 53, timeout: Duration(seconds: 5));
socket.destroy();
```

- **لماذا `8.8.8.8` وليس اسم نطاق؟** لتجاوز DNS cache الخاص بالنظام — قد ينجح تحويل الاسم محلياً بينما الإنترنت مقطوع.
- **لماذا المنفذ 53؟** منفذ DNS، مفتوح دائماً على خوادم Google العامة، وغير محجوب عادةً.
- **لماذا Socket وليس `http`؟** أخف وأسرع، ولا يتأثر بالـ HTTP caching أو الـ proxies.

### 3.3 ثلاث طبقات للفحص

1. **فحص فوري** عند `initialize()` عند بدء التطبيق.
2. **مستمع `onConnectivityChanged`** — يتفاعل لحظياً عند تغيّر الشبكة (فتح/إغلاق الواي فاي).
3. **مؤقت دوري تكيّفي** — لالتقاط حالة "واي فاي بدون نت" التي لا تُطلق أي حدث:
   - أثناء الاتصال: كل **10 ثوانٍ**
   - أثناء الانقطاع: كل **5 ثوانٍ** (استجابة أسرع لعودة النت)

المؤقت يُعاد جدولته تلقائياً عند تغيّر الحالة عبر `_scheduleNextCheck()`.

### 3.4 الحماية من التداخل

العلم `_checking` يمنع تشغيل فحصين بالتوازي (مثلاً إذا وصل حدث شبكة أثناء انتظار الـ socket timeout).

### 3.5 النشر إلى الواجهة

الخدمة تنشر الحالة عبر `ValueNotifier<bool> isOnline`. أي Widget يستمع عبر `addListener` ويعيد البناء. **مهم:** إزالة المستمع في `dispose`.

---

## 4. الكود الكامل

### 4.1 `connectivity_service.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitors real internet connectivity using:
/// 1. connectivity_plus for instant network-interface change triggers.
/// 2. A TCP socket to 8.8.8.8:53 to verify actual internet (bypasses DNS cache).
/// 3. A periodic timer (10 s online / 5 s offline) to catch "WiFi but no internet".
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicTimer;
  bool _initialized = false;
  bool _checking = false;

  static const Duration _onlineInterval = Duration(seconds: 10);
  static const Duration _offlineInterval = Duration(seconds: 5);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Immediate check on startup
    await _checkAndUpdate();

    // React instantly to network interface changes
    _subscription = Connectivity().onConnectivityChanged.listen((_) {
      _checkAndUpdate();
    });

    // Periodic check catches "WiFi connected but no internet" cases
    _scheduleNextCheck();
  }

  void _scheduleNextCheck() {
    _periodicTimer?.cancel();
    final interval = isOnline.value ? _onlineInterval : _offlineInterval;
    _periodicTimer = Timer(interval, () async {
      await _checkAndUpdate();
      if (_initialized) _scheduleNextCheck();
    });
  }

  Future<void> _checkAndUpdate() async {
    if (_checking) return;
    _checking = true;
    try {
      final online = await _hasRealInternet();
      if (isOnline.value != online) {
        isOnline.value = online;
        // Reschedule with the new interval
        _scheduleNextCheck();
      }
    } finally {
      _checking = false;
    }
  }

  /// TCP connection to Google Public DNS (8.8.8.8:53).
  /// Bypasses OS DNS cache — works even when DNS resolves locally.
  Future<bool> _hasRealInternet() async {
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _periodicTimer?.cancel();
    isOnline.dispose();
    _initialized = false;
  }
}
```

> **ملاحظة للويب:** `dart:io` غير متاح على Flutter Web. إذا كان التطبيق المضيف يدعم الويب، انظر القسم 8.

---

### 4.2 `no_internet_screen.dart` — النسخة الأصلية (داخل المكتبة)

هذه النسخة تعتمد على ثوابت المكتبة (`TrydosWalletAssets`, `TrydosWalletStyles`, `ksh32`...). القيم الفعلية:

- `TrydosWalletAssets.reload` = `'assets/svg/reload.svg'`
- `TrydosWalletStyles.fontFamily` = `'Quicksand'`
- `TrydosWalletStyles.packageName` = `'trydos_wallet'`
- `ksh16 = 16.h` · `ksh32 = 32.h` · `ksh40 = 40.h` · `ksw8 = 8.w`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constent/assets.dart';
import '../constent/constant_design.dart';
import '../constent/styles.dart';

/// Full-screen overlay shown when internet connectivity is lost.
/// Cannot be dismissed — disappears automatically when connectivity returns.
class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key, required this.languageCode});

  final String languageCode;

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isRtl => widget.languageCode == 'ar' || widget.languageCode == 'ku';

  String _title() {
    switch (widget.languageCode) {
      case 'ar':
        return 'لا يوجد اتصال بالإنترنت';
      case 'ku':
        return 'هیچ پەیوەندییەکی ئینتەرنێت نییە';
      case 'tr':
        return 'İnternet Bağlantısı Yok';
      default:
        return 'No Internet Connection';
    }
  }

  String _subtitle() {
    switch (widget.languageCode) {
      case 'ar':
        return 'يرجى التحقق من اتصالك بالإنترنت والتأكد من اتصالك بشبكة Wi-Fi أو بيانات الجوال.';
      case 'ku':
        return 'تکایە پەیوەندی ئینتەرنێتەکەت بپشکنە و دڵنیابە کە بە Wi-Fi یان داتای مۆبایل پەیوەندیت هەیە.';
      case 'tr':
        return 'Lütfen internet bağlantınızı kontrol edin ve Wi-Fi veya mobil veriye bağlı olduğunuzdan emin olun.';
      default:
        return 'Please check your internet connection and make sure you are connected to Wi-Fi or mobile data.';
    }
  }

  String _reconnecting() {
    switch (widget.languageCode) {
      case 'ar':
        return 'في انتظار إعادة الاتصال...';
      case 'ku':
        return 'چاوەڕوانی دووبارە پەیوەندیکردنەوە...';
      case 'tr':
        return 'Yeniden bağlanmayı bekliyorum...';
      default:
        return 'Waiting for connection...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Animated icon container
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120.r,
                    height: 120.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        TrydosWalletAssets.reload,
                        width: 52.r,
                        height: 52.r,
                        colorFilter: const ColorFilter.mode(
                          Color(0xff2C2A2A),
                          BlendMode.srcIn,
                        ),
                        package: TrydosWalletStyles.packageName,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ksh32),
                // Title
                Text(
                  _title(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: TrydosWalletStyles.fontFamily,
                    package: TrydosWalletStyles.packageName,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2C2A2A),
                  ),
                ),
                SizedBox(height: ksh16),
                // Subtitle
                Text(
                  _subtitle(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: TrydosWalletStyles.fontFamily,
                    package: TrydosWalletStyles.packageName,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xff585858),
                    height: 1.6,
                  ),
                ),
                SizedBox(height: ksh40),
                // Reconnecting indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xff0080FF),
                        ),
                      ),
                    ),
                    SizedBox(width: ksw8),
                    Text(
                      _reconnecting(),
                      style: TextStyle(
                        fontFamily: TrydosWalletStyles.fontFamily,
                        package: TrydosWalletStyles.packageName,
                        fontSize: 13.sp,
                        color: const Color(0xff0080FF),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### 4.3 `no_internet_screen.dart` — النسخة المحمولة (للتطبيق المضيف)

نفس التصميم بالضبط، لكن **بدون أي اعتماد على المكتبة**: لا `package:`، لا `flutter_svg`، لا `flutter_screenutil`. استبدلنا الأيقونة بـ `Icons.wifi_off_rounded` بنفس المقاسات.

```dart
import 'package:flutter/material.dart';

/// Full-screen overlay shown when internet connectivity is lost.
/// Cannot be dismissed — disappears automatically when connectivity returns.
class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key, required this.languageCode});

  final String languageCode;

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isRtl => widget.languageCode == 'ar' || widget.languageCode == 'ku';

  String _title() {
    switch (widget.languageCode) {
      case 'ar':
        return 'لا يوجد اتصال بالإنترنت';
      case 'ku':
        return 'هیچ پەیوەندییەکی ئینتەرنێت نییە';
      case 'tr':
        return 'İnternet Bağlantısı Yok';
      default:
        return 'No Internet Connection';
    }
  }

  String _subtitle() {
    switch (widget.languageCode) {
      case 'ar':
        return 'يرجى التحقق من اتصالك بالإنترنت والتأكد من اتصالك بشبكة Wi-Fi أو بيانات الجوال.';
      case 'ku':
        return 'تکایە پەیوەندی ئینتەرنێتەکەت بپشکنە و دڵنیابە کە بە Wi-Fi یان داتای مۆبایل پەیوەندیت هەیە.';
      case 'tr':
        return 'Lütfen internet bağlantınızı kontrol edin ve Wi-Fi veya mobil veriye bağlı olduğunuzdan emin olun.';
      default:
        return 'Please check your internet connection and make sure you are connected to Wi-Fi or mobile data.';
    }
  }

  String _reconnecting() {
    switch (widget.languageCode) {
      case 'ar':
        return 'في انتظار إعادة الاتصال...';
      case 'ku':
        return 'چاوەڕوانی دووبارە پەیوەندیکردنەوە...';
      case 'tr':
        return 'Yeniden bağlanmayı bekliyorum...';
      default:
        return 'Waiting for connection...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 52,
                        color: Color(0xff2C2A2A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _title(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2C2A2A),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _subtitle(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xff585858),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xff0080FF)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _reconnecting(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xff0080FF),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 5. مواصفات التصميم (Design Spec)

| العنصر | القيمة |
|---|---|
| خلفية الشاشة | `Colors.white` (عبر `Material`) |
| دائرة الأيقونة | قطر `120`، لون `#F4F5F5`، `BoxShape.circle` |
| الأيقونة | مقاس `52`، لون `#2C2A2A` |
| أنيميشن النبض | `Tween(0.92 → 1.0)`، مدة `1500ms`، `Curves.easeInOut`، `repeat(reverse: true)` |
| العنوان | `20sp`، `FontWeight.bold`، لون `#2C2A2A` |
| النص التوضيحي | `14sp`، عادي، لون `#585858`، `height: 1.6` |
| نص إعادة الاتصال | `13sp`، لون `#0080FF` |
| المؤشر الدائري | `16×16`، `strokeWidth: 2`، لون `#0080FF` |
| الهوامش الأفقية | `32` |
| المسافات العمودية | أيقونة→عنوان `32` · عنوان→نص `16` · نص→مؤشر `40` |
| التوزيع | `Spacer(flex: 2)` أعلى · `Spacer(flex: 3)` أسفل |
| الاتجاه | `Directionality` — RTL لـ `ar` و `ku` |

---

## 6. طريقة الربط في التطبيق المضيف

### الخيار A (المفضّل) — تغطية التطبيق كله عبر `MaterialApp.builder`

يعرض الشاشة فوق **أي** صفحة في التطبيق، بما فيها صفحات المحفظة والـ Dialogs.

```dart
// lib/widgets/connectivity_gate.dart
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../screens/no_internet_screen.dart';

/// Wraps the whole app and overlays [NoInternetScreen] whenever the device
/// has no real internet access.
class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({
    super.key,
    required this.child,
    required this.languageCode,
    this.onReconnected,
  });

  final Widget child;
  final String languageCode;

  /// Called once each time connectivity is restored — refresh data here.
  final VoidCallback? onReconnected;

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ConnectivityService.instance.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isOffline = !ConnectivityService.instance.isOnline.value;
        });
      });
      ConnectivityService.instance.isOnline.addListener(_onConnectivityChanged);
    });
  }

  @override
  void dispose() {
    ConnectivityService.instance.isOnline
        .removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    final online = ConnectivityService.instance.isOnline.value;
    if (!mounted) return;
    setState(() => _isOffline = !online);
    if (online) widget.onReconnected?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline)
          Positioned.fill(
            child: NoInternetScreen(languageCode: widget.languageCode),
          ),
      ],
    );
  }
}
```

الاستخدام:

```dart
MaterialApp(
  builder: (context, child) => ConnectivityGate(
    languageCode: currentLanguageCode, // 'ar' | 'ku' | 'tr' | 'en'
    onReconnected: () {
      // أعد تحميل البيانات / أعد الاتصال بالـ WebSocket
    },
    child: child ?? const SizedBox.shrink(),
  ),
  home: const MyHomePage(),
);
```

> **مهم:** يجب أن يكون `ConnectivityGate` تحت `Directionality`/`MediaQuery`. استخدام `builder` في `MaterialApp` يضمن ذلك. لا تضعه فوق `MaterialApp`.

### الخيار B — طبقة على صفحة واحدة (نفس ما تفعله المكتبة)

```dart
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      Scaffold(/* محتوى الصفحة */),
      if (_isOffline)
        Positioned.fill(
          child: NoInternetScreen(languageCode: languageCode),
        ),
    ],
  );
}
```

مع نفس منطق `initState` / `dispose` / `_onConnectivityChanged` الموجود في القسم أعلاه.

### ما تفعله المكتبة عند عودة الاتصال

في `home_page.dart`:

```dart
void _onConnectivityChanged() {
  final online = ConnectivityService.instance.isOnline.value;
  if (online) {
    emitLockEvent(LockEvent.lockEvent());   // إعادة تفعيل قفل الجلسة
  }
  if (!mounted) return;
  setState(() => _isOffline = !online);
  if (online) {
    final bloc = context.read<WalletBloc>();
    bloc.add(const WalletReconnectWebSocketRequested());
    bloc.add(const WalletRefreshAllRequested());
    bloc.add(const WalletTransferPurposesLoadRequested());
  }
}
```

في التطبيق المضيف: ضع ما يعادلها داخل `onReconnected`.

---

## 7. المتطلبات

`pubspec.yaml`:

```yaml
dependencies:
  connectivity_plus: ^6.1.4
```

> النسخة المحمولة من الشاشة (القسم 4.3) لا تحتاج `flutter_svg` ولا `flutter_screenutil`.

### أذونات المنصات

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

**iOS** — لا يحتاج إذناً خاصاً. لكن إن كان التطبيق يستخدم `NSAppTransportSecurity` بقيود صارمة، فالاتصال بـ Socket خام على المنفذ 53 غير متأثر بها.

**macOS** (إن وُجد) — فعّل `com.apple.security.network.client` في ملفات `.entitlements`.

---

## 8. حالات خاصة وملاحظات

| الحالة | الملاحظة |
|---|---|
| **تأخير الظهور حتى 5 ثوانٍ** | في حالة "واي فاي بدون نت" لا يُرفض الـ socket فوراً بل يعلّق حتى انتهاء المهلة. لتسريع الاستجابة قلّل `timeout` إلى `Duration(seconds: 2)`. |
| **الحالة الابتدائية `true`** | `isOnline` يبدأ بـ `true` عمداً، حتى لا تومض الشاشة عند الإقلاع قبل انتهاء أول فحص. |
| **`8.8.8.8` محجوب في بعض الشبكات** | بعض شبكات الشركات/الدول تحجب DNS الخارجي. الحل: جرّب أكثر من هدف بالتوازي (مثلاً `1.1.1.1:53` و `8.8.8.8:53`) واعتبر النتيجة `true` إذا نجح أي منها، أو استبدل الهدف بخادم API الخاص بالتطبيق. |
| **Flutter Web** | `dart:io` غير مدعوم. استخدم conditional import: ملف `_io.dart` بالكود أعلاه وملف `_web.dart` يعتمد على `connectivity_plus` وحده (بدون فحص TCP). |
| **استهلاك البطارية** | فحص كل 10 ثوانٍ عبر socket خفيف جداً. إن أردت تقليله أكثر، أوقف المؤقت عند دخول التطبيق للخلفية عبر `AppLifecycleState.paused`. |
| **`dispose()` للخدمة** | الخدمة singleton تعيش طوال عمر التطبيق — **لا تستدعِ `ConnectivityService.instance.dispose()`** إلا عند إغلاق التطبيق فعلياً، لأنه يستدعي `isOnline.dispose()` ويجعل الـ notifier غير قابل للاستخدام. |
| **`initialize()` آمن للاستدعاء المتكرر** | يحميه العلم `_initialized`. |

---

## 9. قائمة تحقق للتنفيذ في التطبيق المضيف

- [ ] إضافة `connectivity_plus: ^6.1.4` إلى `pubspec.yaml` ثم `flutter pub get`
- [ ] إضافة أذونات `INTERNET` و `ACCESS_NETWORK_STATE` في `AndroidManifest.xml`
- [ ] إنشاء `lib/services/connectivity_service.dart` بالكود من القسم 4.1 حرفياً
- [ ] إنشاء `lib/screens/no_internet_screen.dart` بالكود من القسم 4.3 (أو 4.2 إن كان `flutter_screenutil` + `flutter_svg` متوفرين)
- [ ] إنشاء `lib/widgets/connectivity_gate.dart` من القسم 6 (الخيار A)
- [ ] تغليف `MaterialApp` عبر `builder:` بـ `ConnectivityGate` وتمرير `languageCode` الحالي للتطبيق
- [ ] تنفيذ منطق إعادة التحميل داخل `onReconnected`
- [ ] الاختبار: (1) إيقاف الواي فاي كلياً → تظهر خلال ~5 ثوانٍ (2) الاتصال براوتر مفصول عن الإنترنت → تظهر أيضاً (3) عودة النت → تختفي خلال ~5 ثوانٍ وتُعاد البيانات
