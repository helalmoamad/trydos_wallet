import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Why the light gate is holding the challenge back.
enum FaceLightVerdict {
  /// Good enough to start.
  ok,

  /// Bright enough overall but the face itself is dark — the user is in front
  /// of a window. Checked before [tooDark] because the fix is different:
  /// turn around, not find more light.
  backlit,

  tooBright,
  tooDark,
  tooBlurry,
}

/// Measures one JPEG frame for [FaceLightGate].
///
/// Top-level and self-contained so it can run through `compute` — the work is
/// a decode plus two passes over a small bitmap, which is enough to stutter
/// the camera preview if done on the UI thread, and it runs every 150 ms.
///
/// Returns null for anything undecodable; the caller waives the gate rather
/// than failing a user whose camera simply would not give a reading.
FaceLightSample? measureFaceLight(Uint8List jpeg) {
  // decodeImage throws on truncated or foreign bytes rather than answering
  // null, and this runs in an isolate where an escaping error is far from the
  // code that can decide what to do about it. Undecodable means "no reading",
  // which the caller already handles.
  img.Image? decoded;
  try {
    decoded = img.decodeImage(jpeg);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;

  // 96 px wide, as the web uses: enough for luminance and a coarse Sobel,
  // cheap enough to repeat several times a second.
  final small = decoded.width > _sampleWidth
      ? img.copyResize(decoded, width: _sampleWidth)
      : decoded;

  final width = small.width;
  final height = small.height;
  if (width < 3 || height < 3) return null;

  // The centre 50% box is where a face sits inside the guide oval.
  final left = width ~/ 4;
  final top = height ~/ 4;
  final right = width - left;
  final bottom = height - top;

  double frameSum = 0;
  var frameCount = 0;
  final centre = <double>[];

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = small.getPixel(x, y);
      final luma =
          0.299 * pixel.r.toDouble() +
          0.587 * pixel.g.toDouble() +
          0.114 * pixel.b.toDouble();
      frameSum += luma;
      frameCount++;
      if (x >= left && x < right && y >= top && y < bottom) {
        centre.add(luma);
      }
    }
  }

  if (frameCount == 0 || centre.isEmpty) return null;

  final centreWidth = right - left;
  final centreHeight = bottom - top;
  final centreMean = centre.reduce((a, b) => a + b) / centre.length;

  // Sobel-magnitude variance over the centre box — the same "is this in
  // focus" proxy the web uses.
  double gradSum = 0;
  double gradSquareSum = 0;
  var gradCount = 0;

  double at(int x, int y) => centre[y * centreWidth + x];

  for (var y = 1; y < centreHeight - 1; y++) {
    for (var x = 1; x < centreWidth - 1; x++) {
      final gx =
          -at(x - 1, y - 1) -
          2 * at(x - 1, y) -
          at(x - 1, y + 1) +
          at(x + 1, y - 1) +
          2 * at(x + 1, y) +
          at(x + 1, y + 1);
      final gy =
          -at(x - 1, y - 1) -
          2 * at(x, y - 1) -
          at(x + 1, y - 1) +
          at(x - 1, y + 1) +
          2 * at(x, y + 1) +
          at(x + 1, y + 1);
      final magnitude = gx.abs() + gy.abs();
      gradSum += magnitude;
      gradSquareSum += magnitude * magnitude;
      gradCount++;
    }
  }

  final sharpness = gradCount == 0
      ? 0.0
      : (gradSquareSum / gradCount) -
            (gradSum / gradCount) * (gradSum / gradCount);

  return FaceLightSample(
    centreLuminance: centreMean,
    frameLuminance: frameSum / frameCount,
    sharpness: sharpness < 0 ? 0 : sharpness,
  );
}

const int _sampleWidth = 96;

/// Measures a luma plane straight off the camera stream.
///
/// The stream is already running to track the face, so reading the light from
/// the same frames costs nothing — where capturing a JPEG every 150 ms would
/// fight the stream for the camera and stutter the preview.
///
/// [luma] is one byte per pixel: the Y plane of an NV21 frame on Android, or
/// a greyscale pass over BGRA on iOS. Returns null when the buffer does not
/// describe the stated size.
FaceLightSample? measureLumaPlane({
  required Uint8List luma,
  required int width,
  required int height,
  int bytesPerRow = 0,
}) {
  final stride = bytesPerRow > 0 ? bytesPerRow : width;
  if (width < 8 || height < 8 || luma.length < stride * height) return null;

  // Step over the frame rather than reading every pixel: this runs per frame,
  // and ~96 columns is as much as the measurement needs.
  final step = (width / _sampleWidth).ceil().clamp(1, 16);

  final left = width ~/ 4;
  final top = height ~/ 4;
  final right = width - left;
  final bottom = height - top;

  var frameSum = 0;
  var frameCount = 0;
  var centreSum = 0;
  var centreCount = 0;

  // Sobel needs neighbours, so the centre box is also kept as a small grid.
  final centreRow = <int>[];
  var previousRow = <int>[];
  var gradSum = 0.0;
  var gradSquareSum = 0.0;
  var gradCount = 0;

  for (var y = 0; y < height; y += step) {
    centreRow.clear();
    for (var x = 0; x < width; x += step) {
      final value = luma[y * stride + x];
      frameSum += value;
      frameCount++;
      if (x >= left && x < right && y >= top && y < bottom) {
        centreSum += value;
        centreCount++;
        centreRow.add(value);
      }
    }

    // Vertical and horizontal differences against the row above: a cheap
    // stand-in for the full Sobel, and enough to separate focus from blur.
    if (previousRow.length == centreRow.length && centreRow.length > 1) {
      for (var i = 1; i < centreRow.length; i++) {
        final magnitude =
            (centreRow[i] - centreRow[i - 1]).abs() +
            (centreRow[i] - previousRow[i]).abs();
        gradSum += magnitude;
        gradSquareSum += magnitude * magnitude;
        gradCount++;
      }
    }
    previousRow = List<int>.of(centreRow);
  }

  if (frameCount == 0 || centreCount == 0) return null;

  final mean = gradCount == 0 ? 0.0 : gradSum / gradCount;
  final sharpness = gradCount == 0
      ? 0.0
      : (gradSquareSum / gradCount) - mean * mean;

  return FaceLightSample(
    centreLuminance: centreSum / centreCount,
    frameLuminance: frameSum / frameCount,
    sharpness: sharpness < 0 ? 0 : sharpness,
  );
}

/// One frame's measurements, as read from a 96-px-wide downsample.
class FaceLightSample {
  const FaceLightSample({
    required this.centreLuminance,
    required this.frameLuminance,
    required this.sharpness,
  });

  /// Mean luma of the centre 50% box, 0–255 — where the face is.
  final double centreLuminance;

  /// Mean luma of the whole frame, 0–255.
  final double frameLuminance;

  /// Sobel-magnitude variance of the centre box.
  final double sharpness;
}

/// The pre-check the web runs before opening an AWS Face Liveness session.
///
/// It is not a liveness test and judges nobody: a face in bad light fails the
/// real challenge, and each failed challenge costs a billed AWS session, so
/// this turns a likely failure into an instruction before anything is spent.
///
/// Thresholds are the web's, from the guide §7.3 / §13.
class FaceLightGate {
  FaceLightGate({
    this.minCentreLuminance = 55,
    this.maxCentreLuminance = 215,
    this.minSharpness = 8,
    this.backlitRatio = 1.6,
    this.stableFor = const Duration(milliseconds: 700),
  });

  final double minCentreLuminance;
  final double maxCentreLuminance;
  final double minSharpness;

  /// frameLuminance / centreLuminance at or above this, with a dark centre,
  /// reads as a bright background behind a shadowed face.
  final double backlitRatio;

  /// How long the readings must stay good before the gate opens.
  final Duration stableFor;

  DateTime? _goodSince;
  FaceLightVerdict _verdict = FaceLightVerdict.tooDark;

  /// The latest reason, for the status line.
  FaceLightVerdict get verdict => _verdict;

  /// Judges one frame. Returns true once the readings have been good
  /// continuously for [stableFor] — a single good frame is not enough, or the
  /// gate opens on one lucky moment between two bad ones.
  bool accept(FaceLightSample sample, {DateTime? now}) {
    final at = now ?? DateTime.now();
    _verdict = _judge(sample);

    if (_verdict != FaceLightVerdict.ok) {
      _goodSince = null;
      return false;
    }

    _goodSince ??= at;
    return !at.isBefore(_goodSince!.add(stableFor));
  }

  /// Forgets the run of good frames — call when the camera restarts or the
  /// screen is left, so a stale streak cannot open the gate on return.
  void reset() {
    _goodSince = null;
    _verdict = FaceLightVerdict.tooDark;
  }

  FaceLightVerdict _judge(FaceLightSample sample) {
    if (sample.centreLuminance > maxCentreLuminance) {
      return FaceLightVerdict.tooBright;
    }
    if (sample.centreLuminance < minCentreLuminance) {
      // A dark face under a bright frame is backlighting, not a dark room.
      final ratio = sample.centreLuminance <= 0
          ? double.infinity
          : sample.frameLuminance / sample.centreLuminance;
      return ratio >= backlitRatio
          ? FaceLightVerdict.backlit
          : FaceLightVerdict.tooDark;
    }
    if (sample.sharpness < minSharpness) {
      return FaceLightVerdict.tooBlurry;
    }
    return FaceLightVerdict.ok;
  }
}
