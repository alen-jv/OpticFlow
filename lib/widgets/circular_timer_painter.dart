import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/session_type.dart';
import '../utils/app_theme.dart';

/// Custom painter that draws the animated circular progress ring.
class CircularTimerPainter extends CustomPainter {
  final double progress;       // 0.0 (empty) → 1.0 (full)
  final SessionType session;
  final Animation<double> glowAnimation;

  CircularTimerPainter({
    required this.progress,
    required this.session,
    required this.glowAnimation,
  }) : super(repaint: glowAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    const startAngle = -math.pi / 2; // Start at 12 o'clock
    final sweepAngle = 2 * math.pi * progress;

    // ── Track ring (background) ────────────────────────────────────────────
    final trackPaint = Paint()
      ..color = AppTheme.ringTrack(session)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // ── Glow layer (soft outer halo) ───────────────────────────────────────
    final glowPaint = Paint()
      ..color = AppTheme.ringColor(session)
          .withOpacity(0.18 * glowAnimation.value)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    // ── Progress arc ───────────────────────────────────────────────────────
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + 2 * math.pi,
        colors: [
          AppTheme.ringColor(session),
          AppTheme.accentColor(session),
          AppTheme.ringColor(session),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(startAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // ── Tip dot ────────────────────────────────────────────────────────────
    if (progress > 0.01) {
      final tipX = center.dx + radius * math.cos(startAngle + sweepAngle);
      final tipY = center.dy + radius * math.sin(startAngle + sweepAngle);
      final dotPaint = Paint()
        ..color = AppTheme.accentColor(session)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), 7, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CircularTimerPainter old) =>
      old.progress != progress || old.session != session;
}
