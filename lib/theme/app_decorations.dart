import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Готовые декорации по §5A «Лён и глина».
abstract final class AppDecorations {
  /// Тёплая низкая тень из спеки: `0 8px 24px rgba(46,38,32,0.06)`.
  /// Никогда не pure black — только тёплый эспрессо-оттенок.
  static const BoxShadow warmShadow = BoxShadow(
    color: AppColors.shadowTint, // 0x0F2E2620 ≈ 6%
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  /// Карточка: тёплая бумага + тёплая тень, скругление 24 (по §5A).
  static BoxDecoration card({Color? color, double radius = 24}) => BoxDecoration(
        color: color ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [warmShadow],
      );
}
