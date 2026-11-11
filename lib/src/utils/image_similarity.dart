/// Catches the user photographing the front of their ID twice.
///
/// The server reads whichever side it is given and reports a `WRONG_SIDE`
/// error, but that costs a round trip and a rate-limited attempt. Comparing
/// the two crops locally refuses the duplicate before the request leaves the
/// device — guide §6.6.3.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Mean absolute RGB difference below which two crops are the same picture.
///
/// The web's value. Low enough that the real back of a card — different text,
/// different layout — clears it comfortably; high enough that re-photographing
/// the same side under slightly different light still reads as a duplicate.
const double kSameImageThreshold = 20;

/// Both images reduced to this before comparing, so the test is about layout
/// and tone rather than pixels the camera never reproduces twice.
const int kComparisonSize = 32;

/// Mean absolute RGB difference between two JPEGs, 0–255.
///
/// Returns null when either image cannot be read — the caller then lets the
/// request through rather than blocking a capture on a failed comparison.
double? meanAbsoluteImageDifference(Uint8List a, Uint8List b) {
  final left = _normalise(a);
  final right = _normalise(b);
  if (left == null || right == null) return null;

  var total = 0;
  for (var y = 0; y < kComparisonSize; y++) {
    for (var x = 0; x < kComparisonSize; x++) {
      final p = left.getPixel(x, y);
      final q = right.getPixel(x, y);
      total +=
          (p.r.toInt() - q.r.toInt()).abs() +
          (p.g.toInt() - q.g.toInt()).abs() +
          (p.b.toInt() - q.b.toInt()).abs();
    }
  }

  // Three channels per pixel.
  return total / (kComparisonSize * kComparisonSize * 3);
}

/// Whether [back] looks like the same picture as [front].
///
/// False when either image is unreadable: a comparison that could not be made
/// must not stand in the user's way.
bool looksLikeSameImage(
  Uint8List front,
  Uint8List back, {
  double threshold = kSameImageThreshold,
}) {
  final difference = meanAbsoluteImageDifference(front, back);
  if (difference == null) return false;
  return difference < threshold;
}

/// The two crops, as one argument so the comparison can cross into an
/// isolate — `compute` takes a single value.
class CapturePair {
  const CapturePair({required this.front, required this.back});

  final Uint8List front;
  final Uint8List back;
}

/// Entry point for `compute`: top-level, so it can be sent to an isolate.
bool compareCaptures(CapturePair pair) =>
    looksLikeSameImage(pair.front, pair.back);

img.Image? _normalise(Uint8List bytes) {
  // decodeImage throws on truncated or foreign bytes rather than answering
  // null, and this runs in an isolate where an escaping error is far from the
  // code that can decide what to do about it.
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;

  return img.copyResize(
    decoded,
    width: kComparisonSize,
    height: kComparisonSize,
  );
}
