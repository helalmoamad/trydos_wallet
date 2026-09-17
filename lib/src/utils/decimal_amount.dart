/// Exact decimal arithmetic for money, backed by [BigInt].
///
/// The merchant-payment API sends every amount as a decimal **string** —
/// `"100.00"` for currencies, six fraction digits for metals. Those strings
/// must never pass through a `double`: `0.1 + 0.2` is not `0.3` in binary
/// floating point, and a wallet that renders a rounded amount on a payment
/// confirmation screen is showing the user a different number than the one it
/// is about to debit.
///
/// The rule this class enforces:
///
/// * **Display** the string the server sent, untouched — see [raw].
/// * **Compare or add** only through [DecimalAmount], never through `double`.
///
/// ```dart
/// final price = DecimalAmount.tryParse(lookup.amount);      // "100.00"
/// final balance = DecimalAmount.fromDouble(wallet.available);
/// if (price != null && balance.compareTo(price) < 0) {
///   // insufficient balance — say so before the user taps pay
/// }
/// ```
class DecimalAmount implements Comparable<DecimalAmount> {
  const DecimalAmount._(this._units, this._scale, this.raw);

  /// Unscaled value: the digits with the decimal point removed.
  final BigInt _units;

  /// Number of fraction digits, i.e. the value is `_units / 10^_scale`.
  final int _scale;

  /// The text this amount was parsed from. Render this, not a reformatted
  /// version — the server decides how many fraction digits an asset shows.
  final String raw;

  static final DecimalAmount zero = DecimalAmount._(BigInt.zero, 0, '0');

  /// Strict decimal parser: optional sign, digits, optional `.` and digits.
  ///
  /// Returns null for anything else — including the empty string, grouped
  /// thousands (`1,000.00`) and exponent notation — rather than guessing at a
  /// number a payment screen would then display.
  static DecimalAmount? tryParse(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^[+-]?\d+(\.\d+)?$').hasMatch(text)) return null;

    final negative = text.startsWith('-');
    final unsigned = (negative || text.startsWith('+'))
        ? text.substring(1)
        : text;

    final dotIndex = unsigned.indexOf('.');
    final digits = dotIndex < 0
        ? unsigned
        : unsigned.substring(0, dotIndex) + unsigned.substring(dotIndex + 1);
    final scale = dotIndex < 0 ? 0 : unsigned.length - dotIndex - 1;

    final units = BigInt.parse(digits);
    return DecimalAmount._(negative ? -units : units, scale, text);
  }

  /// Bridge for values this library still holds as `double` — wallet balances
  /// parsed from an older endpoint. Amounts that arrive as strings must go
  /// through [tryParse] instead: converting them here would reintroduce
  /// exactly the rounding this class exists to avoid.
  factory DecimalAmount.fromDouble(double value, {int scale = 8}) {
    final text = value.toStringAsFixed(scale);
    return tryParse(text) ?? zero;
  }

  bool get isZero => _units == BigInt.zero;
  bool get isNegative => _units.isNegative;
  bool get isPositive => _units > BigInt.zero;

  /// Rescales [a] and [b] to a common scale so their units can be compared or
  /// added directly.
  static (BigInt, BigInt, int) _align(DecimalAmount a, DecimalAmount b) {
    final scale = a._scale > b._scale ? a._scale : b._scale;
    final aUnits = a._units * BigInt.from(10).pow(scale - a._scale);
    final bUnits = b._units * BigInt.from(10).pow(scale - b._scale);
    return (aUnits, bUnits, scale);
  }

  @override
  int compareTo(DecimalAmount other) {
    final (a, b, _) = _align(this, other);
    return a.compareTo(b);
  }

  bool operator <(DecimalAmount other) => compareTo(other) < 0;
  bool operator <=(DecimalAmount other) => compareTo(other) <= 0;
  bool operator >(DecimalAmount other) => compareTo(other) > 0;
  bool operator >=(DecimalAmount other) => compareTo(other) >= 0;

  DecimalAmount operator +(DecimalAmount other) {
    final (a, b, scale) = _align(this, other);
    return _fromUnits(a + b, scale);
  }

  DecimalAmount operator -(DecimalAmount other) {
    final (a, b, scale) = _align(this, other);
    return _fromUnits(a - b, scale);
  }

  static DecimalAmount _fromUnits(BigInt units, int scale) {
    return DecimalAmount._(units, scale, _render(units, scale));
  }

  static String _render(BigInt units, int scale) {
    final negative = units.isNegative;
    var digits = units.abs().toString();
    if (scale == 0) return negative ? '-$digits' : digits;

    digits = digits.padLeft(scale + 1, '0');
    final whole = digits.substring(0, digits.length - scale);
    final fraction = digits.substring(digits.length - scale);
    return '${negative ? '-' : ''}$whole.$fraction';
  }

  @override
  bool operator ==(Object other) =>
      other is DecimalAmount && compareTo(other) == 0;

  @override
  int get hashCode {
    // Equality ignores trailing zeros ("1.50" == "1.5"), so the hash has to as
    // well: strip them before hashing the unscaled value.
    var units = _units;
    var scale = _scale;
    final ten = BigInt.from(10);
    while (scale > 0 && units != BigInt.zero && units % ten == BigInt.zero) {
      units = units ~/ ten;
      scale--;
    }
    if (units == BigInt.zero) scale = 0;
    return Object.hash(units, scale);
  }

  @override
  String toString() => raw;
}
