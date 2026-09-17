import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trydos_wallet/src/api/api_headers.dart';
import 'package:trydos_wallet/src/api/api_interceptors.dart';
import 'package:trydos_wallet/src/api/api_log.dart';

/// نتيجة موحدة لطلبات API.
class ApiResult<T> {
  ApiResult.success(this.data, {this.statusCode})
    : error = null,
      errorMessage = null,
      errorCode = null,
      _manualFailure = false;
  ApiResult.failure(
    this.error, {
    this.errorMessage,
    this.statusCode,
    this.errorCode,
  }) : data = null,
       _manualFailure = false;
  ApiResult.manualFailure({this.errorMessage, this.statusCode, this.errorCode})
    : data = null,
      error = null,
      _manualFailure = true;

  final T? data;
  final DioException? error;
  final String? errorMessage;
  final bool _manualFailure;

  /// HTTP status of the response, when one came back.
  ///
  /// Callers that must branch on the outcome (404 vs 409 vs 429) read this
  /// instead of pattern-matching [errorMessage], which is localized prose.
  final int? statusCode;

  /// Machine-readable `code` from a `{ statusCode, code, message }` error body.
  ///
  /// This is the field to branch on. [errorMessage] is only ever a fallback to
  /// show the user, because the backend localizes it per `Accept-Language`.
  final String? errorCode;

  bool get isSuccess => error == null && !_manualFailure;
  bool get isFailure => error != null || _manualFailure;

  /// True when the request never produced a response: timeout or a dropped
  /// connection. The caller does not know whether the server acted, so a
  /// payment must be retried with the same idempotency key rather than
  /// reported as a failure.
  bool get isTimeoutOrConnectionLoss {
    final e = error;
    if (e == null) return false;
    if (e.response != null) return false;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        return true;
      default:
        return false;
    }
  }
}

/// عميل DIO جاهز لطلبات GET, POST, PUT, DELETE مع Interceptor و Headers.
class ApiClient {
  ApiClient({
    required String baseUrl,
    ApiHeadersConfig? headersConfig,
    bool debug = false,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    // KYC client passes false: its 401s stay inside the library (see
    // ApiAuthInterceptor.emitAuthEvents).
    bool emitAuthEvents = true,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: connectTimeout ?? const Duration(seconds: 30),
           receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
           headers: {
             'Content-Type': 'application/json',
             'Accept': 'application/json',
           },
           validateStatus: (status) => status != null && status <= 400,
         ),
       ) {
    if (headersConfig != null) {
      ApiHeaders.apply(_dio, headersConfig);
    }
    // No badCertificateCallback, no custom adapter: Dio keeps its default
    // client, which performs full chain + hostname validation against the
    // platform trust store. A forged or mismatched certificate fails the
    // handshake.
    // _dio.interceptors.add(ApiErrorInterceptor()); // Removed in favor of direct handling
    _dio.interceptors.add(ApiDebugInterceptor(enabled: debug));
    _dio.interceptors.add(
      ApiAuthInterceptor(emitAuthEvents: emitAuthEvents),
    );
    // Capture every request/response into the in-app network inspector.
    // Not registered at all in release builds — see ApiLogStore.isAvailable.
    if (ApiLogStore.isAvailable) {
      _dio.interceptors.add(ApiLogInterceptor());
    }
  }

  final Dio _dio;

  Dio get dio => _dio;

  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// تحديث هيدر الـ client (مثلاً بعد تغيير التوكن).
  void updateHeaders(ApiHeadersConfig config) {
    ApiHeaders.apply(_dio, config);
  }

  String? _extractErrorMessage(DioException e) {
    return _extractErrorMessageFromData(e.response?.data) ?? e.message;
  }

  String? _extractErrorMessageFromData(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      // Prefer the precise backend reason carried in `detail` (often a nested
      // object or a JSON-encoded string) over the generic top-level `error`.
      return data['message']?.toString() ??
          _extractFromDetail(data['detail']) ??
          data['error']?.toString() ??
          data['msg']?.toString();
    } else if (data is String && data.isNotEmpty) {
      return data;
    }
    return null;
  }

  /// Pull a message out of a `detail` field that may be a nested map or a
  /// JSON-encoded string, e.g. {"message":"You are already verified",...}.
  String? _extractFromDetail(dynamic detail) {
    if (detail == null) return null;
    Map<dynamic, dynamic>? map;
    if (detail is Map) {
      map = detail;
    } else if (detail is String && detail.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(detail);
        if (decoded is Map) {
          map = decoded;
        } else {
          return detail; // plain string detail
        }
      } catch (_) {
        return detail; // not JSON → use as-is
      }
    }
    if (map == null) return null;
    return map['message']?.toString() ?? map['error']?.toString();
  }

  /// Pull the machine-readable `code` out of a `{ statusCode, code, message }`
  /// error body. Returns null when the backend sent no code.
  String? _extractErrorCodeFromData(dynamic data) {
    if (data is! Map) return null;
    final code = data['code'] ?? data['errorCode'];
    if (code == null) return null;
    final text = code.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _extractErrorCode(DioException e) =>
      _extractErrorCodeFromData(e.response?.data);

  void _handle400(dynamic data) {
    final msg = _extractErrorMessageFromData(data);
    if (msg != null) {
      if (kDebugMode) {
        debugPrint('[ApiClient] Radical 400 emission: $msg');
      }
      emitApiErrorEvent(ApiErrorEvent(msg, statusCode: 400));
    }
  }

  /// GET
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      if (res.statusCode == 400) {
        _handle400(res.data);
        return ApiResult<T>.manualFailure(
          errorMessage: _extractErrorMessageFromData(res.data),
          statusCode: 400,
          errorCode: _extractErrorCodeFromData(res.data),
        );
      }
      final data = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(data, statusCode: res.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _handle400(e.response?.data);
      }
      return ApiResult<T>.failure(
        e,
        errorMessage: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        errorCode: _extractErrorCode(e),
      );
    }
  }

  /// POST
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      if (res.statusCode == 400) {
        _handle400(res.data);
        return ApiResult<T>.manualFailure(
          errorMessage: _extractErrorMessageFromData(res.data),
          statusCode: 400,
          errorCode: _extractErrorCodeFromData(res.data),
        );
      }
      final result = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(result, statusCode: res.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _handle400(e.response?.data);
      }
      return ApiResult<T>.failure(
        e,
        errorMessage: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        errorCode: _extractErrorCode(e),
      );
    }
  }

  /// PUT
  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      if (res.statusCode == 400) {
        _handle400(res.data);
        return ApiResult<T>.manualFailure(
          errorMessage: _extractErrorMessageFromData(res.data),
          statusCode: 400,
          errorCode: _extractErrorCodeFromData(res.data),
        );
      }
      final result = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(result, statusCode: res.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _handle400(e.response?.data);
      }
      return ApiResult<T>.failure(
        e,
        errorMessage: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        errorCode: _extractErrorCode(e),
      );
    }
  }

  /// PATCH
  Future<ApiResult<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      if (res.statusCode == 400) {
        _handle400(res.data);
        return ApiResult<T>.manualFailure(
          errorMessage: _extractErrorMessageFromData(res.data),
          statusCode: 400,
          errorCode: _extractErrorCodeFromData(res.data),
        );
      }
      final result = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(result, statusCode: res.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _handle400(e.response?.data);
      }
      return ApiResult<T>.failure(
        e,
        errorMessage: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        errorCode: _extractErrorCode(e),
      );
    }
  }

  /// DELETE
  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      if (res.statusCode == 400) {
        _handle400(res.data);
        return ApiResult<T>.manualFailure(
          errorMessage: _extractErrorMessageFromData(res.data),
          statusCode: 400,
          errorCode: _extractErrorCodeFromData(res.data),
        );
      }
      final result = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(result, statusCode: res.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _handle400(e.response?.data);
      }
      return ApiResult<T>.failure(
        e,
        errorMessage: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        errorCode: _extractErrorCode(e),
      );
    }
  }
}
