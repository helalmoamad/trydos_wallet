import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/utils/amount_input_formatter.dart';

void main() {
  const formatter = AmountInputFormatter();

  /// Applies the formatter as if [text] had just been typed or pasted whole,
  /// with the caret at the end.
  String format(String text, {String previous = ''}) {
    return formatter
        .formatEditUpdate(
          TextEditingValue(
            text: previous,
            selection: TextSelection.collapsed(offset: previous.length),
          ),
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        )
        .text;
  }

  test('يسمح بخانتين عشريتين على الأكثر', () {
    expect(format('12'), '12');
    expect(format('12.'), '12.');
    expect(format('12.3'), '12.3');
    expect(format('12.34'), '12.34');
    expect(format('12.345'), '12.34');
    expect(format('12.3456789'), '12.34');
  });

  test('يقبل فاصلة عشرية واحدة فقط', () {
    expect(format('1.2.3'), '1.23');
    expect(format('1..2'), '1.2');
  });

  test('يحوّل الفاصلة والفاصلة العربية إلى نقطة', () {
    expect(format('12,34'), '12.34');
    expect(format('12٫34'), '12.34');
    expect(format('12,345'), '12.34');
  });

  test('يرفض فاصلة عشرية بلا رقم قبلها', () {
    expect(format('.5'), '5');
    expect(format(','), '');
  });

  test('يحذف الحروف والرموز', () {
    expect(format('12a3'), '123');
    expect(format('1 000'), '1000');
    expect(format('-12.34'), '12.34');
  });

  test('الحقل الفارغ يبقى فارغاً', () {
    expect(format(''), '');
  });

  test('الناتج دائماً قابل للتحليل كرقم', () {
    for (final input in ['12.345', '1.2.3', '12,34', '000.99', '9']) {
      final result = format(input);
      expect(
        double.tryParse(result),
        isNotNull,
        reason: '"$input" أنتج "$result" وهو غير قابل للتحليل',
      );
    }
  });

  test('المؤشر يتبع النص بعد حذف محرف', () {
    // "12.345" typed with the caret after the rejected '5'.
    final result = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '12.34',
        selection: TextSelection.collapsed(offset: 5),
      ),
      const TextEditingValue(
        text: '12.345',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    expect(result.text, '12.34');
    expect(result.selection.baseOffset, 5);
  });

  test('عدد الخانات قابل للضبط', () {
    const strict = AmountInputFormatter(decimalPlaces: 0);
    final result = strict.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '12.34',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    expect(result.text, '1234');
  });
}
