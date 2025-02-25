import 'package:flutter/material.dart';
import 'dart:math' show sqrt;

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset centerOffset;
  
  CircularRevealClipper({
    required this.fraction,
    required this.centerOffset,
  });
  
  @override
  Path getClip(Size size) {
    final center = centerOffset;
    final maxRadius = sqrt(size.width * size.width + size.height * size.height);
    final radius = maxRadius * fraction;
    
    final path = Path()
      ..addOval(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );
    
    return path;
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
} 