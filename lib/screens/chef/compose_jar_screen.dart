import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/meal_hints.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/widgets/leaf_button.dart';
import 'package:modular_chef/widgets/module_picker_row.dart';

/// Сборка одной банки Шефом: 4 слоя снизу вверх + живые подсказки.
/// Возвращает собранную банку как [PlannedMeal] (kind breakfast) через pop.
class ComposeJarScreen extends StatefulWidget {
  const ComposeJarScreen({super.key});

  @override
  State<ComposeJarScreen> createState() => _ComposeJarScreenState();
}

class _ComposeJarScreenState extends State<ComposeJarScreen> {
  Module? _base, _barrier, _middle, _top;

  bool get _ready => _base != null;

  void _save() {
    final comps = <MealComponent>[
      _comp(_base!, MealRole.jarBase),
      if (_barrier != null) _comp(_barrier!, MealRole.jarBarrier),
      if (_middle != null) _comp(_middle!, MealRole.jarMiddle),
      if (_top != null) _comp(_top!, MealRole.jarTop),
    ];
    final tail = [_middle?.name, _top?.name]
        .whereType<String>()
        .map((s) => s.toLowerCase())
        .join(', ');
    final jar = PlannedMeal(
      title: tail.isEmpty ? _base!.name : '${_base!.name} · $tail',
      kind: MealKind.breakfast,
      components: comps,
      fromContainer: 'холодильник',
    );
    Navigator.pop(context, jar);
  }

  MealComponent _comp(Module m, MealRole role) =>
      MealComponent(moduleId: m.id, role: role, name: m.name, emoji: m.emoji);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catalog = context.watch<CatalogService>();

    final layers = <(MealRole, ModuleCategory, String, bool, Module?)>[
      (MealRole.jarBase, ModuleCategory.jarBase, '1 · Основа', false, _base),
      (MealRole.jarBarrier, ModuleCategory.jarBarrier, '2 · Прокладка', true, _barrier),
      (MealRole.jarMiddle, ModuleCategory.jarMiddle, '3 · Сочный слой', true, _middle),
      (MealRole.jarTop, ModuleCategory.jarTop, '4 · Хруст / декор', true, _top),
    ];

    void setLayer(MealRole role, Module m) => setState(() {
          switch (role) {
            case MealRole.jarBase:
              _base = _base?.id == m.id ? null : m;
            case MealRole.jarBarrier:
              _barrier = _barrier?.id == m.id ? null : m;
            case MealRole.jarMiddle:
              _middle = _middle?.id == m.id ? null : m;
            default:
              _top = _top?.id == m.id ? null : m;
          }
        });

    final hints = MealHints.jar(
      base: _base,
      barrier: _barrier,
      middle: _middle,
      top: _top,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Собрать банку'),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('Слои снизу вверх — не перемешиваются при хранении',
                      style: tt.bodySmall
                          ?.copyWith(color: AppColors.onPrimaryContainer)),
                ),
                for (final (role, category, label, optional, picked) in layers) ...[
                  ModulePickerRow(
                    label: label,
                    optional: optional,
                    modules: catalog.modulesByCategory(category),
                    selectedIds: {if (picked != null) picked.id},
                    onTap: (m) => setLayer(role, m),
                  ),
                  const SizedBox(height: 20),
                ],
                if (hints.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final h in hints)
                          MealHintTile(text: h.text, positive: h.positive),
                      ],
                    ),
                  ),
              ],
            ),
      bottomSheet: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: LeafButton(
            onPressed: _ready ? _save : null,
            label: 'Сохранить банку',
          ),
        ),
      ),
    );
  }
}
