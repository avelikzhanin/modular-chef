import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Типографика Clinical Ethereal: Inter из Google Fonts.
/// Display — tight letter-spacing (-0.02em), body — warm body grey.
abstract final class AppTypography {
  /// Material 3 type scale, заданная явно, чтобы её можно было применять
  /// независимо от того, удалось ли подгрузить шрифт.
  static const TextTheme baseScale = TextTheme(
    displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
    headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
    titleLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    titleSmall:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall:  TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall:  TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );

  /// Чистая функция: применяет правила Clinical Ethereal к любой базовой теме.
  /// Letter-spacing на display, цвет on_surface_variant на body, +0.05em
  /// tracking на label. Тестируется напрямую без сетевых зависимостей.
  @visibleForTesting
  static TextTheme applyClinicalRules(TextTheme base) {
    TextStyle display(TextStyle src) =>
        src.copyWith(letterSpacing: src.fontSize! * -0.02);
    TextStyle body(TextStyle src) =>
        src.copyWith(color: AppColors.onSurfaceVariant);
    TextStyle label(TextStyle src) =>
        src.copyWith(letterSpacing: src.fontSize! * 0.05);
    TextStyle heading(TextStyle src) =>
        src.copyWith(color: AppColors.onSurface);

    return base.copyWith(
      displayLarge: display(base.displayLarge!),
      displayMedium: display(base.displayMedium!),
      displaySmall: display(base.displaySmall!),
      headlineLarge: heading(base.headlineLarge!),
      headlineMedium: heading(base.headlineMedium!),
      headlineSmall: heading(base.headlineSmall!),
      titleLarge: heading(base.titleLarge!),
      titleMedium: heading(base.titleMedium!),
      titleSmall: heading(base.titleSmall!),
      bodyLarge: body(base.bodyLarge!),
      bodyMedium: body(base.bodyMedium!),
      bodySmall: body(base.bodySmall!),
      labelLarge: label(base.labelLarge!),
      labelMedium: label(base.labelMedium!),
      labelSmall: label(base.labelSmall!),
    );
  }

  /// Production: Inter (через GoogleFonts) + clinical-правила.
  /// В тестах используйте `applyClinicalRules(baseScale)` напрямую —
  /// геттер `textTheme` требует инициализированного binding'а.
  static TextTheme get textTheme =>
      applyClinicalRules(GoogleFonts.interTextTheme(baseScale));
}
