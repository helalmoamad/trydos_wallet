import 'package:dio/dio.dart';

import 'api_client_io.dart' if (dart.library.html) 'api_client_stub.dart' as api_io;
import 'api_headers.dart';
import 'api_interceptors.dart';

/// نتيجة موحدة لطلبات API.
class ApiResult<T> {
  ApiResult.success(this.data) : error = null;
  ApiResult.failure(this.error) : data = null;

  final T? data;
  final DioException? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
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
  })  : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: connectTimeout ?? const Duration(seconds: 30),
            receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    if (headersConfig != null) {
      ApiHeaders.apply(_dio, headersConfig);
    }
    if (allowBadCertificate) {
      api_io.configureAllowBadCertificate(_dio);
    }
    _dio.interceptors.add(ApiDebugInterceptor(enabled: debug));
  }

  final Dio _dio;

  Dio get dio => _dio;

  /// تحديث هيدر الـ client (مثلاً بعد تغيير التوكن).
  void updateHeaders(ApiHeadersConfig config) {
    ApiHeaders.apply(_dio, config);
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
      final data = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(data);
    } on DioException catch (e) {
      return ApiResult<T>.failure(e);
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
      final result = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(result);
    } on DioException catch (e) {
      return ApiResult<T>.failure(e);
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
      final result = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(result);
    } on DioException catch (e) {
      return ApiResult<T>.failure(e);
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
      final result = fromJson != null && res.data != null
          ? fromJson(res.data)
          : res.data as T?;
      return ApiResult.success(result);
    } on DioException catch (e) {
      return ApiResult<T>.failure(e);
    }
  }
}
