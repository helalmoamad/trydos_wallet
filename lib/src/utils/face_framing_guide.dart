/// What to tell the user about where their face is.
///
/// One instruction at a time, and the one that actually unblocks them: a user
/// told three things at once follows none of them.
enum FaceFramingHint {
  /// Nothing in frame.
  noFace,

  /// Face found but too small — the mesh would be guesswork and the AWS
  /// challenge is likelier to fail.
  moveCloser,

  /// Filling the frame; the oval cannot contain it.
  moveBack,

  /// Right size, wrong place.
  centreFace,

  /// Framed correctly but still moving.
  holdSteady,

  /// Framed and still — ready to start.
  ready,
}

/// One frame's face geometry, in the preview's own coordinate space.
class FaceFrame {
  const FaceFrame({
    required this.centreX,
    required this.centreY,
    required this.width,
    required this.height,
    required this.frameWidth,
    required this.frameHeight,
  });

  final double centreX;
  final double centreY;
  final double width;
  final double height;
  final double frameWidth;
  final double frameHeight;

  /// How much of the frame's width the face spans, 0–1.
  double get fill => frameWidth <= 0 ? 0 : width / frameWidth;

  /// Distance of the face centre from the frame centre, as a fraction of the
  /// half-frame — 0 is dead centre, 1 is at the edge.
  double get centreOffset {
    if (frameWidth <= 0 || frameHeight <= 0) return 1;
    final dx = (centreX - frameWidth / 2).abs() / (frameWidth / 2);
    final dy = (centreY - frameHeight / 2).abs() / (frameHeight / 2);
    return dx > dy ? dx : dy;
  }
}

/// Decides what the steadying screen says, and when it may start the
/// challenge.
///
/// Separate from the screen so the thresholds can be tested without a camera,
/// and separate from [FaceLightGate] because the two answer different
/// questions: that one is about the room, this one is about the person.
class FaceFramingGuide {
  FaceFramingGuide({
    this.minFill = 0.45,
    this.maxFill = 0.78,
    this.maxCentreOffset = 0.22,
    this.maxDrift = 0.04,
    this.stableFor = const Duration(milliseconds: 900),
  });

  /// Face width as a fraction of frame width. Below [minFill] the contours
  /// are too coarse to draw a mesh from; above [maxFill] the face no longer
  /// fits the oval.
  final double minFill;
  final double maxFill;

  /// How far off centre a face may sit, as a fraction of the half-frame.
  final double maxCentreOffset;

  /// Movement between two readings, as a fraction of frame width, that still
  /// counts as holding still. Covers both drift and size change — leaning in
  /// is movement too.
  final double maxDrift;

  /// How long the face must stay framed and still.
  final Duration stableFor;

  FaceFrame? _previous;
  DateTime? _steadySince;
  FaceFramingHint _hint = FaceFramingHint.noFace;

  FaceFramingHint get hint => _hint;

  /// Progress towards [stableFor], 0–1 — drives the bar under the preview.
  double get progress {
    final since = _steadySince;
    if (since == null || stableFor.inMicroseconds == 0) return 0;
    final held = DateTime.now().difference(since).inMicroseconds;
    final ratio = held / stableFor.inMicroseconds;
    return ratio < 0 ? 0 : (ratio > 1 ? 1 : ratio);
  }

  /// Feeds one reading. Null means no face was found this frame.
  ///
  /// Returns true once the face has been framed and still for [stableFor].
  bool accept(FaceFrame? face, {DateTime? now}) {
    final at = now ?? DateTime.now();

    if (face == null) {
      _reset(FaceFramingHint.noFace);
      return false;
    }

    if (face.fill < minFill) {
      _reset(FaceFramingHint.moveCloser);
      return false;
    }
    if (face.fill > maxFill) {
      _reset(FaceFramingHint.moveBack);
      return false;
    }
    if (face.centreOffset > maxCentreOffset) {
      _reset(FaceFramingHint.centreFace);
      return false;
    }

    // Framed. Now: is it still?
    final previous = _previous;
    _previous = face;
    if (previous == null || _drift(previous, face) > maxDrift) {
      _steadySince = at;
      _hint = FaceFramingHint.holdSteady;
      return false;
    }

    _steadySince ??= at;
    final held = !at.isBefore(_steadySince!.add(stableFor));
    _hint = held ? FaceFramingHint.ready : FaceFramingHint.holdSteady;
    return held;
  }

  /// Forgets the run — call when the camera restarts or the page is left, so
  /// a stale streak cannot start a challenge on return.
  void reset() {
    _previous = null;
    _steadySince = null;
    _hint = FaceFramingHint.noFace;
  }

  void _reset(FaceFramingHint hint) {
    _previous = null;
    _steadySince = null;
    _hint = hint;
  }

  /// Largest of the horizontal, vertical and size changes between two
  /// readings, as a fraction of frame width.
  double _drift(FaceFrame a, FaceFrame b) {
    final frameWidth = b.frameWidth;
    if (frameWidth <= 0) return double.infinity;

    final dx = (a.centreX - b.centreX).abs() / frameWidth;
    final dy = (a.centreY - b.centreY).abs() / frameWidth;
    final dSize = (a.width - b.width).abs() / frameWidth;

    var worst = dx;
    if (dy > worst) worst = dy;
    if (dSize > worst) worst = dSize;
    return worst;
  }
}
