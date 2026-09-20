import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'role.dart';
import 'role_provider.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Сегмент-переключатель «Шеф | Гость» — по макету Stitch:
/// песочный трек, активный сегмент — светло-зелёная пилюля (Light Leaf).
/// Компактный: помещается в AppBar (высота ≤ 40) без обрезания подсветки.
class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>().role;
    final tt = Theme.of(context).textTheme;

    Widget seg(UserRole value, String label) {
      final selected = role == value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.read<RoleProvider>().setRole(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.lightLeaf : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? const [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 4,
                        offset: Offset(0, 1)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                value == UserRole.chef
                    ? 'assets/art/ui/role_chef.png'
                    : 'assets/art/ui/role_guest.png',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: tt.labelMedium?.copyWith(
                  color: selected
                      ? AppColors.leafDeep
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(UserRole.chef, 'Шеф'),
          seg(UserRole.guest, 'Гость'),
        ],
      ),
    );
  }
}
