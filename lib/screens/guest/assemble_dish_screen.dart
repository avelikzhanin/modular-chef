import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/today_plan.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Гостевая активная сборка тарелки из запасов под конкретный слот.
/// main → белок(+гарнир+овощ+соус); завтрак/перекус → одно блюдо.
class AssembleDishScreen extends StatefulWidget {
  const AssembleDishScreen({super.key, required this.slot});
  final MealSlot slot;

  @override
  State<AssembleDishScreen> createState() => _AssembleDishScreenState();
}

class _AssembleDishScreenState extends State<AssembleDishScreen> {
  final Map<MealRole, Module> _picked = {};

  MealKind get _kind => switch (widget.slot) {
        MealSlot.breakfast => MealKind.breakfast,
        MealSlot.snack => MealKind.snack,
        MealSlot.lunch || MealSlot.dinner => MealKind.main,
      };

  bool get _isMain => _kind == MealKind.main;

  bool get _ready => _isMain
      ? _picked.containsKey(MealRole.protein)
      : _picked.containsKey(MealRole.standalone);

  void _toggle(MealRole role, Module m) {
    setState(() {
      if (_picked[role]?.id == m.id) {
        _picked.remove(role);
      } else {
        _picked[role] = m;
      }
    });
  }

  void _done(BuildContext context) {
    final order = _isMain
        ? [MealRole.protein, MealRole.side, MealRole.vegetable, MealRole.sauce]
        : [MealRole.standalone];
    final components = <MealComponent>[];
    for (final role in order) {
      final m = _picked[role];
      if (m != null) {
        components.add(MealComponent(
            moduleId: m.id, role: role, name: m.name, emoji: m.emoji));
      }
    }
    final protein = _picked[MealRole.protein] ?? _picked[MealRole.standalone];
    final meal = PlannedMeal(
      title: PlannedMeal.titleFrom(components, _kind),
      kind: _kind,
      components: components,
      reheatMinutes: _isMain ? 2 : 0,
      fromContainer: protein != null ? _containerFor(protein) : '',
    );
    context.read<TodayPlan>().setMeal(widget.slot, meal);
    Navigator.maybePop(context);
  }

  String _containerFor(Module m) => switch (m.storage.zone.jsonValue) {
        'fridge' => 'холодильник',
        'freezer' => 'морозилка',
        'vacuum' => 'вакуум',
        'pantry' => 'кладовая',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catalog = context.watch<CatalogService>();

    final sections = _isMain
        ? const [
            (MealRole.protein, ModuleCategory.protein, 'Белок'),
            (MealRole.side, ModuleCategory.side, 'Гарнир'),
            (MealRole.vegetable, ModuleCategory.vegetable, 'Овощ'),
            (MealRole.sauce, ModuleCategory.sauce, 'Соус'),
          ]
        : [
            (
              MealRole.standalone,
              widget.slot == MealSlot.breakfast
                  ? ModuleCategory.breakfast
                  : ModuleCategory.snack,
              'Выбери'
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Собрать: ${widget.slot.label.toLowerCase()}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: !catalog.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
              children: [
                Text(
                  _isMain
                      ? 'Собери тарелку из того, что есть'
                      : 'Выбери из запасов',
                  style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                for (final (role, category, label) in sections) ...[
                  _Section(
                    label: label,
                    optional: _isMain && role != MealRole.protein,
                    modules: catalog.modulesByCategory(category),
                    selectedId: _picked[role]?.id,
                    onTap: (m) => _toggle(role, m),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
      bottomSheet: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_picked.isNotEmpty) ...[
                Text(
                  _picked.values.map((m) => m.name).join(' + '),
                  style: tt.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (_isMain)
                  Text('Совет: держи один вкусовой профиль в тарелке',
                      style: tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _ready ? () => _done(context) : null,
                  child: const Text('Готово'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.optional,
    required this.modules,
    required this.selectedId,
    required this.onTap,
  });
  final String label;
  final bool optional;
  final List<Module> modules;
  final String? selectedId;
  final ValueChanged<Module> onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: tt.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 8),
              Text('по желанию',
                  style: tt.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modules.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final m = modules[i];
              final selected = m.id == selectedId;
              return InkWell(
                onTap: () => onTap(m),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                    border: selected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m.emoji, style: const TextStyle(fontSize: 26)),
                          if (selected)
                            const Icon(Icons.check_circle,
                                size: 18, color: AppColors.primary),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        m.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelMedium?.copyWith(
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
            },
          ),
        ),
      ],
    );
  }
}
