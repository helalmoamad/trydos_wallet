import 'package:flutter/foundation.dart';

/// Step-by-step trace of the KYC flow, for following what actually happened.
///
/// The flow spans two servers, a native SDK and half a dozen screens, and a
/// failure at the end rarely says which step went wrong. This prints the
/// shape of each step — which call, what it answered, how long it took — so a
/// log read after the fact tells the story.
///
/// **It never prints the contents.** A KYC response carries face images,
/// national numbers, names and dates of birth; a log line holding those
/// outlives the session in logcat, where any app with READ_LOGS — or anyone
/// holding the phone — can read it. Only counts, codes, statuses and sizes go
/// out. Where an identifier genuinely helps (a session id, a request id), it
/// is shortened rather than printed whole.
///
/// Debug builds only: [kDebugMode] is a compile-time constant, so in release
/// the calls and their arguments are tree-shaken away entirely.
class KycTrace {
  KycTrace._();

  static const String _tag = '[KYC]';

  /// When the flow started, so each line can carry an elapsed time.
  static DateTime? _startedAt;

  /// Marks the beginning of an attempt and resets the clock.
  static void begin(String what) {
    if (!kDebugMode) return;
    _startedAt = DateTime.now();
    debugPrint('$_tag ▶ $what');
  }

  /// A step being attempted.
  static void step(String what, [Map<String, Object?>? details]) {
    if (!kDebugMode) return;
    debugPrint('$_tag ${_elapsed()} · $what${_format(details)}');
  }

  /// A step that worked.
  static void ok(String what, [Map<String, Object?>? details]) {
    if (!kDebugMode) return;
    debugPrint('$_tag ${_elapsed()} ✓ $what${_format(details)}');
  }

  /// A step that did not.
  static void fail(String what, [Map<String, Object?>? details]) {
    if (!kDebugMode) return;
    debugPrint('$_tag ${_elapsed()} ✗ $what${_format(details)}');
  }

  /// Shortens an identifier for logs: enough to match two lines to the same
  /// session, not enough to be reused.
  ///
  /// Returns `null` unchanged so a missing id is visible as missing rather
  /// than as an empty string.
  static String? id(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '<empty>';
    if (trimmed.length <= 8) return trimmed;
    return '${trimmed.substring(0, 4)}…${trimmed.substring(trimmed.length - 4)}';
  }

  /// Describes an image payload by size alone.
  ///
  /// Printing a data URL would put the user's face in the log; its length is
  /// what a reader actually needs — "did we send an image, and was it the
  /// right order of magnitude".
  static String image(String? dataUrl) {
    if (dataUrl == null) return 'none';
    if (dataUrl.isEmpty) return 'empty';
    final comma = dataUrl.indexOf(',');
    final payload = comma >= 0 ? dataUrl.length - comma - 1 : dataUrl.length;
    // base64 carries 3 bytes per 4 characters.
    final bytes = (payload * 3) ~/ 4;
    return '${(bytes / 1024).toStringAsFixed(0)}KB';
  }

  /// Milliseconds since [begin], or a placeholder before it was called.
  static String _elapsed() {
    final started = _startedAt;
    if (started == null) return '    —';
    final ms = DateTime.now().difference(started).inMilliseconds;
    return '${ms.toString().padLeft(5)}ms';
  }

  static String _format(Map<String, Object?>? details) {
    if (details == null || details.isEmpty) return '';
    final parts = details.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${e.value}')
        .join(' ');
    return parts.isEmpty ? '' : '  $parts';
  }
}
