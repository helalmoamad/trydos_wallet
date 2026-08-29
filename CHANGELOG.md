## Unreleased

### 💥 تغيير كاسر — `allowBadCertificate` أُزيل

* **أُزيل البارامتر `allowBadCertificate` من `TrydosWalletConfig` و`ApiClient`
  و`WalletWebSocketService`، وأُزيلت الدالة `ApiClient.updateAllowBadCertificate`.**
  التطبيقات المضيفة التي تمرّره لن تُترجم — **الحل: احذف السطر**، لا بديل له
  ولا قيمة تُمرَّر.
* أُزيل تنفيذ التجاوز نفسه لا العلَم فقط: حُذف الملفان
  `lib/src/api/api_client_io.dart` و`api_client_stub.dart` (كانا يحملان
  `badCertificateCallback`)، وحُذف `HttpOverrides` من خدمة الـ WebSocket.
* **التحقق من الشهادات مفروض دائماً**: يستخدم Dio عميله الافتراضي بتحقق كامل
  من السلسلة واسم المضيف. الشهادة المزيّفة أو الموقّعة ذاتياً أو المنتهية أو
  غير المطابقة تُسقِط الاتصال بـ `HandshakeException`.
* السياق: كان التجاوز مؤقتاً لأن مضيف التطوير
  `trydos_wallet_develop.ramaaz.dev` يحوي شرطات سفلية يمنعها RFC 1123، فيرفض
  BoringSSL مطابقتها مع الشهادة البديلة `*.ramaaz.dev`. انتقل الباك اند إلى
  `rdb-develop.ramaaz.dev` فزال السبب.
* قاعدة Semgrep `trydos-tls-no-insecure-adapter` تمنع عودة التجاوز.

## 0.0.2

* Fix transactions pagination freeze in wallet home screen by deferring load-more dispatch to post-frame scheduling to avoid Build scheduled during frame assertions with overscroll/stretch physics.
* Prevent duplicate/re-entrant load-more triggers at list end by adding queue and lock guards for the same frame/viewport state.
* Move pagination lock reset logic out of build phase into bloc listener flow to avoid side effects during layout/paint.

## 0.0.1

* TODO: Describe initial release.
