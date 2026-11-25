import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Anillo de progreso (como el de "Be more active" de S Health).
class DonutProgress extends StatelessWidget {
  const DonutProgress({
    super.key,
    required this.progress,
    required this.child,
    this.size = 160,
    this.stroke = 16,
    this.color = AppColors.orange,
  });

  final double progress; // 0..1
  final Widget child;
  final double size;
  final double stroke;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          progress: progress.clamp(0.0, 1.0).toDouble(),
          color: color,
          track: AppColors.silver.withValues(alpha: 0.45),
          stroke: stroke,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}