import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The web drawn over the user's face while they steady it.
///
/// Points come from ML Kit's face contours — the oval, brows, eyes, nose and
/// lips — so the web sits on the actual face and follows it: it grows as the
/// user leans in, shifts as they move, and tilts as they turn. Nothing here
/// judges liveness; it is feedback, so the person can see the camera has
/// found them.
///
/// Contours, not a 468-point mesh: that API is Android-only, and the wallet
/// ships both platforms. What matters for the look is that the contours stay
/// *grouped*: the oval is the boundary, and the rest are features woven
/// inside it. Flattening them into one cloud and fanning from the centre
/// produces a starburst spilling past the face, not a mesh.
class FaceMeshOverlay extends StatelessWidget {
  const FaceMeshOverlay({
    super.key,
    required this.contours,
    required this.sourceSize,
    this.color = const Color(0xFFFF8E8E),
    this.mirror = true,
  });

  /// One polyline per contour, in [sourceSize]'s coordinate space. The face
  /// oval first, when the detector found one.
  final List<List<Offset>> contours;

  /// Size of the image the points were detected in — already in the detector's
  /// rotated space. The painter maps them with the same "cover" transform the
  /// preview uses, or the web floats away from the face.
  final Size sourceSize;

  /// Web colour. Green once the challenge has been passed.
  final Color color;

  /// Front-camera previews are mirrored for the user; the detector's points
  /// are not. Flipped here so the two agree.
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FaceMeshPainter(
          contours: contours,
          sourceSize: sourceSize,
          color: color,
          mirror: mirror,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _FaceMeshPainter extends CustomPainter {
  _FaceMeshPainter({
    required this.contours,
    required this.sourceSize,
    required this.color,
    required this.mirror,
  });

  final List<List<Offset>> contours;
  final Size sourceSize;
  final Color color;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    if (contours.isEmpty ||
        sourceSize.width <= 0 ||
        sourceSize.height <= 0 ||
        size.isEmpty) {
      return;
    }

    final mapped = [for (final c in contours) _mapContour(c, size)];
    final outline = mapped.first;
    if (outline.length < 3) return;

    // Everything is clipped to the face oval, so no stroke can stray onto the
    // background however the contours wobble.
    final boundary = Path()..addPolygon(outline, true);
    canvas.save();
    canvas.clipPath(boundary);

    final web = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color.withValues(alpha: 0.5)
      ..isAntiAlias = true;

    _drawWeave(canvas, outline, web);
    _drawFeatureStruts(canvas, outline, mapped.skip(1).toList(), web);

    canvas.restore();

    // The outline and the features themselves, drawn over the weave and not
    // clipped away, so the face reads as traced rather than merely hatched.
    final edges = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = color.withValues(alpha: 0.85)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(boundary, edges);
    for (final feature in mapped.skip(1)) {
      if (feature.length < 2) continue;
      canvas.drawPath(Path()..addPolygon(feature, false), edges);
    }

    final vertices = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.9)
      ..isAntiAlias = true;
    for (final contour in mapped) {
      for (final point in contour) {
        canvas.drawCircle(point, 1.0, vertices);
      }
    }
  }

  /// Chords across the oval, both ways, giving the lattice its diamonds.
  ///
  /// Spokes from one centre would read as a starburst; connecting each rim
  /// point to the ones a quarter and a third of the way round instead lays a
  /// net over the face.
  void _drawWeave(Canvas canvas, List<Offset> outline, Paint paint) {
    final n = outline.length;
    if (n < 8) return;

    final path = Path();
    for (final stride in [n ~/ 3, n ~/ 4]) {
      if (stride < 2) continue;
      for (var i = 0; i < n; i++) {
        final a = outline[i];
        final b = outline[(i + stride) % n];
        path
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  /// Ties each feature to the rim nearest it, so eyes, nose and lips sit in
  /// the net rather than floating on top of it.
  void _drawFeatureStruts(
    Canvas canvas,
    List<Offset> outline,
    List<List<Offset>> features,
    Paint paint,
  ) {
    if (features.isEmpty) return;

    final path = Path();
    for (final feature in features) {
      for (var i = 0; i < feature.length; i += 2) {
        final point = feature[i];
        final nearest = _nearest(outline, point);
        path
          ..moveTo(point.dx, point.dy)
          ..lineTo(nearest.dx, nearest.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  Offset _nearest(List<Offset> candidates, Offset to) {
    var best = candidates.first;
    var bestDistance = double.infinity;
    for (final candidate in candidates) {
      final dx = candidate.dx - to.dx;
      final dy = candidate.dy - to.dy;
      final distance = dx * dx + dy * dy;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = candidate;
      }
    }
    return best;
  }

  /// Maps detector coordinates onto the widget with the preview's own
  /// "cover" transform: scale by the larger ratio, then centre the overflow.
  List<Offset> _mapContour(List<Offset> contour, Size size) {
    final scale = math.max(
      size.width / sourceSize.width,
      size.height / sourceSize.height,
    );
    final dx = (size.width - sourceSize.width * scale) / 2;
    final dy = (size.height - sourceSize.height * scale) / 2;

    return [
      for (final point in contour)
        Offset(
          mirror ? size.width - (point.dx * scale + dx) : point.dx * scale + dx,
          point.dy * scale + dy,
        ),
    ];
  }

  @override
  bool shouldRepaint(_FaceMeshPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.mirror != mirror ||
      oldDelegate.sourceSize != sourceSize ||
      !identical(oldDelegate.contours, contours);
}
