import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ParkiWell's original four-loop monoline mark.
///
/// The painter keeps the brand asset crisp at every display size and allows the
/// line color to adapt to light and dark surfaces without loading a bitmap.
class ParkiWellMark extends StatelessWidget {
  final double size;
  final Color color;

  const ParkiWellMark({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'ParkiWell logo',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _ParkiWellMarkPainter(color),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParkiWellMarkPainter extends CustomPainter {
  final Color color;

  const _ParkiWellMarkPainter(this.color);

  Path _petal() {
    return Path()
      ..moveTo(232, 256)
      ..cubicTo(171, 220, 158, 151, 200, 105)
      ..cubicTo(231, 71, 281, 71, 312, 105)
      ..cubicTo(354, 151, 341, 220, 280, 256)
      ..quadraticBezierTo(256, 228, 232, 256)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final scale = side / 512;
    final offset = Offset(
      (size.width - side) / 2,
      (size.height - side) / 2,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    for (var turn = 0; turn < 4; turn += 1) {
      canvas.save();
      canvas.translate(256, 256);
      canvas.rotate(turn * math.pi / 2);
      canvas.translate(-256, -256);
      canvas.drawPath(_petal(), paint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ParkiWellMarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
