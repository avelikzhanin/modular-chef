import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Шеф-экран «Список покупок» — порт chef/serene_5 из Stitch.
/// Группы по отделам магазина + переключатель недель + чекбоксы.
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  int _weekIndex = 0;

  late final List<_ShoppingSection> _sections = [
    _ShoppingSection(
      title: 'Мясо и птица',
      icon: Icons.restaurant_outlined,
      tint: _SectionTint.primary,
      items: [
        const _Item('Куриное филе, 1.2 кг'),
        const _Item('Говяжий фарш, 600 г', checked: true),
      ],
    ),
    _ShoppingSection(
      title: 'Овощи и зелень',
      icon: Icons.eco_outlined,
      tint: _SectionTint.primary,
      items: [
        const _Item('Брокколи, 2 кочана'),
        const _Item('Болгарский перец, 3 шт'),
        const _Item('Шпинат свежий, 200 г'),
        const _Item('Черри, 1 уп', checked: true),
      ],
    ),
    _ShoppingSection(
      title: 'Молочные продукты',
      icon: Icons.egg_alt_outlined,
      tint: _SectionTint.secondary,
      items: [
        const _Item('Греческий йогурт, 500 г'),
        const _Item('Яйца куриные, 10 шт'),
      ],
    ),
    _ShoppingSection(
      title: 'Бакалея',
      icon: Icons.inventory_2_outlined,
      tint: _SectionTint.primary,
      items: [
        const _Item('Оливковое масло, 1 л'),
        const _Item('Киноа, 400 г'),
        const _Item('Морская соль', checked: true),
      ],
    ),
  ];

  void _toggle(_ShoppingSection s, _Item item) {
    setState(() {
      final i = s.items.indexOf(item);
      s.items[i] = item.copy(checked: !item.checked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              Text(
                'Список покупок',
                style: tt.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ОРГАНИЗАЦИЯ РАЦИОНА',
                style: tt.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _WeekTabs(
                index: _weekIndex,
                onChanged: (i) => setState(() => _weekIndex = i),
              ),
              const SizedBox(height: 24),
              for (final s in _sections) ...[
                _SectionBlock(section: s, onToggle: _toggle),
                const SizedBox(height: 16),
              ],
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tertiaryContainer,
                foregroundColor: AppColors.onTertiaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: const StadiumBorder(),
                textStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.ios_share, size: 20),
              label: const Text('Поделиться'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SectionTint { primary, secondary }

class _ShoppingSection {
  _ShoppingSection({
    required this.title,
    required this.icon,
    required this.tint,
    required this.items,
  });
  final String title;
  final IconData icon;
  final _SectionTint tint;
  final List<_Item> items;
}

class _Item {
  const _Item(this.title, {this.checked = false});
  final String title;
  final bool checked;
  _Item copy({bool? checked}) => _Item(title, checked: checked ?? this.checked);
}

class _WeekTabs extends StatelessWidget {
  const _WeekTabs({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    Widget pill(int i, String label) {
      final selected = i == index;
      return InkWell(
        onTap: () => onChanged(i),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: tt.labelLarge?.copyWith(
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          pill(0, 'Неделя 1'),
          const SizedBox(width: 4),
          pill(1, 'Неделя 2'),
        ]),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section, required this.onToggle});
  final _ShoppingSection section;
  final void Function(_ShoppingSection, _Item) onToggle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bg = section.tint == _SectionTint.secondary
        ? AppColors.secondaryContainer.withValues(alpha: 0.3)
        : AppColors.surfaceContainerLowest;
    final iconColor = section.tint == _SectionTint.secondary
        ? AppColors.secondary
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Text(
                section.title,
                style: tt.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                onTap: () => onToggle(section, item),
                child: Row(
                  children: [
                    _Checkbox(checked: item.checked),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.title,
                        style: tt.bodyLarge?.copyWith(
                          color: item.checked
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                          decoration: item.checked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? AppColors.primaryContainer : Colors.transparent,
        border: checked
            ? null
            : Border.all(color: AppColors.primaryContainer, width: 2),
        shape: BoxShape.circle,
      ),
      child: checked
          ? const Icon(Icons.check,
              size: 14, color: AppColors.onPrimaryContainer)
          : null,
    );
  }
}
