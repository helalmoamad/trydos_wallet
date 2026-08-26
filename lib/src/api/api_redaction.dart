/// Redaction helpers shared by the debug logger and the in-app network
/// inspector.
///
/// Request headers carry `Authorization: Bearer <jwt>`. Anything that prints
/// or stores them verbatim puts a live credential into logcat or into the
/// inspector's in-memory buffer, where any app holding the READ_LOGS
/// permission — or anyone holding the device — can read it.
library;

/// Header names whose values must never be logged in full.
const Set<String> _sensitiveHeaders = <String>{
  'authorization',
  'proxy-authorization',
  'cookie',
  'set-cookie',
  'x-api-key',
  'x-auth-token',
  'x-refresh-token',
};

/// Body/query keys whose values must never be logged in full.
final RegExp _sensitiveKeyPattern = RegExp(
  r'(token|password|passwd|pin|secret|otp|credential|jwt|api[_-]?key|'
  r'authorization|cvv|card[_-]?number|pan)',
  caseSensitive: false,
);

/// Replaces a secret with a shape-preserving placeholder.
///
/// Keeps the scheme (`Bearer`) and a 4-character tail so a log reader can still
/// tell two different tokens apart and confirm which one was sent, without the
/// value being usable.
String redactValue(Object? value) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) return text;

  final space = text.indexOf(' ');
  if (space > 0 && space < 12) {
    // "Bearer eyJhbGci..." → keep the scheme, redact the credential.
    final scheme = text.substring(0, space);
    return '$scheme ${_mask(text.substring(space + 1))}';
  }
  return _mask(text);
}

String _mask(String secret) {
  if (secret.length <= 8) return '***REDACTED***';
  return '***REDACTED(${secret.length})…${secret.substring(secret.length - 4)}';
}

/// Copy of [headers] with every sensitive value replaced.
Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
  return headers.map((key, value) {
    if (_sensitiveHeaders.contains(key.toLowerCase())) {
      return MapEntry(key, redactValue(value));
    }
    return MapEntry(key, value);
  });
}

/// Copy of [map] with values of secret-looking keys replaced. Recurses into
/// nested maps and lists so a token buried in a request body is caught too.
dynamic redactData(dynamic data) {
  if (data is Map) {
    return data.map<String, dynamic>((key, value) {
      final name = key.toString();
      if (_sensitiveKeyPattern.hasMatch(name)) {
        return MapEntry(name, redactValue(value));
      }
      return MapEntry(name, redactData(value));
    });
  }
  if (data is List) {
    return data.map(redactData).toList();
  }
  return data;
}
