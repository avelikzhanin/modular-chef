import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/theme/app_theme.dart';
import 'package:modular_chef/theme/app_typography.dart';

void main() {
  group('AppColors «Лён и глина»', () {
    test('primary is dry clay', () {
      expect(AppColors.primary, const Color(0xFFAE6A4D));
    });

    test('primary container is light clay', () {
      expect(AppColors.primaryContainer, const Color(0xFFE8CDBD));
    });

    test('surface base is warm linen', () {
      expect(AppColors.surface, const Color(0xFFEDE6DA));
    });

    test('surface lowest is warm paper for floating cards', () {
      expect(AppColors.surfaceContainerLowest, const Color(0xFFFBF6EE));
    });

    test('secondary container is warm sand-olive', () {
      expect(AppColors.secondaryContainer, const Color(0xFFE7DEC8));
    });

    test('tertiary container is warm sand', () {
      expect(AppColors.tertiaryContainer, const Color(0xFFF0E2D0));
    });

    test('on-surface variant is warm muted brown', () {
      expect(AppColors.onSurfaceVariant, const Color(0xFF8A7C6C));
    });

    test('on-surface is espresso', () {
      expect(AppColors.onSurface, const Color(0xFF2E2620));
    });
  });

  group('AppTypography.applyTypeRules', () {
    final theme = AppTypography.applyTypeRules(AppTypography.baseScale);

    test('display large uses tight letter-spacing (-0.02em)', () {
      // -0.02em при fontSize 57 ≈ -1.14 logical px
      expect(theme.displayLarge!.letterSpacing, closeTo(-1.14, 0.05));
    });

    test('body large color is the warm muted brown', () {
      expect(theme.bodyLarge!.color, const Color(0xFF8A7C6C));
    });

    test('label medium tracking is +0.05em', () {
      // +0.05em при fontSize 12 = 0.6
      expect(theme.labelMedium!.letterSpacing, closeTo(0.6, 0.05));
    });
  });

  group('AppTheme.light', () {
    // Инжектим текст-тему без google_fonts, чтобы не дёргать сеть.
    final theme = AppTheme.light(
      textTheme: AppTypography.applyTypeRules(AppTypography.baseScale),
    );

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('color scheme wires primary from AppColors', () {
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.primaryContainer, AppColors.primaryContainer);
      expect(theme.colorScheme.surface, AppColors.surface);
    });

    test('scaffold background is the linen surface', () {
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
    });

    test('card has 24 radius and warm paper background, no elevation', () {
      final card = theme.cardTheme;
      expect(card.color, AppColors.surfaceContainerLowest);
      final shape = card.shape as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).topLeft.x, 24);
      expect(card.elevation, 0);
    });

    test('filled button is restrained: clay fill, 14 radius, not a pill', () {
      final style = theme.filledButtonTheme.style!;
      final shape = style.shape!.resolve({}) as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).topLeft.x, 14);
      expect(style.backgroundColor!.resolve({}), AppColors.primary);
    });

    test('navigation bar is flat and uses primary container as indicator', () {
      final nav = theme.navigationBarTheme;
      expect(nav.backgroundColor, AppColors.surfaceContainerLowest);
      expect(nav.indicatorColor, AppColors.primaryContainer);
      expect(nav.surfaceTintColor, Colors.transparent);
    });

    test('app bar is flat — no elevation, no surface tint', () {
      final bar = theme.appBarTheme;
      expect(bar.elevation, 0);
      expect(bar.scrolledUnderElevation, 0);
      expect(bar.backgroundColor, AppColors.surface);
      expect(bar.surfaceTintColor, Colors.transparent);
    });
  });
}
