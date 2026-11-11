/// §6.6.3 — refusing the front of the ID photographed twice.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
// ignore: implementation_imports
import 'package:trydos_wallet/src/utils/image_similarity.dart';

void main() {
  /// A card-ish image: a background with a block of "text" rows, so two
  /// different sides differ in layout the way real crops do.
  Uint8List card({
    required int background,
    required int ink,
    int rows = 6,
    int quality = 92,
  }) {
    final image = img.Image(width: 300, height: 190);
    img.fill(image, color: img.ColorRgb8(background, background, background));
    for (var r = 0; r < rows; r++) {
      final y = 30 + r * 22;
      for (var x = 20; x < 280; x++) {
        for (var dy = 0; dy < 8; dy++) {
          image.setPixelRgb(x, y + dy, ink, ink, ink);
        }
      }
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  test('الصورة نفسها = فرق صفري', () {
    final bytes = card(background: 230, ink: 40);
    expect(meanAbsoluteImageDifference(bytes, bytes), 0);
    expect(looksLikeSameImage(bytes, bytes), isTrue);
  });

  test('إعادة تصوير الوجه نفسه بإضاءة مختلفة قليلاً تبقى تكراراً', () {
    // Same layout, slightly different exposure and compression — what a
    // second shot of the same side actually looks like.
    final first = card(background: 230, ink: 40);
    final second = card(background: 222, ink: 48, quality: 85);
    final difference = meanAbsoluteImageDifference(first, second);
    expect(difference, isNotNull);
    expect(difference, lessThan(kSameImageThreshold));
    expect(looksLikeSameImage(first, second), isTrue);
  });

  test('ظهر حقيقي مختلف التخطيط يمر', () {
    final front = card(background: 230, ink: 40, rows: 6);
    final back = card(background: 60, ink: 235, rows: 2);
    final difference = meanAbsoluteImageDifference(front, back);
    expect(difference, isNotNull);
    expect(difference, greaterThan(kSameImageThreshold));
    expect(looksLikeSameImage(front, back), isFalse);
  });

  test('العتبة ٢٠ والحجم ٣٢', () {
    // Pinned: both are the web's values and the comparison means nothing
    // without them.
    expect(kSameImageThreshold, 20);
    expect(kComparisonSize, 32);
  });

  test('بايتات تالفة لا توقف الالتقاط', () {
    // A comparison that could not be made must not block the user — the
    // server still has the final word on which side it was shown.
    final good = card(background: 230, ink: 40);
    final bad = Uint8List.fromList([1, 2, 3, 4]);
    expect(meanAbsoluteImageDifference(good, bad), isNull);
    expect(looksLikeSameImage(good, bad), isFalse);
    expect(looksLikeSameImage(bad, good), isFalse);
    expect(looksLikeSameImage(Uint8List(0), Uint8List(0)), isFalse);
  });

  test('compareCaptures هي المدخل عبر العزلة', () {
    final bytes = card(background: 230, ink: 40);
    expect(compareCaptures(CapturePair(front: bytes, back: bytes)), isTrue);

    final other = card(background: 60, ink: 235, rows: 2);
    expect(compareCaptures(CapturePair(front: bytes, back: other)), isFalse);
  });
}
