import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/screens/chef/menu_archive_screen.dart';
import 'package:modular_chef/shell/role.dart';
import 'package:modular_chef/shell/role_provider.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/widgets/atmospheric_header.dart';

/// Профиль — собран точно по дизайну Stitch: заголовок-курсив + аватар,
/// подзаголовок, переключатель-пилюля «Шеф | Гость», стопка плиток.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        children: [
          AtmosphericHeader(
            title: 'Профиль',
            subtitle: 'Твоя кухня и твои привычки — всё, что делает меню «твоим».',
            background: 'assets/art/bg_profile.png',
            trailing: Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryContainer, width: 2),
              ),
              child: Image.asset('assets/art/avatar_chef.png', fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

          // Переключатель ролей — пилюля во всю ширину
          const _RolePill(),
          const SizedBox(height: 24),

          // Плитки — акварельные глифы
          _NavTile(
            asset: 'assets/art/ui/tile_dishes.png',
            title: 'Мои блюда',
            subtitle: 'Личная библиотека рецептов',
            onTap: () => context.push(Routes.chefMyDishes),
          ),
          const SizedBox(height: 16),
          _NavTile(
            asset: 'assets/art/ui/tile_combos.png',
            title: 'Мои сочетания',
            subtitle: 'Любимые тройки для генератора',
            onTap: () => context.push(Routes.chefFavourites),
          ),
          const SizedBox(height: 16),
          _NavTile(
            asset: 'assets/art/ui/tile_breakfast.png',
            title: 'Заготовки завтраков',
            subtitle: 'Банки и яйца впрок',
            onTap: () => context.push(Routes.chefBreakfastPreps),
          ),
          const SizedBox(height: 16),
          _NavTile(
            asset: 'assets/art/ui/tile_prefs.png',
            title: 'Предпочтения',
            subtitle: 'Аллергии, диета',
            onTap: () => context.push(Routes.chefPreferences),
          ),
          const SizedBox(height: 16),
          _NavTile(
            asset: 'assets/art/ui/nav_menu.png',
            title: 'Прошлые меню',
            subtitle: 'Архив утверждённых меню по датам',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MenuArchiveScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _NavTile(
            asset: 'assets/art/ui/tile_settings.png',
            title: 'Настройки',
            subtitle: 'Порции с одной готовки',
            onTap: () => context.push(Routes.chefSettings),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final role = context.watch<RoleProvider>().role;

    Widget seg(UserRole value, String label) {
      final selected = role == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.read<RoleProvider>().setRole(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: tt.labelLarge?.copyWith(
                color: selected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: [seg(UserRole.chef, 'Шеф'), seg(UserRole.guest, 'Гость')]),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String asset;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                        color: AppColors.shadowTint,
                        blurRadius: 24,
                        offset: Offset(0, 8)),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.lightLeaf : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(12),
                child: Opacity(
                  opacity: enabled ? 1 : 0.55,
                  child: Image.asset(asset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: tt.titleMedium?.copyWith(
                          color: enabled
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: tt.labelMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(enabled ? Icons.chevron_right_rounded : Icons.lock_rounded,
                  color: AppColors.onSurfaceVariant, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
