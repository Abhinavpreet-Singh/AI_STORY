import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.show,
    required this.child,
  });

  final bool show;
  final Widget child;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.play();
    }
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
        widget.child,
        if (widget.show)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _controller,
                  blastDirection: math.pi / 2,
                  blastDirectionality: BlastDirectionality.explosive,
                  maxBlastForce: 18,
                  minBlastForce: 8,
                  emissionFrequency: 0.04,
                  numberOfParticles: 24,
                  gravity: 0.15,
                  colors: const [
                    AppColors.primary,
                    AppColors.accent,
                    AppColors.success,
                    Color(0xFFFF6B9D),
                    Color(0xFF4ECDC4),
                  ],
                  createParticlePath: _drawStar,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Path _drawStar(Size size) {
    final path = Path();
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    path.moveTo(halfWidth, 0);
    path.lineTo(halfWidth * 1.2, halfHeight * 0.8);
    path.lineTo(size.width, halfHeight);
    path.lineTo(halfWidth * 1.2, halfHeight * 1.2);
    path.lineTo(halfWidth, size.height);
    path.lineTo(halfWidth * 0.8, halfHeight * 1.2);
    path.lineTo(0, halfHeight);
    path.lineTo(halfWidth * 0.8, halfHeight * 0.8);
    path.close();
    return path;
  }
}
