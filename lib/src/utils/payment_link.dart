import 'payment_code.dart';

/// Extracts a payment code from a link.
///
/// The backend can build payment links shaped `<base>/r/v1/<requestCode>`.
/// **No page serves that path yet** — the decision of who builds it, and on
/// which domain, is still open — so today the backend returns no link and shops
/// show the 10-digit code instead.
///
/// Until that page exists, shops must not print QR codes containing a link: the
/// only safe QR content is the code itself, scanned by this app. What lives
/// here is the other half, ready for the day the page ships — the parsing that
/// turns an incoming universal link, app link or custom-scheme URL into a code
/// this app can resolve.
///
/// ```dart
/// final code = PaymentLink.extractCode(incomingUri);
/// if (code != null) {
///   // hand it to the same resolve endpoint every scan goes through
/// }
/// ```
abstract class PaymentLink {
  PaymentLink._();

  /// The path segments that precede a request code in a payment link.
  static const List<String> pathPrefix = ['r', 'v1'];

  /// Pulls the request code out of [uri], or returns null when the link is not
  /// a payment link or carries nothing resolvable.
  ///
  /// Accepts three shapes:
  /// * `https://<host>/r/v1/<code>` — the universal / app link.
  /// * `<scheme>://r/v1/<code>` — the custom-scheme fallback, where the `r` is
  ///   the host rather than a path segment.
  /// * `<scheme>://pay?code=<code>` — a query parameter, for hosts that prefer
  ///   it.
  ///
  /// The extracted code is normalized and validated against the known
  /// namespaces, so a link carrying junk is rejected here rather than costing
  /// one of the ten lookups the throttle allows per fifteen minutes.
  static String? extractCode(Uri? uri) {
    if (uri == null) return null;

    // The parameter name is not settled, because the hosted payment page that
    // would produce these links does not exist yet. These are the spellings the
    // store's own checkout response uses for the same two values
    // (`request_code`, `short_code`), plus the obvious variants. A name we
    // guessed wrong costs nothing: the value still has to pass [_validated].
    final fromQuery = _firstNonEmpty([
      uri.queryParameters['code'],
      uri.queryParameters['requestCode'],
      uri.queryParameters['request_code'],
      uri.queryParameters['shortCode'],
      uri.queryParameters['short_code'],
      uri.queryParameters['paymentCode'],
      uri.queryParameters['payment_code'],
    ]);
    if (fromQuery != null) return _validated(fromQuery);

    // Treat the host as a leading segment so the custom-scheme form, where
    // `r` lands in the host, parses the same way as the https form.
    final segments = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ].where((segment) => segment.isNotEmpty).toList();

    for (var i = 0; i + pathPrefix.length < segments.length; i++) {
      final matchesPrefix = List.generate(
        pathPrefix.length,
        (offset) =>
            segments[i + offset].toLowerCase() == pathPrefix[offset],
      ).every((matched) => matched);

      if (matchesPrefix) {
        return _validated(segments[i + pathPrefix.length]);
      }
    }

    // A bare link whose last segment is itself a code, e.g. a shortened URL.
    if (segments.isNotEmpty) {
      return _validated(segments.last);
    }

    return null;
  }

  /// Convenience wrapper for a link that arrives as a string.
  static String? extractCodeFromString(String? link) {
    final raw = link?.trim() ?? '';
    if (raw.isEmpty) return null;
    return extractCode(Uri.tryParse(raw));
  }

  static String? _validated(String? candidate) {
    final code = PaymentCode.normalize(candidate);
    return PaymentCode.isResolvable(code) ? code : null;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }
}
