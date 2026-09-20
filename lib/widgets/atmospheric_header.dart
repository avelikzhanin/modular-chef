import 'package:flutter/material.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Атмосферная шапка по §5A: мягкое тёплое «небо» с облаками, плавный fade
/// в льняной фон, крупный серифный заголовок (Fraunces) + подпись.
/// Лёгкая замена плоскому AppBar на ключевых экранах.
class AtmosphericHeader extends StatelessWidget {
  const AtmosphericHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.background = 'assets/art/bg_clouds.png',
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;

  /// Акварельная подложка шапки (у каждого экрана — свой мотив).
  final String background;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final topPad = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        width: double.infinity,
        color: AppColors.surface,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Настоящее акварельное небо (сгенерировано) + fade в лён снизу.
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(background,
                      fit: BoxFit.cover, alignment: Alignment.topCenter),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.surface],
                        stops: [0.35, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 12, 16, 26),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Логотип и wordmark убраны — имя живёт на иконке приложения.
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      if (onBack != null)
                        _RoundIcon(icon: Icons.arrow_back, onTap: onBack!),
                      const Spacer(),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: tt.headlineMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.onPrimaryContainer),
                  ),
                ],
              ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.onSurface),
      ),
    );
  }
}
