import 'dart:math';

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AuthGradientBackground extends StatefulWidget {
  final Widget child;

  const AuthGradientBackground({super.key, required this.child});

  @override
  State<AuthGradientBackground> createState() => _AuthGradientBackgroundState();
}

class _AuthGradientBackgroundState extends State<AuthGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<_BubbleData> _bubbles = [
    _BubbleData(top: 80, left: -30, size: 120, phase: 0),
    _BubbleData(top: 200, left: 250, size: 150, phase: pi / 2),
    _BubbleData(top: 400, left: 50, size: 100, phase: pi),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.primary,
            child: Stack(
              children: [
                ..._bubbles.map(_buildAnimatedBubble),
                widget.child,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBubble(_BubbleData bubble) {
    final offset = sin((_controller.value * 2 * pi) + bubble.phase) * 20;

    return Positioned(
      top: bubble.top + offset,
      left: bubble.left,
      child: Container(
        width: bubble.size,
        height: bubble.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.secondary.withOpacity(0.15),
        ),
      ),
    );
  }
}

class _BubbleData {
  final double top;
  final double left;
  final double size;
  final double phase;

  _BubbleData({
    required this.top,
    required this.left,
    required this.size,
    required this.phase,
  });
}
