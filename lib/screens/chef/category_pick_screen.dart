import 'package:flutter/material.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/widgets/leaf_button.dart';
import 'package:modular_chef/widgets/module_picker_row.dart';

/// Под-экран выбора внутри категории («Мясо», «Рыба», «Крупы»…):
/// сетка акварельных плиток, множественный выбор, «Готово» возвращает набор.
class CategoryPickScreen extends StatefulWidget {
  const CategoryPickScreen({
    super.key,
    required this.title,
    required this.modules,
    required this.initiallySelected,
    this.hint,
    this.detailScreenOf,
    this.detailSummaryOf,
  });

  final String title;
  final List<Module> modules;
  final Set<String> initiallySelected;
  final String? hint;

  /// Экран настройки для позиций с опциями (яйца → виды и добавки).
  /// Выбор такой позиции сразу открывает её настройку — как опции у пиццы.
  final Widget? Function(Module)? detailScreenOf;

  /// Живая сводка настройки («2 вида · 3 добавки») — подпись на плитке.
  final String? Function(BuildContext, Module)? detailSummaryOf;

  @override
  State<CategoryPickScreen> createState() => _CategoryPickScreenState();
}

class _CategoryPickScreenState extends State<CategoryPickScreen> {
  late final Set<String> _selected = {...widget.initiallySelected};

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _selected),
        ),
      ),
      body: Column(
        children: [
          if (widget.hint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.hint!,
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant)),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: widget.modules.length,
                  itemBuilder: (context, i) {
                    final m = widget.modules[i];
                    final detail = widget.detailScreenOf?.call(m);
                    return ModuleTile(
                      module: m,
                      selected: _selected.contains(m.id),
                      caption: _selected.contains(m.id)
                          ? widget.detailSummaryOf?.call(context, m)
                          : null,
                      onTap: () async {
                        if (_selected.contains(m.id)) {
                          setState(() => _selected.remove(m.id));
                          return;
                        }
                        setState(() => _selected.add(m.id));
                        // Есть опции — сразу открываем их настройку.
                        if (detail != null && context.mounted) {
                          await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => detail));
                          if (mounted) setState(() {});
                        }
                      },
                    );
                  },
                ),
                // Настройка выбранных позиций с опциями — не снимая выбор.
                if (widget.detailScreenOf != null) ...[
                  const SizedBox(height: 16),
                  for (final m in widget.modules)
                    if (_selected.contains(m.id) &&
                        widget.detailScreenOf?.call(m) != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Builder(builder: (context) {
                          final tt = Theme.of(context).textTheme;
                          final summary =
                              widget.detailSummaryOf?.call(context, m);
                          return InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        widget.detailScreenOf!.call(m)!),
                              );
                              if (mounted) setState(() {});
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Text(
                                    'Настроить: ${m.name}'
                                    '${summary != null && summary.isNotEmpty ? ' · $summary' : ''}',
                                    style: tt.titleSmall?.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    size: 20,
                                    color: AppColors.onSurfaceVariant),
                              ]),
                            ),
                          );
                        }),
                      ),
                ],
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
            onPressed: () => Navigator.pop(context, _selected),
            label: _selected.isEmpty
                ? 'Готово'
                : 'Готово · выбрано ${_selected.length}',
            height: 52,
          ),
        ),
      ),
    );
  }
}
