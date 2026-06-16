import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Шеф-экран «День заготовки» — теперь из каталога и на все типы:
/// Шаг 1 — выбор способа для белков/гарниров/овощей/супов (+ детали и хранение);
/// Шаг 2 — план заготовки из выбранного.
class PrepScreen extends StatefulWidget {
  const PrepScreen({super.key});

  @override
  State<PrepScreen> createState() => _PrepScreenState();
}

class _PrepScreenState extends State<PrepScreen> {
  int _step = 0;

  /// moduleId → выбранный способ приготовления.
  final Map<String, String> _method = {};

  static const _prepCategories = <(ModuleCategory, String)>[
    (ModuleCategory.protein, 'Белки'),
    (ModuleCategory.side, 'Гарниры'),
    (ModuleCategory.vegetable, 'Овощи'),
    (ModuleCategory.soup, 'Супы'),
  ];

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: !catalog.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : (_step == 0 ? _buildStep1(context, catalog) : _buildStep2(context, catalog)),
    );
  }

  Widget _buildStep1(BuildContext context, CatalogService catalog) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                _StepBadge(text: 'ШАГ 1 из 2', active: true),
                SizedBox(width: 8),
                _StepBadge(text: 'ШАГ 2', active: false),
              ]),
              const SizedBox(height: 16),
              Text('Способ приготовления',
                  style: tt.headlineMedium?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Выбери способ и загляни в детали — как готовить и где хранить.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            children: [
              for (final (cat, label) in _prepCategories) ...[
                Builder(builder: (_) {
                  final items = catalog
                      .modulesByCategory(cat)
                      .where((m) => m.methods.isNotEmpty)
                      .toList();
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: tt.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      for (final m in items) ...[
                        _PrepItem(
                          module: m,
                          selected: _method[m.id],
                          onPick: (method) => setState(() => _method[m.id] = method),
                          onInfo: () => _showDetail(context, m),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 12),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => setState(() => _step = 1),
                icon: const Icon(Icons.arrow_forward),
                label: Text(_method.isEmpty
                    ? 'Продолжить'
                    : 'Продолжить · выбрано ${_method.length}'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context, CatalogService catalog) {
    final tt = Theme.of(context).textTheme;
    final entries = _method.entries
        .map((e) => (module: catalog.moduleById(e.key), method: e.value))
        .where((x) => x.module != null)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                TextButton.icon(
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Шаг 1'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                ),
                const Spacer(),
                const _StepBadge(text: 'ШАГ 1', active: false),
                const SizedBox(width: 8),
                const _StepBadge(text: 'ШАГ 2 из 2', active: true),
              ]),
              const SizedBox(height: 16),
              Text('План заготовки',
                  style: tt.headlineMedium?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                entries.isEmpty
                    ? 'Вернись на шаг 1 и выбери способы приготовления.'
                    : 'Готовь по порядку, раскладывай по контейнерам.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                _PlanStep(index: i + 1, module: entries[i].module!, method: entries[i].method),
                const SizedBox(height: 10),
              ],
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    const Text('🧼', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Подготовь контейнеры заранее — сэкономит 10 минут в конце.',
                        style: tt.bodyMedium?.copyWith(
                            color: AppColors.onTertiaryContainer,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, Module m) {
    final tt = Theme.of(context).textTheme;
    final zone = m.storage.zone;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(m.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(m.name,
                    style: tt.titleLarge?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 14),
              Text('СПОСОБЫ',
                  style: tt.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4)),
              const SizedBox(height: 6),
              for (final method in m.methods)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    const Icon(Icons.local_fire_department_outlined,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(method, style: tt.bodyLarge?.copyWith(color: AppColors.onSurface)),
                  ]),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(zone.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('${zone.label} · до ${m.storage.days} дн.',
                          style: tt.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600)),
                    ]),
                    if (m.storage.tip.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(m.storage.tip,
                          style: tt.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.text, required this.active});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: tt.labelSmall?.copyWith(
            color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          )),
    );
  }
}

class _PrepItem extends StatelessWidget {
  const _PrepItem({
    required this.module,
    required this.selected,
    required this.onPick,
    required this.onInfo,
  });
  final Module module;
  final String? selected;
  final ValueChanged<String> onPick;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(module.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(module.name,
                  style: tt.titleSmall?.copyWith(
                      color: AppColors.onSurface, fontWeight: FontWeight.w700)),
            ),
            InkWell(
              onTap: onInfo,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.info_outline, size: 18, color: AppColors.onSurfaceVariant),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in module.methods)
                _MethodChip(
                  label: method,
                  selected: method == selected,
                  onTap: () => onPick(method),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: tt.labelLarge?.copyWith(
              color: selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({required this.index, required this.module, required this.method});
  final int index;
  final Module module;
  final String method;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final zone = module.storage.zone;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$index',
                style: tt.labelMedium?.copyWith(
                    color: AppColors.onPrimaryContainer, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${module.emoji} ${module.name}',
                    style: tt.bodyLarge?.copyWith(
                        color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(method, style: tt.bodyMedium?.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('${zone.emoji} ${zone.label} · до ${module.storage.days} дн.',
                    style: tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
