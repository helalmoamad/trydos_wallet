import 'package:flutter/material.dart';

/// ثوابت الأنماط والخطوط لمكتبة المحفظة.
class TrydosWalletStyles {
  /// اسم عائلة الخط كما هو معرف في pubspec.yaml الخاص بالمكتبة.
  static const String fontFamily = 'Quicksand';

  /// اسم المكتبة لاستخدامه عند استدعاء الأصول من تطبيقات أخرى.
  static const String packageName = 'trydos_wallet';

  /// النمط الأساسي للنصوص مع تحديد اسم الخط والمكتبة.
  static TextStyle get baseTextStyle =>
      const TextStyle(fontFamily: fontFamily, package: packageName);

  /// نمط العناوين الكبيرة.
  static TextStyle get headlineLarge =>
      baseTextStyle.copyWith(fontSize: 32, fontWeight: FontWeight.bold);

  /// نمط العناوين المتوسطة.
  static TextStyle get headlineMedium =>
      baseTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w600);

  /// نمط النصوص العادية.
  static TextStyle get bodyLarge =>
      baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.normal);

  /// نمط النصوص المتوسطة.
  static TextStyle get bodyMedium =>
      baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.normal);

  /// نمط النصوص الصغيرة جداً (للتواريخ والحالات).
  static TextStyle get bodySmall =>
      baseTextStyle.copyWith(fontSize: 10, fontWeight: FontWeight.normal);

  /// نمط المبالغ المالية.
  static TextStyle get amountText =>
      baseTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold);
}
