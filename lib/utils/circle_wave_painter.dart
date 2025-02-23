import 'package:flutter/material.dart';

class CircleWavePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  CircleWavePainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50.0);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CircleWavePainter oldDelegate) =>
      center != oldDelegate.center ||
      radius != oldDelegate.radius ||
      color != oldDelegate.color;
} 