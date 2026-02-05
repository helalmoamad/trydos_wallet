import 'package:dio/dio.dart';

/// Interceptor لطباعة الطلبات والردود في وضع Debug.
class ApiDebugInterceptor extends Interceptor {
  ApiDebugInterceptor({this.enabled = true, this.prefix = '[API]'});

  final bool enabled;
  final String prefix;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) {
      handler.next(options);
      return;
    }
    _log('═══════════════════════════════════════');
    _log('$prefix REQUEST');
    _log('${options.method} ${options.uri}');
    _log('Headers: ${options.headers}');
    if (options.queryParameters.isNotEmpty) {
      _log('Query: ${options.queryParameters}');
    }
    if (options.data != null) {
      _log('Body: ${options.data}');
    }
    _log('═══════════════════════════════════════');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!enabled) {
      handler.next(response);
      return;
    }
    _log('───────────────────────────────────────');
    _log('$prefix RESPONSE [SUCCESS]');
    _log('${response.requestOptions.method} ${response.requestOptions.uri}');
    _log('Status: ${response.statusCode}');
    _log('Data: ${response.data}');
    _log('───────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) {
      handler.next(err);
      return;
    }
    final res = err.response;
    _log('XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
    _log('$prefix RESPONSE [FAILED]');
    _log('${err.requestOptions.method} ${err.requestOptions.uri}');
    _log('Error Type: ${err.type}');
    _log('Status: ${res?.statusCode ?? "N/A (لا يوجد استجابة من الخادم)"}');
    _log('Message: ${err.message ?? "—"}');
    _log('Underlying Error: ${err.error ?? "—"}');
    if (res?.data != null) {
      _log('Response Data: ${res!.data}');
    } else {
      _log('Response Data: N/A (ربما خطأ شبكة، انقطاع، أو timeout)');
    }
    _log('StackTrace: ${err.stackTrace}');
    _log('XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
    handler.next(err);
  }

  void _log(String msg) {
    // ignore: avoid_print
    print(msg);
  }
}
