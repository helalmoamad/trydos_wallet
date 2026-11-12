import 'package:flutter/material.dart';

/// A soft blue line sweeping down a frozen capture while the server reads it.
///
/// The freeze alone looks like the app has hung; the sweep says the picture
/// was taken and is being worked on. It is pure feedback — it tracks nothing
/// and reports no progress, because the request's duration is unknown and a
/// bar that stalled at 80% would lie.
///
/// Travels the full height and spans [widthFactor] of the width, so it reads
/// as passing over the card rather than over the whole viewfinder.
class ScanningLine extends StatefulWidget {
  const ScanningLine({
    super.key,
    this.color = const Color(0xff388CFF),
    this.period = const Duration(milliseconds: 1400),
    this.widthFactor = 0.86,
    this.thickness = 2.5,
  });

  final Color color;

  /// One top-to-bottom pass.
  final Duration period;

  /// Line length as a fraction of the available width.
  final double widthFactor;

  final double thickness;

  @override
  State<ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<ScanningLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ScanningLinePainter(
            progress: Curves.easeInOut.transform(_controller.value),
            color: widget.color,
            widthFactor: widget.widthFactor,
            thickness: widget.thickness,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ScanningLinePainter extends CustomPainter {
  _ScanningLinePainter({
    required this.progress,
    required this.color,
    required this.widthFactor,
    required this.thickness,
  });

  final double progress;
  final Color color;
  final double widthFactor;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final lineWidth = size.width * widthFactor;
    final left = (size.width - lineWidth) / 2;
    final right = left + lineWidth;
    final y = size.height * progress;

    // A glow trailing the line, so the sweep reads as motion rather than a
    // bar that teleports between frames.
    final glow = Rect.fromLTRB(
      left,
      (y - 26).clamp(0.0, size.height),
      right,
      (y + 26).clamp(0.0, size.height),
    );
    if (!glow.isEmpty) {
      canvas.drawRect(
        glow,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0),
            ],
          ).createShader(glow),
      );
    }

    canvas.drawLine(
      Offset(left, y),
      Offset(right, y),
      Paint()
        ..color = color
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_ScanningLinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.widthFactor != widthFactor ||
      oldDelegate.thickness != thickness;
}
