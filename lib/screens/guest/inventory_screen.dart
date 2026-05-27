import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Гостевой экран «Запасы» — модули из CatalogService, сгруппированные
/// по категориям (Белки / Гарниры / Овощи / Соусы). Count и suggestion —
/// пока mock-эвристика; Stage 3+ заменит на реальные остатки из БД.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

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
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
                  children: [
                    Text(
                      'Что есть в запасе',
                      style: tt.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Собери своё блюдо из готовых модулей',
                      style: tt.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    const _SuggestionBanner(
                      primary: 'Свежий салат заканчивается завтра. Попробуй:',
                      secondary: 'курица + салат + лимонная заправка',
                    ),
                    const SizedBox(height: 36),
                    _CategorySection(
                      title: 'Белки',
                      meta: '${catalog.modulesByCategory(ModuleCategory.protein).length} вариантов',
                      modules: catalog.modulesByCategory(ModuleCategory.protein),
                    ),
                    const SizedBox(height: 32),
                    _CategorySection(
                      title: 'Гарниры',
                      meta: 'Долгого хранения',
                      modules: catalog.modulesByCategory(ModuleCategory.side),
                    ),
                    const SizedBox(height: 32),
                    _CategorySection(
                      title: 'Овощи',
                      trailingIcon: Icons.eco,
                      modules: catalog.modulesByCategory(ModuleCategory.vegetable),
                      layout: _Layout.list,
                    ),
                    const SizedBox(height: 32),
                    _CategorySection(
                      title: 'Соусы',
                      modules: catalog.modulesByCategory(ModuleCategory.sauce),
                      layout: _Layout.chips,
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _AssemblyBar(
                    summary: 'Курица + рис + йогуртовый соус',
                    onAssemble: () => context.push(Routes.guestAssembleDish),
                  ),
                ),
              ],
            ),
    );
  }
}

enum _Layout { grid, list, chips }

class _SuggestionBanner extends StatelessWidget {
  const _SuggestionBanner({required this.primary, required this.secondary});
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.onPrimaryContainer,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '$primary\n',
                    style: TextStyle(
                      color:
                          AppColors.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  TextSpan(text: secondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.modules,
    this.meta,
    this.trailingIcon,
    this.layout = _Layout.grid,
  });
  final String title;
  final List<Module> modules;
  final String? meta;
  final IconData? trailingIcon;
  final _Layout layout;

  /// Псевдо-count для дем-показа — стабильный по id, диапазон 2–5.
  int _count(Module m) => 2 + (m.id.hashCode.abs() % 4);

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
            if (meta != null)
              Text(
                meta!.toUpperCase(),
                style: tt.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: AppColors.primary, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        switch (layout) {
          _Layout.grid => _GridLayout(modules: modules, countFor: _count),
          _Layout.list => _ListLayout(modules: modules, countFor: _count),
          _Layout.chips => _ChipsLayout(modules: modules, countFor: _count),
        },
      ],
    );
  }
}

class _GridLayout extends StatelessWidget {
  const _GridLayout({required this.modules, required this.countFor});
  final List<Module> modules;
  final int Function(Module) countFor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final m in modules)
          SizedBox(
            width: (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2,
            child: _ModuleCard(module: m, count: countFor(m)),
          ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.count});
  final Module module;
  final int count;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint,
              blurRadius: 32,
              offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(module.emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  module.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListLayout extends StatelessWidget {
  const _ListLayout({required this.modules, required this.countFor});
  final List<Module> modules;
  final int Function(Module) countFor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final m in modules)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Text(
                        m.name,
                        style: tt.bodyLarge?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${countFor(m)}',
                    style: tt.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ChipsLayout extends StatelessWidget {
  const _ChipsLayout({required this.modules, required this.countFor});
  final List<Module> modules;
  final int Function(Module) countFor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (int i = 0; i < modules.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: i == 0
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.shadowTint,
                    blurRadius: 32,
                    offset: Offset(0, 12)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(modules[i].emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  modules[i].name,
                  style: tt.bodyMedium?.copyWith(
                    color: i == 0
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${countFor(modules[i])}',
                  style: tt.labelSmall?.copyWith(
                    color: (i == 0
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurface)
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AssemblyBar extends StatelessWidget {
  const _AssemblyBar({required this.summary, required this.onAssemble});
  final String summary;
  final VoidCallback onAssemble;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint,
              blurRadius: 32,
              offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ВАША СБОРКА',
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: tt.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.close, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onAssemble,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
              textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Собрать'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
