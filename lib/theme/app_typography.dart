import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Типографика «Лён и глина»: Fraunces (заголовки, редакторский serif)
/// + Inter (текст/UI). Контраст serif-заголовок + sans-body — ключ к
/// взрослому редакторскому виду.
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

  /// Чистая функция: применяет правила типографики (letter-spacing, цвета)
  /// к базовой теме — БЕЗ применения шрифта, чтобы тесты работали без сети.
  /// Display — tight letter-spacing (-0.02em), body — тёплый muted, label
  /// — +0.05em tracking.
  @visibleForTesting
  static TextTheme applyTypeRules(TextTheme base) {
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

  /// Production: правила + Inter на всём, Fraunces поверх display/headline.
  /// В тестах используйте `applyTypeRules(baseScale)` напрямую —
  /// геттер `textTheme` требует инициализированного binding'а (google_fonts).
  static TextTheme get textTheme {
    final ruled = applyTypeRules(baseScale);
    final inter = GoogleFonts.interTextTheme(ruled);
    return inter.copyWith(
      displayLarge: GoogleFonts.fraunces(textStyle: inter.displayLarge),
      displayMedium: GoogleFonts.fraunces(textStyle: inter.displayMedium),
      displaySmall: GoogleFonts.fraunces(textStyle: inter.displaySmall),
      headlineLarge: GoogleFonts.fraunces(textStyle: inter.headlineLarge),
      headlineMedium: GoogleFonts.fraunces(textStyle: inter.headlineMedium),
      headlineSmall: GoogleFonts.fraunces(textStyle: inter.headlineSmall),
    );
  }
}
