import 'package:flutter/services.dart';

/// Caps typed money entry at [decimalPlaces] fraction digits.
///
/// Every amount in this library is parsed with `double.tryParse`, which needs a
/// plain `123.45`. So the formatter keeps the text parseable as it is typed:
/// digits only, at most one decimal point, and never more than two digits after
/// it. A comma — what the decimal key emits on several locales' numeric
/// keyboards — is accepted and written as a point, so a user whose keyboard
/// gives them `,` can still enter a fractional amount.
///
/// Characters are dropped rather than the whole edit rejected, so pasting
/// `12.3456` leaves `12.34` instead of leaving the field untouched.
class AmountInputFormatter extends TextInputFormatter {
  const AmountInputFormatter({this.decimalPlaces = 2})
    : assert(decimalPlaces >= 0);

  /// Maximum digits allowed after the decimal point.
  final int decimalPlaces;

  static bool _isDigit(String ch) {
    final code = ch.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  /// The separators a numeric keyboard may produce for a decimal point: the
  /// point itself, a comma, and the Arabic decimal separator.
  static bool _isSeparator(String ch) => ch == '.' || ch == ',' || ch == '٫';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final cursor = newValue.selection.end;
    final kept = StringBuffer();
    var hasSeparator = false;
    var fractionDigits = 0;
    var droppedBeforeCursor = 0;

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      var keep = false;

      if (_isDigit(ch)) {
        if (!hasSeparator) {
          keep = true;
        } else if (fractionDigits < decimalPlaces) {
          keep = true;
          fractionDigits++;
        }
      } else if (_isSeparator(ch) &&
          !hasSeparator &&
          decimalPlaces > 0 &&
          // A leading point would leave ".5", which double.tryParse accepts but
          // the library's own DecimalAmount does not. Require a digit first.
          kept.isNotEmpty) {
        hasSeparator = true;
        keep = true;
      }

      if (keep) {
        kept.write(_isSeparator(ch) ? '.' : ch);
      } else if (i < cursor) {
        droppedBeforeCursor++;
      }
    }

    final result = kept.toString();
    if (result == text) {
      return newValue;
    }

    final offset = (cursor - droppedBeforeCursor).clamp(0, result.length);
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
