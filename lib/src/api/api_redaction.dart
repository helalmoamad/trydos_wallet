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
  if (data is String) return _elideBulk(data);
  return data;
}

/// Longest string printed in full. Past this it is almost certainly an
/// encoded blob rather than anything a reader would parse by eye.
const int _bulkStringThreshold = 256;

/// Replaces an encoded blob with a description of it.
///
/// KYC alone sends three images per submission, each a few hundred KB of
/// base64. Printed verbatim they bury every other line in the log, cost real
/// time to serialise on the UI thread, and spill the user's face and ID into
/// logcat where the session's end does not reach. What a log reader actually
/// needs is that an image was there and roughly how big — the bytes tell them
/// nothing.
String _elideBulk(String value) {
  if (value.length <= _bulkStringThreshold) return value;

  final comma = value.indexOf(',');
  final isDataUrl = value.startsWith('data:') && comma > 0;
  final payloadLength = isDataUrl ? value.length - comma - 1 : value.length;
  // base64 carries 3 bytes per 4 characters.
  final bytes = (payloadLength * 3) ~/ 4;
  final kb = (bytes / 1024).toStringAsFixed(0);

  if (isDataUrl) {
    // Keep the media type: "was it a JPEG?" is a real question when the
    // server rejects an image.
    final mime = value.substring(5, comma).split(';').first;
    return '<$mime ~${kb}KB>';
  }
  return '<${value.length} chars ~${kb}KB>';
}
