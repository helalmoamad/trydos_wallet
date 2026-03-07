import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'dart:async';

/// حدث بسيط لتمثيل حالات المصادقة الصالحة للإرسال للتطبيق المستدعي.
class AuthEvent {
  final String name;

  const AuthEvent._(this.name);

  factory AuthEvent.unauthenticated() => const AuthEvent._('unauthenticated');

  @override
  String toString() => 'AuthEvent.$name';
}

/// حدث لتمثيل أخطاء API العامة (مثل 400) التي تحتاج لعرض رسالة للمستخدم.
class ApiErrorEvent {
  final String message;
  final int? statusCode;

  const ApiErrorEvent(this.message, {this.statusCode});
}

// Broadcast streams تسمح لأي عدد من المستمعين بالتسجيل.
final StreamController<AuthEvent> _authEventController =
    StreamController<AuthEvent>.broadcast();
final StreamController<ApiErrorEvent> _errorEventController =
    StreamController<ApiErrorEvent>.broadcast();

/// ستستعملها التطبيقات للاستماع لأحداث المصادقة.
Stream<AuthEvent> get authEvents => _authEventController.stream;

/// ستستعملها التطبيقات للاستماع لأخطاء API لعرض SnackBars.
Stream<ApiErrorEvent> get errorEvents => _errorEventController.stream;

/// مفتاح عالمي لـ ScaffoldMessenger لضمان إمكانية عرض SnackBars من أي مكان.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// دوال داخلية لإرسال الأحداث دون كسر الـ interceptor chain.
void emitAuthEvent(AuthEvent evt) {
  try {
    _authEventController.add(evt);
  } catch (_) {
    // ignore stream errors
  }
}

void emitApiErrorEvent(ApiErrorEvent evt) {
  try {
    _errorEventController.add(evt);
  } catch (_) {
    // ignore stream errors
  }
}

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
    _log('Status: ${res?.statusCode ?? "N/A (no server response)"}');
    _log('Message: ${err.message ?? "—"}');
    _log('Underlying Error: ${err.error ?? "—"}');
    if (res?.data != null) {
      _log('Response Data: ${res!.data}');
    } else {
      _log('Response Data: N/A (network error, disconnect, or timeout)');
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

/// Interceptor للكشف عن أخطاء المصادقة (مثال: 401 أو رسالة تحتوي على 'unAthu').
class ApiAuthInterceptor extends Interceptor {
  ApiAuthInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final res = err.response;

    var isAuthError = false;

    if (res?.statusCode == 401) {
      isAuthError = true;
    } else if (res?.data != null) {
      try {
        final data = res!.data;
        if (data is Map<String, dynamic>) {
          final msg = data['message']?.toString() ?? '';
          if (msg.toLowerCase().contains('unauth') ||
              msg.toLowerCase().contains('unauthorized')) {
            isAuthError = true;
          }
        } else if (data is String) {
          if (data.toLowerCase().contains('unauth') ||
              data.toLowerCase().contains('unauthorized')) {
            isAuthError = true;
          }
        }
      } catch (_) {
        // ignore parsing errors
      }
    }

    if (isAuthError) {
      try {
        emitAuthEvent(AuthEvent.unauthenticated());
      } catch (_) {
        // swallow errors to avoid breaking the interceptor chain
      }
    }

    handler.next(err);
  }
}

/// Interceptor للكشف عن أخطاء 400 وإرسال حدث لعرض رسالة للمستخدم.
class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print(
      '[ApiErrorInterceptor] onError called. Status: ${err.response?.statusCode}',
    );

    if (err.response?.statusCode == 400) {
      final res = err.response;
      String? errorMessage;

      if (res?.data != null) {
        final data = res!.data;
        // ignore: avoid_print
        print('[ApiErrorInterceptor] Response data type: ${data.runtimeType}');

        if (data is Map) {
          errorMessage =
              data['message']?.toString() ??
              data['error']?.toString() ??
              data['msg']?.toString();
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }
      }

      errorMessage ??= err.message;

      if (errorMessage != null) {
        // ignore: avoid_print
        print('[ApiErrorInterceptor] Emitting error event: $errorMessage');
        emitApiErrorEvent(ApiErrorEvent(errorMessage, statusCode: 400));
      }
    }
    handler.next(err);
  }
}
