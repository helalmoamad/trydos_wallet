import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trydos_wallet/src/api/api_redaction.dart';

/// Max characters stored for a single request/response body. KYC requests send
/// multi-MB base64 images, so we truncate to keep the in-memory buffer small.
const int _kMaxBodyChars = 20000;

/// A single captured API request/response for the in-app network inspector.
class ApiLogEntry {
  ApiLogEntry({
    required this.method,
    required this.url,
    required this.path,
    required this.requestHeaders,
    required this.queryParameters,
    required this.requestBody,
    required this.statusCode,
    required this.responseHeaders,
    required this.responseBody,
    required this.errorMessage,
    required this.timestamp,
    required this.durationMs,
  });

  final String method;

  /// Full request URI (host + path + query).
  final String url;

  /// Short path, used as the card subtitle.
  final String path;
  final Map<String, dynamic> requestHeaders;
  final Map<String, dynamic> queryParameters;

  /// Already stringified + truncated bodies (we never retain large structures).
  final String requestBody;
  final int? statusCode;
  final Map<String, String> responseHeaders;
  final String responseBody;
  final String? errorMessage;
  final DateTime timestamp;
  final int durationMs;

  bool get isError =>
      errorMessage != null || (statusCode != null && statusCode! >= 400);
}

/// In-memory store of API logs, exposed as a [ValueListenable] for the UI.
class ApiLogStore {
  ApiLogStore._();
  static final ApiLogStore instance = ApiLogStore._();

  static const int _maxEntries = 200;

  final ValueNotifier<List<ApiLogEntry>> _entries =
      ValueNotifier<List<ApiLogEntry>>(const <ApiLogEntry>[]);

  ValueListenable<List<ApiLogEntry>> get listenable => _entries;

  /// Whether the inspector is available at all.
  ///
  /// DELIBERATELY `true`, including in release builds: QA relies on the
  /// long-press-Settings inspector on release APKs, and the team chose to keep
  /// that until it is no longer needed.
  ///
  /// ACCEPTED RISK: the buffer holds full response bodies — balances,
  /// transaction history, transfer details, KYC and personal data — and the
  /// page offers a copy button, so anyone holding an end user's phone can read
  /// and exfiltrate them. Auth headers are redacted (see api_redaction.dart),
  /// bodies are not.
  ///
  /// Set this to `kDebugMode` to close it; every call site already checks it,
  /// so that one word is the whole fix. The Semgrep rule
  /// `trydos-api-inspector-must-stay-debug-only` reports this on every scan so
  /// it stays visible rather than forgotten.
  static const bool isAvailable = true;

  void add(ApiLogEntry entry) {
    if (!isAvailable) return;
    // Newest first; cap the buffer to avoid unbounded growth.
    final next = <ApiLogEntry>[entry, ..._entries.value];
    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }
    _entries.value = next;
  }

  void clear() => _entries.value = const <ApiLogEntry>[];
}

const String _kLogStartKey = '__api_log_start';

/// Dio interceptor that records every request/response/error into [ApiLogStore].
/// Logging never breaks the interceptor chain — all work is guarded.
class ApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!ApiLogStore.isAvailable) {
      handler.next(options);
      return;
    }
    options.extra[_kLogStartKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (!ApiLogStore.isAvailable) {
      handler.next(response);
      return;
    }
    _record(
      options: response.requestOptions,
      statusCode: response.statusCode,
      responseHeaders: response.headers.map,
      responseBody: response.data,
      errorMessage: null,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!ApiLogStore.isAvailable) {
      handler.next(err);
      return;
    }
    _record(
      options: err.requestOptions,
      statusCode: err.response?.statusCode,
      responseHeaders: err.response?.headers.map ?? const {},
      responseBody: err.response?.data,
      errorMessage: err.message ?? err.error?.toString() ?? err.type.name,
    );
    handler.next(err);
  }

  void _record({
    required RequestOptions options,
    required int? statusCode,
    required Map<String, List<String>> responseHeaders,
    required dynamic responseBody,
    required String? errorMessage,
  }) {
    try {
      final start = options.extra[_kLogStartKey];
      final durationMs = start is int
          ? DateTime.now().millisecondsSinceEpoch - start
          : 0;
      ApiLogStore.instance.add(
        ApiLogEntry(
          method: options.method,
          url: options.uri.toString(),
          path: options.path,
          // Redact before storing: the inspector's buffer is readable from
          // inside the app and its entries get shared/exported by testers.
          requestHeaders: redactHeaders(
            Map<String, dynamic>.from(options.headers),
          ),
          queryParameters: redactData(
            Map<String, dynamic>.from(options.queryParameters),
          ) as Map<String, dynamic>,
          requestBody: _stringify(redactData(options.data)),
          statusCode: statusCode,
          responseHeaders: redactHeaders(
            responseHeaders.map((key, value) => MapEntry(key, value.join(', '))),
          ).map((key, value) => MapEntry(key, value.toString())),
          responseBody: _stringify(redactData(responseBody)),
          errorMessage: errorMessage,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        ),
      );
    } catch (_) {
      // Never break the interceptor chain because of logging.
    }
  }

  /// Pretty-print a body to a string and truncate if very large.
  static String _stringify(dynamic body) {
    if (body == null) return '';
    String text;
    if (body is String) {
      text = body;
    } else if (body is FormData) {
      final fields = body.fields
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      final files = body.files
          .map((e) => '${e.key}: <file ${e.value.filename ?? ''}>')
          .join('\n');
      text = 'FormData\n$fields${files.isEmpty ? '' : '\n$files'}';
    } else {
      try {
        text = const JsonEncoder.withIndent('  ').convert(body);
      } catch (_) {
        text = body.toString();
      }
    }
    if (text.length > _kMaxBodyChars) {
      return '${text.substring(0, _kMaxBodyChars)}\n… (truncated, '
          '${text.length} chars total)';
    }
    return text;
  }
}
