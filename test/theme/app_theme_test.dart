import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/theme/app_colors.dart';
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
}
