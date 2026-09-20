import 'dart:math';
import 'package:flutter/material.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Деликатное «зерно» бумаги поверх всего приложения (§5A «Фактура»).
/// Очень низкая непрозрачность, не перехватывает тапы, рисуется один раз.
class PaperGrain extends StatelessWidget {
  const PaperGrain({super.key, this.opacity = 0.035});
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: _GrainPainter(opacity),
          size: Size.infinite,
        ),
      );
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.opacity);
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rnd = Random(7); // фикс. seed — стабильное зерно
    final paint = Paint()
      ..color = AppColors.onSurface.withValues(alpha: opacity);
    final count =
        (size.width * size.height / 220).clamp(0, 6000).toInt();
    for (var i = 0; i < count; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
