import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/services/active_menu.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/menu_generator.dart';
import 'package:modular_chef/services/prompt_builder.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Шеф-экран «Собери своё меню» (BuildMenu).
/// Секции собираются из CatalogService — 4 основные категории каталога
/// (белки/гарниры/супы/завтраки) + раздел «Мои блюда» (на Stage 4 — из БД).
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Заранее «выбраны» популярные id из каталога.
  final Set<String> _picked = {'chicken_breast', 'salmon', 'rice', 'oatmeal_jar'};
  // Пользовательские «Мои блюда» — Stage 4 вынесет в БД.
  final List<String> _myDishes = ['Шакшука'];

  void _toggle(String id) {
    setState(() {
      _picked.contains(id) ? _picked.remove(id) : _picked.add(id);
    });
  }

  static const _sectionsOrder = <(ModuleCategory, String)>[
    (ModuleCategory.protein, 'Выберите 3–5'),
    (ModuleCategory.side, 'Выберите 2–4'),
    (ModuleCategory.soup, 'Опционально 0–2'),
    (ModuleCategory.breakfast, 'Выберите 2–3'),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catalog = context.watch<CatalogService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: !catalog.isLoaded
          ? _LoadingState(error: catalog.loadError)
          : _buildContent(context, catalog, tt),
      bottomSheet: !catalog.isLoaded
          ? null
          : Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _picked.isEmpty
                        ? null
                        : () => _generateAndOpen(context, catalog),
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

  Widget _buildContent(
      BuildContext context, CatalogService catalog, TextTheme tt) {
    return ListView(
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
        for (final (category, hint) in _sectionsOrder) ...[
          _SectionBlock(
            title: category.label,
            hint: hint,
            items: catalog
                .modulesByCategory(category)
                .map((m) => _ChoiceItem(id: m.id, name: m.name, emoji: m.emoji))
                .toList(),
            picked: _picked,
            onToggle: _toggle,
            onAddCustom: () => _showAddCustomSheet(category.label),
          ),
          const SizedBox(height: 28),
        ],
        _SectionBlock(
          title: 'Мои блюда',
          hint: 'Ваши избранные',
          items: _myDishes
              .map((n) => _ChoiceItem(id: n, name: n, emoji: '⭐'))
              .toList(),
          picked: _picked,
          onToggle: _toggle,
          onAddCustom: () => _showAddCustomSheet('Мои блюда'),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  /// Делит набор пиков на 4 категории (по тому, что есть в каталоге),
  /// зовёт генератор, кладёт результат в ActiveMenu и открывает TwoWeekMenu.
  Future<void> _generateAndOpen(
      BuildContext context, CatalogService catalog) async {
    final activeMenu = context.read<ActiveMenu>();
    final generator = context.read<MenuGenerator>();
    final byCategory = <ModuleCategory, List<String>>{
      for (final c in ModuleCategory.values) c: <String>[],
    };
    for (final id in _picked) {
      final m = catalog.moduleById(id);
      if (m != null) byCategory[m.category]!.add(id);
    }
    final request = GenerationRequest(
      proteinIds: byCategory[ModuleCategory.protein]!,
      sideIds: byCategory[ModuleCategory.side]!,
      soupIds: byCategory[ModuleCategory.soup]!,
      breakfastIds: byCategory[ModuleCategory.breakfast]!,
      customDishes: _picked
          .where((id) => catalog.moduleById(id) == null)
          .toList(growable: false),
    );

    activeMenu.beginGenerating();
    // Открываем экран сразу — он покажет loader, а когда генератор завершится,
    // перерисуется с готовым меню.
    if (context.mounted) context.push(Routes.chefTwoWeekMenu);
    try {
      final menu = await generator.generate(
        request,
        modules: catalog.allModules,
        pairings: catalog.allPairings,
      );
      activeMenu.set(menu);
    } catch (e) {
      activeMenu.fail(e);
    }
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
      setState(() {
        _myDishes.add(added);
        _picked.add(added);
      });
    }
  }
}

class _ChoiceItem {
  const _ChoiceItem({required this.id, required this.name, required this.emoji});
  final String id;
  final String name;
  final String emoji;
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Каталог не загрузился: $error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.hint,
    required this.items,
    required this.picked,
    required this.onToggle,
    required this.onAddCustom,
  });
  final String title;
  final String hint;
  final List<_ChoiceItem> items;
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
              title,
              style: tt.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              hint.toUpperCase(),
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
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              if (i == items.length) {
                return _AddTile(onTap: onAddCustom);
              }
              final item = items[i];
              return _ChoiceTile(
                item: item,
                selected: picked.contains(item.id),
                onTap: () => onToggle(item.id),
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
