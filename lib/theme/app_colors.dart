import 'package:flutter/material.dart';

/// Палитра дизайн-системы «Лён и глина».
/// Источник: docs/superpowers/specs/2026-05-28-modular-chef-v2-plates-design.md §5A
/// Тёплая, выцветшая, природная — заменяет зелёный Clinical Ethereal.
abstract final class AppColors {
  // Surfaces — тёплые льняные тона (база, секции, плавающие карточки)
  static const Color surface = Color(0xFFEDE6DA); // льняной фон
  static const Color surfaceContainerLow = Color(0xFFE8E0D2); // секции/подложки
  static const Color surfaceContainer = Color(0xFFE2D9C8);
  static const Color surfaceContainerHigh = Color(0xFFDCD2BE);
  static const Color surfaceContainerLowest = Color(0xFFFBF6EE); // карточки (тёплая бумага)

  // Primary — сухая глина (терракота приглушённая)
  static const Color primary = Color(0xFFAE6A4D);
  static const Color onPrimary = Color(0xFFFFF7F1);
  static const Color primaryContainer = Color(0xFFE8CDBD); // светлая глина — заливки/индикатор
  static const Color onPrimaryContainer = Color(0xFF6E3D27);

  // Secondary — олива-тауп
  static const Color secondary = Color(0xFF8A7E5E);
  static const Color onSecondary = Color(0xFFFFFBF2);
  static const Color secondaryContainer = Color(0xFFE7DEC8);
  static const Color onSecondaryContainer = Color(0xFF4E472F);

  // Tertiary — тёплый песок/блаш для chips
  static const Color tertiary = Color(0xFFA86B4A);
  static const Color onTertiary = Color(0xFFFFFBF2);
  static const Color tertiaryContainer = Color(0xFFF0E2D0);
  static const Color onTertiaryContainer = Color(0xFF7A5A33);

  // Текст — эспрессо
  static const Color onSurface = Color(0xFF2E2620);
  static const Color onSurfaceVariant = Color(0xFF8A7C6C);

  // Outline — только в "ghost" виде (низкая непрозрачность)
  static const Color outlineVariant = Color(0xFFCFC3AE);

  // Тёплая низкая тень — никогда не pure black
  static const Color shadowTint = Color(0x0F2E2620); // ≈ rgba(46,38,32,0.06)
}
