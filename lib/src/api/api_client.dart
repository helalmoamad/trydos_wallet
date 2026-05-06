import 'package:dio/dio.dart';
import 'package:trydos_wallet/src/api/api_client_io.dart'
    if (dart.library.html) 'package:trydos_wallet/src/api/api_client_stub.dart'
    as api_io;
import 'package:trydos_wallet/src/api/api_headers.dart';
import 'package:trydos_wallet/src/api/api_interceptors.dart';

/// نتيجة موحدة لطلبات API.
class ApiResult<T> {
  ApiResult.success(this.data)
    : error = null,
      errorMessage = null,
      _manualFailure = false;
  ApiResult.failure(this.error, {this.errorMessage})
    : data = null,
      _manualFailure = false;
  ApiResult.manualFailure({this.errorMessage})
    : data = null,
      error = null,
      _manualFailure = true;

  final T? data;
  final DioException? error;
  final String? errorMessage;
  final bool _manualFailure;

  bool get isSuccess => error == null && !_manualFailure;
  bool get isFailure => error != null || _manualFailure;
}

/// عميل DIO جاهز لطلبات GET, POST, PUT, DELETE مع Interceptor و Headers.
class ApiClient {
  ApiClient({
    required String baseUrl,
    ApiHeadersConfig? headersConfig,
    bool debug = false,
    bool allowBadCertificate = false,
    Duration? connectTimeout,
    Duration? receiveTimeout,
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
    if (allowBadCertificate) {
      api_io.configureAllowBadCertificate(_dio);
    }
    // _dio.interceptors.add(ApiErrorInterceptor()); // Removed in favor of direct handling
    _dio.interceptors.add(ApiDebugInterceptor(enabled: debug));
    _dio.interceptors.add(ApiAuthInterceptor());
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

  void updateAllowBadCertificate(bool allowBadCertificate) {
    if (allowBadCertificate) {
      api_io.configureAllowBadCertificate(_dio);
    }
  }

  String? _extractErrorMessage(DioException e) {
    return _extractErrorMessageFromData(e.response?.data) ?? e.message;
  }

  String? _extractErrorMessageFromData(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data['msg']?.toString();
    } else if (data is String && data.isNotEmpty) {
      return data;
    }
    return null;
  }

  void _handle400(dynamic data) {
    final msg = _extractErrorMessageFromData(data);
    if (msg != null) {
      // ignore: avoid_print
      print('[ApiClient] Radical 400 emission: $msg');
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
        );
      }
      final data = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _handle400(e.response?.data);
      }
      return ApiResult<T>.failure(e, errorMessage: _extractErrorMessage(e));
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
        );
      }
      final result = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(result);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _handle400(e.response?.data);
      }
      return ApiResult<T>.failure(e, errorMessage: _extractErrorMessage(e));
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
        );
      }
      final result = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(result);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _handle400(e.response?.data);
      }
      return ApiResult<T>.failure(e, errorMessage: _extractErrorMessage(e));
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
        );
      }
      final result = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(result);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _handle400(e.response?.data);
      }
      return ApiResult<T>.failure(e, errorMessage: _extractErrorMessage(e));
    }
  }
}
