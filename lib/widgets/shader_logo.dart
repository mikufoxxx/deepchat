import 'package:flutter/material.dart';
import 'dart:ui';

class ShaderLogo extends StatefulWidget {
  const ShaderLogo({super.key});

  @override
  State<ShaderLogo> createState() => _ShaderLogoState();
}

class _ShaderLogoState extends State<ShaderLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            
            // 文字层
            Center(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFA6C0FE), // 淡蓝色
                      Color(0xFFF68084), // 粉红色
                    ],
                  ).createShader(bounds);
                },
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'MajorMonoDisplay',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                    children: [
                      TextSpan(
                        text: 'D',
                        style: TextStyle(fontSize: 50),
                      ),
                      TextSpan(
                        text: 'eep',
                        style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'C',
                        style: TextStyle(fontSize: 50),
                      ),
                      TextSpan(
                        text: 'hat',
                        style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 