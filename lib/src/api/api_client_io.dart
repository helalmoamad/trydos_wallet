import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// تفعيل تجاوز التحقق من شهادة SSL (للتطوير فقط).
void configureAllowBadCertificate(Dio dio) {
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  };
}
