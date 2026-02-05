import 'dart:io' show HttpHeaders, Platform;

import 'package:dio/dio.dart';

/// إعدادات الهيدر الافتراضية للطلبات.
class ApiHeadersConfig {
  ApiHeadersConfig({
    this.languageCode = 'ar',
    this.isKurdish = false,
    this.applicationVersion = '1.0.0',
    this.token,
    bool? isAndroid,
  }) : isAndroid = isAndroid ?? Platform.isAndroid;

  final String languageCode;
  final bool isKurdish;
  final String applicationVersion;
  final String? token;
  final bool isAndroid;

  String get lang {
    if (languageCode == 'ar') {
      return isKurdish ? 'ku' : 'ar';
    }
    return languageCode;
  }

  String get userAgent =>
      'device OS: ${isAndroid ? 'Android' : 'IOS'}, application version: $applicationVersion';
}

/// بناة هيدر طلبات API.
class ApiHeaders {
  ApiHeaders._();

  static void apply(Dio client, ApiHeadersConfig config) {
    final headers = client.options.headers;
    headers['lang'] = config.lang;
    headers['x-lang'] = config.lang;
    headers['Accept-Language'] = config.lang;
    headers['User-Agent'] = config.userAgent;
    if (config.token != null && config.token!.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer ${config.token}';
    }
  }
}
