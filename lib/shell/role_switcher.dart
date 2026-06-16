import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'role.dart';
import 'role_provider.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Компактный сегмент-переключатель «Шеф | Гость» для AppBar.
/// Видны оба состояния — понятнее, чем иконка-стрелка.
class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>().role;
    final tt = Theme.of(context).textTheme;

    Widget seg(UserRole value, IconData icon, String label) {
      final selected = role == value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.read<RoleProvider>().setRole(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: tt.labelMedium?.copyWith(
                  color:
                      selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(UserRole.chef, Icons.restaurant_menu, 'Шеф'),
          seg(UserRole.guest, Icons.fastfood_outlined, 'Гость'),
        ],
      ),
    );
  }
}
