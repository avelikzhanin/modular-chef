import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Профиль',
            style: tt.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          _NavTile(
            icon: Icons.menu_book_outlined,
            title: 'Мои блюда',
            subtitle: 'Личная библиотека рецептов',
            onTap: () => context.push(Routes.chefMyDishes),
          ),
          const SizedBox(height: 12),
          const _NavTile(
            icon: Icons.tune_outlined,
            title: 'Предпочтения',
            subtitle: 'Аллергии, диета, ограничения',
            onTap: null,
          ),
          const SizedBox(height: 12),
          const _NavTile(
            icon: Icons.settings_outlined,
            title: 'Настройки',
            subtitle: 'Уведомления, синхронизация',
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleMedium?.copyWith(
                      color: enabled
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: enabled
                  ? AppColors.onSurfaceVariant
                  : AppColors.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
