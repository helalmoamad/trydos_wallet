import 'package:flutter/material.dart';

/// Dims everything outside the detected document and draws a frame on its
/// edges.
///
/// Two jobs in one pass, because they share a rectangle: the scrim tells the
/// user which part of the picture is being read, and the frame shows that the
/// card has actually been found rather than merely photographed. Without the
/// dimming a detected card looks the same as an undetected one.
///
/// [bounds] is in [sourceSize]'s coordinate space — the detector's, not the
/// widget's — and is mapped with the preview's own "cover" transform. Null
/// bounds fall back to a resting frame in the middle, so the overlay never
/// blinks out between detections.
class DocumentLockOverlay extends StatelessWidget {
  const DocumentLockOverlay({
    super.key,
    required this.bounds,
    required this.sourceSize,
    required this.color,
    this.locked = false,
    this.scrimOpacity = 0.45,
    this.mirror = false,
  });

  /// The document's rectangle, as the detector reported it.
  final Rect? bounds;

  /// Size of the analysed frame, for mapping [bounds] onto the widget.
  final Size sourceSize;

  /// Frame colour — the screen drives it from its own state.
  final Color color;

  /// Thickens the frame once the card is held steady enough to capture.
  final bool locked;

  /// How dark the area outside the document goes. Deliberately partial: the
  /// user still needs to see what is around the card to line it up.
  final double scrimOpacity;

  /// Front-camera previews are mirrored; ID capture uses the back camera, so
  /// this is normally false.
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          // Resolved here rather than in the painter so the rectangle can be
          // tweened: the frame glides from the full preview onto the card and
          // follows it, instead of snapping between detections.
          final target = _resolveWindow(size);
          return TweenAnimationBuilder<Rect?>(
            tween: RectTween(end: target),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => CustomPaint(
              painter: _DocumentLockPainter(
                window: animated ?? target,
                color: color,
                locked: locked,
                scrimOpacity: scrimOpacity,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }

  /// The document's rectangle in widget coordinates.
  ///
  /// With nothing detected the window is the whole preview: the frame starts
  /// as the camera's own edge and narrows onto the card once one is found,
  /// rather than appearing out of nowhere at some arbitrary card shape.
  Rect _resolveWindow(Size size) {
    final detected = bounds;
    if (detected == null ||
        sourceSize.width <= 0 ||
        sourceSize.height <= 0 ||
        detected.isEmpty) {
      return Offset.zero & size;
    }

    // Same "cover" transform the preview uses: scale by the larger ratio and
    // centre the overflow. Anything else leaves the frame drifting off the
    // card as the preview is cropped differently from the analysed image.
    final scale = _max(
      size.width / sourceSize.width,
      size.height / sourceSize.height,
    );
    final dx = (size.width - sourceSize.width * scale) / 2;
    final dy = (size.height - sourceSize.height * scale) / 2;

    var left = detected.left * scale + dx;
    var right = detected.right * scale + dx;
    final top = detected.top * scale + dy;
    final bottom = detected.bottom * scale + dy;

    if (mirror) {
      final mirroredLeft = size.width - right;
      final mirroredRight = size.width - left;
      left = mirroredLeft;
      right = mirroredRight;
    }

    // Clamped to the widget: a card half out of frame would otherwise punch
    // the scrim open past the preview's rounded corners.
    return Rect.fromLTRB(
      left.clamp(0.0, size.width),
      top.clamp(0.0, size.height),
      right.clamp(0.0, size.width),
      bottom.clamp(0.0, size.height),
    );
  }

  static double _max(double a, double b) => a > b ? a : b;
}

class _DocumentLockPainter extends CustomPainter {
  _DocumentLockPainter({
    required this.window,
    required this.color,
    required this.locked,
    required this.scrimOpacity,
  });

  /// Already in widget coordinates and already tweened.
  final Rect window;
  final Color color;
  final bool locked;
  final double scrimOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || window.isEmpty) return;

    final rounded = RRect.fromRectAndRadius(window, const Radius.circular(12));

    // Scrim with the document punched out of it. One path rather than two
    // draws: two would leave a seam where they meet.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rounded),
      ),
      Paint()..color = Colors.black.withValues(alpha: scrimOpacity),
    );

    // Hairline: the frame marks the edge, it is not the subject. Anything
    // heavier competes with the card it is drawn around.
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = locked ? 1.4 : 0.9
        ..color = color.withValues(alpha: locked ? 0.95 : 0.7)
        ..isAntiAlias = true,
    );

    _drawCorners(canvas);
  }

  /// Short strokes at each corner, so the frame reads as a viewfinder rather
  /// than a plain box.
  void _drawCorners(Canvas canvas) {
    final arm = (window.shortestSide * 0.12).clamp(8.0, 26.0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = locked ? 2.2 : 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(window.left, window.top + arm)
      ..lineTo(window.left, window.top)
      ..lineTo(window.left + arm, window.top)
      ..moveTo(window.right - arm, window.top)
      ..lineTo(window.right, window.top)
      ..lineTo(window.right, window.top + arm)
      ..moveTo(window.right, window.bottom - arm)
      ..lineTo(window.right, window.bottom)
      ..lineTo(window.right - arm, window.bottom)
      ..moveTo(window.left + arm, window.bottom)
      ..lineTo(window.left, window.bottom)
      ..lineTo(window.left, window.bottom - arm);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DocumentLockPainter oldDelegate) =>
      oldDelegate.window != window ||
      oldDelegate.color != color ||
      oldDelegate.locked != locked ||
      oldDelegate.scrimOpacity != scrimOpacity;
}
