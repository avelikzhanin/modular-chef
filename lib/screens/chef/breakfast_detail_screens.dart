import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/services/breakfast_preps.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/widgets/leaf_button.dart';
import 'package:modular_chef/widgets/module_picker_row.dart';

/// Добавки к кашам — из баночных слоёв и бакалеи.
const kPorridgeAddinIds = [
  'jbar_honey', 'jbar_jam', 'jm_banana', 'jm_strawberry', 'jm_raspberry',
  'jm_blueberry', 'jm_dried_fruit', 'jt_walnuts', 'jt_almonds',
  'jt_chia_flax',
];

/// Намазки для бутербродов.
const kSandwichSpreadIds = [
  'jbar_cream_cheese', 'addin_avocado', 'hummus', 'pesto', 'guacamole',
  'jbar_honey',
];

/// Что кладём сверху.
const kSandwichToppingIds = [
  'addin_cheese', 'addin_ham', 'addin_salmon', 'addin_feta', 'addin_herbs',
  'cherry_tomato',
];

/// Как готовим хлеб.
const kBreadPreps = [
  'Свежий', 'Тосты', 'На сковороде с маслом', 'В аэрогриле',
];

List<Module> _byIds(CatalogService c, List<String> ids) =>
    [for (final id in ids) if (c.moduleById(id) != null) c.moduleById(id)!];

/// Общий каркас: шапка, ленты выбора, «Готово».
class _PrepDetailScaffold extends StatelessWidget {
  const _PrepDetailScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Text(subtitle,
              style:
                  tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
      bottomSheet: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: LeafButton(
            onPressed: () => Navigator.maybePop(context),
            label: 'Готово',
          ),
        ),
      ),
    );
  }
}

/// Яйца: виды + общий набор добавок.
class EggsPrepScreen extends StatelessWidget {
  const EggsPrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final preps = context.watch<BreakfastPreps>();
    return _PrepDetailScaffold(
      title: 'Яйца на завтрак',
      subtitle: 'Какие яйца готовим и что к ним купить — '
          'утром Гость сам достанет добавки из холодильника.',
      children: [
        ModulePickerRow(
          label: 'Виды яиц',
          optional: false,
          modules: catalog.modulesByCategory(ModuleCategory.eggStyle),
          selectedIds: preps.eggStyleIds,
          onTap: (m) => preps.toggleEggStyle(m.id),
        ),
        const SizedBox(height: 20),
        ModulePickerRow(
          label: 'Добавки к яйцам',
          optional: true,
          modules: catalog.modulesByCategory(ModuleCategory.eggAddin),
          selectedIds: preps.eggAddinIds,
          onTap: (m) => preps.toggleEggAddin(m.id),
        ),
      ],
    );
  }
}

/// Каша: виды + добавки.
class PorridgePrepScreen extends StatelessWidget {
  const PorridgePrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final preps = context.watch<BreakfastPreps>();
    return _PrepDetailScaffold(
      title: 'Каша на завтрак',
      subtitle: 'Какие каши варим и с чем подаём.',
      children: [
        ModulePickerRow(
          label: 'Какая каша',
          optional: false,
          modules: catalog
              .modulesByCategory(ModuleCategory.breakfast)
              .where((m) => m.tags.contains('porridge_kind'))
              .toList(),
          selectedIds: preps.porridgeKindIds,
          onTap: (m) => preps.togglePorridgeKind(m.id),
        ),
        const SizedBox(height: 20),
        ModulePickerRow(
          label: 'Добавки',
          optional: true,
          modules: _byIds(catalog, kPorridgeAddinIds),
          selectedIds: preps.porridgeAddinIds,
          onTap: (m) => preps.togglePorridgeAddin(m.id),
        ),
      ],
    );
  }
}

/// Бутерброды: конструктор — хлеб, намазка, сверху.
class SandwichPrepScreen extends StatelessWidget {
  const SandwichPrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catalog = context.watch<CatalogService>();
    final preps = context.watch<BreakfastPreps>();
    return _PrepDetailScaffold(
      title: 'Бутерброды',
      subtitle:
          'Собери как банку: хлеб — как готовим, намазка, и что кладём сверху.',
      children: [
        Text('1 · Хлеб — как готовим',
            style: tt.titleMedium?.copyWith(
                color: AppColors.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Хлеб — любой, что дома; отметь способы, которые в ходу.',
            style: tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in kBreadPreps)
              FilterChip(
                label: Text(p),
                selected: preps.sandwichBreadPreps.contains(p),
                onSelected: (_) => preps.toggleSandwichBreadPrep(p),
                showCheckmark: true,
                checkmarkColor: AppColors.leafDeep,
                labelStyle: tt.labelLarge?.copyWith(
                  color: preps.sandwichBreadPreps.contains(p)
                      ? AppColors.leafDeep
                      : AppColors.onSurface,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        ModulePickerRow(
          label: '2 · Намазка',
          optional: true,
          modules: _byIds(catalog, kSandwichSpreadIds),
          selectedIds: preps.sandwichSpreadIds,
          onTap: (m) => preps.toggleSandwichSpread(m.id),
        ),
        const SizedBox(height: 20),
        ModulePickerRow(
          label: '3 · Сверху',
          optional: true,
          modules: _byIds(catalog, kSandwichToppingIds),
          selectedIds: preps.sandwichFillingIds,
          onTap: (m) => preps.toggleSandwichFilling(m.id),
        ),
      ],
    );
  }
}
