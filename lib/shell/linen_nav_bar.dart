import 'package:flutter/material.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Пункт нижней навигации «Лён и лист» — акварельная мини-иконка.
class LinenNavItem {
  const LinenNavItem({required this.asset, required this.label});
  final String asset; // assets/art/ui/nav_*.png
  final String label;
}

/// Нижняя навигация: тёплый песочный фон, скругление сверху, мягкая тень;
/// активный таб — зелёная пилюля, иконки — акварельные.
class LinenNavBar extends StatelessWidget {
  const LinenNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<LinenNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _sand = Color(0xFFF1E1BC);
  static const _muted = Color(0xFF50462A);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, bottomPad + 12),
      decoration: const BoxDecoration(
        color: _sand,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F2E2620),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < items.length; i++) _item(tt, i),
        ],
      ),
    );
  }

  Widget _item(TextTheme tt, int i) {
    final item = items[i];
    final selected = i == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding:
            EdgeInsets.symmetric(horizontal: selected ? 14 : 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.lightLeaf
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: selected ? 1 : 0.8,
              child: Image.asset(item.asset, width: 42, height: 42),
            ),
            Text(
              item.label,
              style: tt.labelSmall?.copyWith(
                color: selected ? AppColors.leafDeep : _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
