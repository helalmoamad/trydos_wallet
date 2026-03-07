import 'package:flutter/material.dart';

/// Helper class for managing responsive padding and margins based on text direction
class ResponsivePadding {
  /// Create padding that respects RTL/LTR
  static EdgeInsets symmetric({
    required double horizontal,
    required double vertical,
  }) {
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Create padding based on text direction
  /// For RTL: swaps left/right values
  static EdgeInsets directional({
    required double start,
    required double end,
    required double top,
    required double bottom,
    required bool isRtl,
  }) {
    if (isRtl) {
      // Swap start and end for RTL
      return EdgeInsets.fromLTRB(end, top, start, bottom);
    }
    return EdgeInsets.fromLTRB(start, top, end, bottom);
  }

  /// Create only start/end padding
  static EdgeInsets horizontal({
    required double start,
    required double end,
    required bool isRtl,
  }) {
    if (isRtl) {
      return EdgeInsets.fromLTRB(end, 0, start, 0);
    }
    return EdgeInsets.fromLTRB(start, 0, end, 0);
  }

  /// Create only top/bottom padding
  static EdgeInsets vertical({required double top, required double bottom}) {
    return EdgeInsets.fromLTRB(0, top, 0, bottom);
  }

  /// Only start padding
  static EdgeInsets only({
    double start = 0,
    double end = 0,
    double top = 0,
    double bottom = 0,
    required bool isRtl,
  }) {
    if (isRtl) {
      return EdgeInsets.fromLTRB(end, top, start, bottom);
    }
    return EdgeInsets.fromLTRB(start, top, end, bottom);
  }
}

/// Helper for managing alignment based on text direction
class ResponsiveAlignment {
  static AlignmentGeometry get startCenter {
    return Alignment.centerLeft;
  }

  static AlignmentGeometry get endCenter {
    return Alignment.centerRight;
  }

  static AlignmentGeometry horizontal(bool isRtl) {
    return isRtl ? Alignment.centerRight : Alignment.centerLeft;
  }

  static CrossAxisAlignment crossAxisAlignment(bool isRtl) {
    return isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  }
}
