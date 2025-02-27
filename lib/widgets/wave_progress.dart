import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shimmer/shimmer.dart';

class WaveProgress extends StatefulWidget {
  final double progress;
  final double height;
  final Color color;
  final Color backgroundColor;
  final bool showShimmer;

  const WaveProgress({
    super.key,
    required this.progress,
    this.height = 60,
    this.color = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.showShimmer = true,
  });

  @override
  State<WaveProgress> createState() => _WaveProgressState();
}

class _WaveProgressState extends State<WaveProgress> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 骨架屏效果
        if (widget.showShimmer)
          Shimmer.fromColors(
            baseColor: widget.backgroundColor.withOpacity(0.1),
            highlightColor: widget.backgroundColor.withOpacity(0.2),
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        
        // 波浪进度
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      progress: widget.progress,
                      color: widget.color,
                      waveOffset: _controller.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              Center(
                child: Text(
                  '${(widget.progress * 100).toInt()}%',
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double waveOffset;

  WavePainter({
    required this.progress,
    required this.color,
    required this.waveOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final y = size.height * (1 - progress);

    // 添加渐变效果
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.1),
        color.withOpacity(0.3),
      ],
    );
    paint.shader = gradient.createShader(Rect.fromLTWH(0, y, size.width, size.height - y));

    path.moveTo(0, size.height);
    path.lineTo(0, y);
    
    // 使用三个不同频率的正弦波叠加，使波浪更自然
    for (double i = 0; i <= size.width + 4; i++) {
      final wave1 = math.sin((i / 50) + (waveOffset * math.pi * 2)) * 4;
      final wave2 = math.sin((i / 40) + (waveOffset * math.pi * 2 * 1.2)) * 3;
      final wave3 = math.sin((i / 30) + (waveOffset * math.pi * 2 * 0.8)) * 2;
      path.lineTo(
        i,
        y + wave1 + wave2 + wave3,
      );
    }

    path.lineTo(size.width, size.height);
    path.close();

    // 添加波浪阴影效果
    canvas.drawShadow(path, color.withOpacity(0.2), 2.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) =>
      progress != oldDelegate.progress || waveOffset != oldDelegate.waveOffset;
}