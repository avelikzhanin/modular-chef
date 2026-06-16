import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Шеф-экран «Список покупок» — порт chef/serene_5 + разделение «Купить» / «Уже есть».
/// `bought` — отметка в магазине (зачёркнуто). `have` — «уже есть дома», покупать не надо.
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
        _Item('Куриное филе, 1.2 кг'),
        _Item('Говяжий фарш, 600 г', bought: true),
      ],
    ),
    _ShoppingSection(
      title: 'Овощи и зелень',
      icon: Icons.eco_outlined,
      tint: _SectionTint.primary,
      items: [
        _Item('Брокколи, 2 кочана'),
        _Item('Болгарский перец, 3 шт'),
        _Item('Шпинат свежий, 200 г'),
        _Item('Черри, 1 уп', bought: true),
      ],
    ),
    _ShoppingSection(
      title: 'Молочные продукты',
      icon: Icons.egg_alt_outlined,
      tint: _SectionTint.secondary,
      items: [
        _Item('Греческий йогурт, 500 г'),
        _Item('Яйца куриные, 10 шт', have: true),
      ],
    ),
    _ShoppingSection(
      title: 'Бакалея',
      icon: Icons.inventory_2_outlined,
      tint: _SectionTint.primary,
      items: [
        _Item('Оливковое масло, 1 л', have: true),
        _Item('Киноа, 400 г'),
        _Item('Морская соль', have: true),
      ],
    ),
  ];

  void _toggleBought(_Item item) => setState(() => item.bought = !item.bought);
  void _toggleHave(_Item item) => setState(() {
        item.have = !item.have;
        if (item.have) item.bought = false; // «есть дома» — не надо покупать
      });

  int get _toBuyCount =>
      _sections.expand((s) => s.items).where((i) => !i.have).length;
  int get _haveCount =>
      _sections.expand((s) => s.items).where((i) => i.have).length;

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
              const SizedBox(height: 6),
              Text(
                'Купить $_toBuyCount · уже есть $_haveCount',
                style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _WeekTabs(
                index: _weekIndex,
                onChanged: (i) => setState(() => _weekIndex = i),
              ),
              const SizedBox(height: 24),
              for (final s in _sections) ...[
                _SectionBlock(
                  section: s,
                  onToggleBought: _toggleBought,
                  onToggleHave: _toggleHave,
                ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
  _Item(this.title, {this.bought = false, this.have = false});
  final String title;
  bool bought; // отмечено купленным в магазине
  bool have; // уже есть дома — покупать не надо
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
  const _SectionBlock({
    required this.section,
    required this.onToggleBought,
    required this.onToggleHave,
  });
  final _ShoppingSection section;
  final ValueChanged<_Item> onToggleBought;
  final ValueChanged<_Item> onToggleHave;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bg = section.tint == _SectionTint.secondary
        ? AppColors.secondaryContainer.withValues(alpha: 0.3)
        : AppColors.surfaceContainerLowest;
    final iconColor = section.tint == _SectionTint.secondary
        ? AppColors.secondary
        : AppColors.primary;

    final toBuy = section.items.where((i) => !i.have).toList();
    final have = section.items.where((i) => i.have).toList();

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
          const SizedBox(height: 12),
          for (final item in toBuy)
            _ItemRow(
              item: item,
              onToggleBought: () => onToggleBought(item),
              onToggleHave: () => onToggleHave(item),
            ),
          if (have.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'УЖЕ ЕСТЬ',
              style: tt.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            for (final item in have)
              _ItemRow(
                item: item,
                onToggleBought: () => onToggleBought(item),
                onToggleHave: () => onToggleHave(item),
              ),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onToggleBought,
    required this.onToggleHave,
  });
  final _Item item;
  final VoidCallback onToggleBought;
  final VoidCallback onToggleHave;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final muted = item.have || item.bought;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Лидирующий маркер: для «купить» — чекбокс куплено; для «есть» — дом
          if (item.have)
            const Icon(Icons.home_filled, size: 22, color: AppColors.secondary)
          else
            GestureDetector(
              onTap: onToggleBought,
              child: _Checkbox(checked: item.bought),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: item.have ? null : onToggleBought,
              behavior: HitTestBehavior.opaque,
              child: Text(
                item.title,
                style: tt.bodyLarge?.copyWith(
                  color: muted ? AppColors.onSurfaceVariant : AppColors.onSurface,
                  decoration:
                      item.bought ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
          ),
          // Тоггл «есть дома»
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              item.have ? Icons.undo : Icons.home_outlined,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            tooltip: item.have ? 'Вернуть в покупки' : 'Уже есть дома',
            onPressed: onToggleHave,
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
          ? const Icon(Icons.check, size: 14, color: AppColors.onPrimaryContainer)
          : null,
    );
  }
}
