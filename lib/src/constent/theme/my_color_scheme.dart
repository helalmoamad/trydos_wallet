import 'package:flutter/material.dart';

extension MyColorScheme on ColorScheme {
  static const MaterialColor _grey = MaterialColor(
    _primaryGreyValue,
    <int, Color>{
      50: Color(0xffF8F8F8),
      100: Color(0xffDBDBDB),
      200: Color(0xff8D8D8D),
      300: Color(0xff989898),
      400: Color(_primaryGreyValue),
      500: Color(0xff707070),
      600: Color(0xff383838),
      700: Color(0xFFBFBFBF),
      800: Color(0xff848484),
    },
  );

  static const int _primaryGreyValue = 0xff585858;

  //static const int _blackPrimaryValue = 0xff1f6e1a;

  static const MaterialColor _hint = MaterialColor(
    _primaryHintValue,
    <int, Color>{
      100: Color(0xffF2F3F3),
    },
  );

  static const int _primaryHintValue = 0xffADADAD;

  static const MaterialColor _drawer = MaterialColor(
    _primaryDrawerValue,
    <int, Color>{},
  );

  static const int _primaryDrawerValue = 0xff2A2E43;

  static const MaterialColor _white = MaterialColor(
    _primaryWhiteValue,
    <int, Color>{},
  );

  static const int _primaryWhiteValue = 0xffFEFEFE;

  MaterialColor get hint => brightness == Brightness.light ? _hint : _hint;

  Color get borderTextField => const Color(0xFFC7C7C7);
  Color get borderColor => const Color(0xff5D5D5D);

  Color get grey50 => _grey.shade50;

  Color get grey200 =>
      brightness == Brightness.light ? _grey.shade200 : _grey.shade200;

  Color get grey300 =>
      brightness == Brightness.light ? _grey.shade300 : _grey.shade300;

  Color get grey =>
      brightness == Brightness.light ? _grey.shade400 : _grey.shade400;

  Color get grey500 =>
      brightness == Brightness.light ? _grey.shade500 : _grey.shade500;

  Color get grey600 =>
      brightness == Brightness.light ? _grey.shade600 : _grey.shade600;

  Color get drawer => brightness == Brightness.light ? _drawer : _drawer;

  Color get white => brightness == Brightness.light ? _white : _white;

  Color get grey700 =>
      brightness == Brightness.light ? _grey.shade700 : _grey.shade700;
  Color get grey800 =>
      brightness == Brightness.light ? _grey.shade700 : _grey.shade700;

  Color get dividerColor => const Color(0xffDFDFDF);

  Color get black => const Color(0xff000000);

  Color get blue => const Color(0xff0080FF);
}

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}
