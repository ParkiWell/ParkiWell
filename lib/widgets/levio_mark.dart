import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Levio's original four-loop monoline mark.
///
/// The painter keeps the brand asset crisp at every display size and allows the
/// line color to adapt to light and dark surfaces without loading a bitmap.
class LevioMark extends StatelessWidget {
  final double size;
  final Color color;

  const LevioMark({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Levio logo',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _LevioMarkPainter(color),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevioMarkPainter extends CustomPainter {
  final Color color;

  const _LevioMarkPainter(this.color);

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
  bool shouldRepaint(covariant _LevioMarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
