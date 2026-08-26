import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// تفعيل/إلغاء تجاوز التحقق من شهادة SSL (للتطوير فقط).
///
/// يستبدل الـ adapter بالكامل بدل تعديل `createHttpClient` عليه، لأن
/// [IOHttpClientAdapter] يخزّن أول `HttpClient` ينشئه (`_cachedHttpClient`)
/// ويعيد استخدامه؛ فتعديل الحقل بعد أول طلب لا يغيّر شيئاً.
///
/// [allow] = false يعيد السلوك الآمن الافتراضي حتى لو كان التجاوز مفعّلاً
/// من قبل، فلا يبقى العميل غير آمن لبقية عمر التطبيق.
void configureAllowBadCertificate(Dio dio, {bool allow = true}) {
  final previous = dio.httpClientAdapter;

  dio.httpClientAdapter = allow
      ? IOHttpClientAdapter(
          createHttpClient: () =>
              HttpClient()..badCertificateCallback = (_, __, ___) => true,
        )
      : IOHttpClientAdapter();

  // Release the old adapter's pooled sockets without killing in-flight
  // requests (force: false lets them drain first).
  previous.close();
}
