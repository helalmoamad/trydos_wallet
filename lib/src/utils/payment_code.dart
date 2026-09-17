/// Recognising and cleaning the codes the one scanner accepts.
///
/// A code carries its own namespace, so a single resolve endpoint routes on the
/// string alone:
///
/// | Shape          | Kind                                  |
/// |----------------|---------------------------------------|
/// | `pr.…`         | a peer payment request (another user) |
/// | `mp.…`         | a merchant payment request            |
/// | `4817302956`   | a merchant counter code, 10 digits    |
///
/// The server does the routing and reports it back as `kind`; this class never
/// decides which endpoint to call. What it is for is the two client-side jobs
/// the server cannot do:
///
/// 1. **Trim before sending.** A code read from a QR or typed as
///    `481 730 2956` must reach the API clean, so the user does not burn a
///    lookup attempt on formatting.
/// 2. **Reject a string in no namespace without a lookup.** Wrong codes are
///    rate-limited — 10 failed lookups in 15 minutes returns `429` — so a
///    stray scan of an unrelated QR must not spend one of those attempts.
library;

enum PaymentCodeKind {
  /// `pr.…` — a payment request from another wallet user.
  peer,

  /// `mp.…` — a merchant payment request.
  merchant,

  /// A 10-digit code shown on a merchant's counter.
  merchantCounter,

  /// Not one of ours. Never send this to the lookup endpoint.
  unknown,
}

abstract class PaymentCode {
  PaymentCode._();

  static const String peerPrefix = 'pr.';
  static const String merchantPrefix = 'mp.';

  /// Length of a merchant counter code.
  static const int counterCodeLength = 10;

  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _counterCode = RegExp(r'^\d{10}$');

  /// Strips every space the user or the QR added.
  ///
  /// Inner whitespace goes too: `481 730 2956` is how we ask people to read a
  /// counter code aloud, and it is how they will type it back.
  static String normalize(String? raw) =>
      (raw ?? '').replaceAll(_whitespace, '').trim();

  /// Classifies an already-[normalize]d string.
  static PaymentCodeKind kindOf(String? raw) {
    final code = normalize(raw);
    if (code.isEmpty) return PaymentCodeKind.unknown;

    final lower = code.toLowerCase();
    if (lower.startsWith(peerPrefix) && code.length > peerPrefix.length) {
      return PaymentCodeKind.peer;
    }
    if (lower.startsWith(merchantPrefix) &&
        code.length > merchantPrefix.length) {
      return PaymentCodeKind.merchant;
    }
    if (_counterCode.hasMatch(code)) return PaymentCodeKind.merchantCounter;

    return PaymentCodeKind.unknown;
  }

  /// True when [raw] is worth a lookup call.
  ///
  /// Anything else is refused locally, before it can count against the
  /// wrong-code throttle.
  static bool isResolvable(String? raw) =>
      kindOf(raw) != PaymentCodeKind.unknown;

  /// True when [raw] is a 10-digit counter code, the only shape a user types by
  /// hand.
  static bool isCounterCode(String? raw) =>
      kindOf(raw) == PaymentCodeKind.merchantCounter;

  /// Groups a counter code for display: `4817302956` → `481 730 2956`.
  ///
  /// Anything that is not exactly 10 digits is returned unchanged, so this is
  /// safe to call on any input a field holds mid-typing.
  static String formatCounterCode(String? raw) {
    final code = normalize(raw);
    if (!_counterCode.hasMatch(code)) return code;
    return '${code.substring(0, 3)} ${code.substring(3, 6)} '
        '${code.substring(6)}';
  }

  /// Progressive grouping for a field the user is still typing into: digits are
  /// grouped 3-3-4 as they arrive, and nothing is padded.
  static String formatCounterCodeInput(String? raw) {
    final digits = normalize(raw).replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > counterCodeLength
        ? digits.substring(0, counterCodeLength)
        : digits;
    if (capped.length <= 3) return capped;
    if (capped.length <= 6) {
      return '${capped.substring(0, 3)} ${capped.substring(3)}';
    }
    return '${capped.substring(0, 3)} ${capped.substring(3, 6)} '
        '${capped.substring(6)}';
  }
}
