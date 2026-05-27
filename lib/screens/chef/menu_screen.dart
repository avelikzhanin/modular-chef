import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Шеф-экран «Собери своё меню» (BuildMenu) — переделанный chef/serene_1.
/// 5 секций с горизонтальным скроллом карточек + плитка «+ Своё»,
/// state — Set выбранных названий, sticky CTA «Собрать меню».
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final Set<String> _picked = {'Курица', 'Лосось', 'Рис', 'Овсянка'};

  static const _sections = <_Section>[
    _Section(
      title: 'Белки',
      hint: 'Выберите 3–5',
      items: [
        _ChoiceItem('Курица', '🍗'),
        _ChoiceItem('Лосось', '🐟'),
        _ChoiceItem('Стейк', '🥩'),
        _ChoiceItem('Индейка', '🦃'),
        _ChoiceItem('Фрикадельки', '🧆'),
        _ChoiceItem('Треска', '🐠'),
        _ChoiceItem('Креветки', '🦐'),
        _ChoiceItem('Тофу', '🟫'),
      ],
    ),
    _Section(
      title: 'Гарниры',
      hint: 'Выберите 2–4',
      items: [
        _ChoiceItem('Рис', '🍚'),
        _ChoiceItem('Гречка', '🟤'),
        _ChoiceItem('Булгур', '🌾'),
        _ChoiceItem('Спагетти', '🍝'),
        _ChoiceItem('Картофель', '🥔'),
        _ChoiceItem('Кускус', '🌾'),
      ],
    ),
    _Section(
      title: 'Супы',
      hint: 'Опционально 0–2',
      items: [
        _ChoiceItem('Сырный', '🧀'),
        _ChoiceItem('Куриный с лапшой', '🍜'),
        _ChoiceItem('Томатный', '🍅'),
        _ChoiceItem('Тыквенный', '🎃'),
        _ChoiceItem('Грибной', '🍄'),
      ],
    ),
    _Section(
      title: 'Завтраки',
      hint: 'Выберите 2–3',
      items: [
        _ChoiceItem('Овсянка', '🥣'),
        _ChoiceItem('Сырники', '🧇'),
        _ChoiceItem('Омлет', '🍳'),
        _ChoiceItem('Каша', '🌾'),
        _ChoiceItem('Бутерброды', '🥪'),
        _ChoiceItem('Гранола', '🥥'),
      ],
    ),
    _Section(
      title: 'Мои блюда',
      hint: 'Ваши избранные',
      items: [
        _ChoiceItem('Шакшука', '🍳'),
      ],
    ),
  ];

  void _toggle(String name) {
    setState(() {
      _picked.contains(name) ? _picked.remove(name) : _picked.add(name);
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Text(
            'Собери своё меню',
            style: tt.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Выберите ингредиенты на 2 недели — система подберёт сочетания.',
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 28),
          for (final s in _sections) ...[
            _SectionBlock(
              section: s,
              picked: _picked,
              onToggle: _toggle,
              onAddCustom: () => _showAddCustomSheet(s.title),
            ),
            const SizedBox(height: 28),
          ],
        ],
      ),
      bottomSheet: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _picked.isEmpty
                  ? null
                  : () => context.push(Routes.chefTwoWeekMenu),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                disabledBackgroundColor: AppColors.surfaceContainerHigh,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: const StadiumBorder(),
                textStyle:
                    tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: Text('Собрать меню · ${_picked.length}'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCustomSheet(String sectionTitle) async {
    final controller = TextEditingController();
    final added = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Добавить в «$sectionTitle»',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Например, нут',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Добавить'),
              ),
            ),
          ],
        ),
      ),
    );
    if (added != null && added.isNotEmpty && mounted) {
      setState(() => _picked.add(added));
    }
  }
}

class _Section {
  const _Section({required this.title, required this.hint, required this.items});
  final String title;
  final String hint;
  final List<_ChoiceItem> items;
}

class _ChoiceItem {
  const _ChoiceItem(this.name, this.emoji);
  final String name;
  final String emoji;
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.section,
    required this.picked,
    required this.onToggle,
    required this.onAddCustom,
  });
  final _Section section;
  final Set<String> picked;
  final ValueChanged<String> onToggle;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              section.title,
              style: tt.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              section.hint.toUpperCase(),
              style: tt.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: section.items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              if (i == section.items.length) {
                return _AddTile(onTap: onAddCustom);
              }
              final item = section.items[i];
              return _ChoiceTile(
                item: item,
                selected: picked.contains(item.name),
                onTap: () => onToggle(item.name),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final _ChoiceItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 28)),
                if (selected)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        size: 14, color: AppColors.onPrimary),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(
                color: selected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              '+ Своё',
              style: tt.labelLarge?.copyWith(
                color: AppColors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
