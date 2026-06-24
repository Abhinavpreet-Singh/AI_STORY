import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class BuddyCharacter extends StatefulWidget {
  const BuddyCharacter({
    super.key,
    required this.isHappy,
    this.isSpeaking = false,
    this.compact = false,
  });

  final bool isHappy;
  final bool isSpeaking;
  final bool compact;

  @override
  State<BuddyCharacter> createState() => _BuddyCharacterState();
}

class _BuddyCharacterState extends State<BuddyCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isSpeaking) {
      _bounceController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BuddyCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _bounceController.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _bounceController.stop();
      _bounceController.value = 0;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        final bounce = widget.isSpeaking
            ? math.sin(_bounceController.value * math.pi) * (widget.compact ? 3 : 4)
            : 0.0;

        return Transform.translate(
          offset: Offset(0, -bounce),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: widget.compact ? 110 : 160,
        height: widget.compact ? 110 : 160,
        decoration: BoxDecoration(
          color: widget.isHappy ? AppColors.accent.withValues(alpha: 0.3) : AppColors.buddyBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: widget.isHappy ? AppColors.accent : AppColors.primary.withValues(alpha: 0.25),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _PipRobotPainter(isHappy: widget.isHappy),
          size: Size(widget.compact ? 110 : 160, widget.compact ? 110 : 160),
        ),
      ),
    ),
    );
  }
}

class _PipRobotPainter extends CustomPainter {
  _PipRobotPainter({required this.isHappy});

  final bool isHappy;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Antenna
    final antennaPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - 42),
      Offset(center.dx, center.dy - 58),
      antennaPaint,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - 62),
      6,
      Paint()..color = AppColors.accent,
    );

    // Head
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy - 20), width: 72, height: 56),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      headRect,
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      headRect,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Eyes
    final eyeY = center.dy - 24;
    if (isHappy) {
      _drawHappyEye(canvas, Offset(center.dx - 14, eyeY));
      _drawHappyEye(canvas, Offset(center.dx + 14, eyeY));
    } else {
      canvas.drawCircle(
        Offset(center.dx - 14, eyeY),
        5,
        Paint()..color = AppColors.primaryDark,
      );
      canvas.drawCircle(
        Offset(center.dx + 14, eyeY),
        5,
        Paint()..color = AppColors.primaryDark,
      );
    }

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 28), width: 64, height: 52),
      const Radius.circular(12),
    );
    canvas.drawRRect(bodyRect, Paint()..color = AppColors.primary);
    canvas.drawCircle(
      Offset(center.dx, center.dy + 28),
      8,
      Paint()..color = AppColors.accent,
    );

    // Arms
    final armPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - 36, center.dy + 20),
      Offset(center.dx - 50, center.dy + 38),
      armPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 36, center.dy + 20),
      Offset(center.dx + 50, center.dy + (isHappy ? 30 : 38)),
      armPaint,
    );
  }

  void _drawHappyEye(Canvas canvas, Offset center) {
    final path = Path()
      ..moveTo(center.dx - 6, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - 8, center.dx + 6, center.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primaryDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PipRobotPainter oldDelegate) =>
      oldDelegate.isHappy != isHappy;
}
