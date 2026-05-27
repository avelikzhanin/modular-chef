import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/theme/app_colors.dart';

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
}
