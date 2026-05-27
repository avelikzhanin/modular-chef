import 'package:flutter/material.dart';

/// Палитра дизайн-системы Clinical Ethereal.
/// Источник: design_input/.../serene_purity/DESIGN.md
abstract final class AppColors {
  // Surfaces — три тональных слоя (база, фон секций, плавающие карточки)
  static const Color surface = Color(0xFFF8F9FB);
  static const Color surfaceContainerLow = Color(0xFFF0F4F7);
  static const Color surfaceContainer = Color(0xFFEAEEF2);
  static const Color surfaceContainerHigh = Color(0xFFE3E8EC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // Primary — мягкий пистачо
  static const Color primary = Color(0xFF49655A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFCBE9DC);
  static const Color onPrimaryContainer = Color(0xFF3C574D);

  // Secondary — пудровая терракота
  static const Color secondary = Color(0xFF8A5D5D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFF0DEDE);
  static const Color onSecondaryContainer = Color(0xFF553535);

  // Tertiary — софт-розовый для chips
  static const Color tertiary = Color(0xFFA34F6B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFDE5EC);
  static const Color onTertiaryContainer = Color(0xFF5A2C3C);

  // Текст
  static const Color onSurface = Color(0xFF2C3337);
  static const Color onSurfaceVariant = Color(0xFF596064);

  // Outline — используется только в "ghost" виде (15% opacity)
  static const Color outlineVariant = Color(0xFFC4CACD);

  // Sanctuary shadow — тинтованный, никогда не pure black
  static const Color shadowTint = Color(0x0A2C3337); // ≈ rgba(44,51,55,0.04)
}
