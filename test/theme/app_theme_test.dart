import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/theme/app_theme.dart';
import 'package:modular_chef/theme/app_typography.dart';

void main() {
  group('AppColors', () {
    test('primary is the muted pistachio from spec', () {
      expect(AppColors.primary, const Color(0xFF49655A));
    });

    test('primary container is the soft pistachio', () {
      expect(AppColors.primaryContainer, const Color(0xFFCBE9DC));
    });

    test('surface base is the cool off-white', () {
      expect(AppColors.surface, const Color(0xFFF8F9FB));
    });

    test('surface lowest is pure white for floating cards', () {
      expect(AppColors.surfaceContainerLowest, const Color(0xFFFFFFFF));
    });

    test('secondary container is the powdery terracotta', () {
      expect(AppColors.secondaryContainer, const Color(0xFFF0DEDE));
    });

    test('tertiary container is the soft pink', () {
      expect(AppColors.tertiaryContainer, const Color(0xFFFDE5EC));
    });

    test('on-surface variant is the warm body grey', () {
      expect(AppColors.onSurfaceVariant, const Color(0xFF596064));
    });
  });

  group('AppTypography.applyClinicalRules', () {
    final theme = AppTypography.applyClinicalRules(AppTypography.baseScale);

    test('display large uses tight letter-spacing per spec (-0.02em)', () {
      // -0.02em при fontSize 57 ≈ -1.14 logical px
      expect(theme.displayLarge!.letterSpacing, closeTo(-1.14, 0.05));
    });

    test('body large color is the warm body grey', () {
      expect(theme.bodyLarge!.color, const Color(0xFF596064));
    });

    test('label medium is uppercase tracking +0.05em', () {
      // +0.05em при fontSize 12 = 0.6
      expect(theme.labelMedium!.letterSpacing, closeTo(0.6, 0.05));
    });
  });

  group('AppTheme.light', () {
    // Инжектим текст-тему без google_fonts, чтобы не дёргать asset bundle.
    final theme = AppTheme.light(
      textTheme: AppTypography.applyClinicalRules(AppTypography.baseScale),
    );

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('color scheme wires primary from AppColors', () {
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.primaryContainer, AppColors.primaryContainer);
      expect(theme.colorScheme.surface, AppColors.surface);
    });

    test('scaffold background is the surface base', () {
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
    });

    test('card has xl radius (24) and white background, no elevation', () {
      final card = theme.cardTheme;
      expect(card.color, AppColors.surfaceContainerLowest);
      final shape = card.shape as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).topLeft.x, 24);
      expect(card.elevation, 0);
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
