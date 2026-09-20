import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/screens/chef/compose_jar_screen.dart';
import 'package:modular_chef/services/breakfast_preps.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/theme/module_visuals.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/widgets/leaf_button.dart';
import 'package:modular_chef/widgets/module_picker_row.dart';

/// Экран Шефа: банки впрок и яйца к завтраку. Из этого Гость потом собирает
/// завтрак (берёт готовую банку / жарит выбранные яйца).
///
/// Один класс на два входа. Из Профиля открывается целиком, а из настройки
/// типа «Баночка» в сборщике меню секция яиц гасится [showEggs]: там она не к
/// месту и выглядит как часть банки.
class BreakfastPrepsScreen extends StatelessWidget {
  const BreakfastPrepsScreen({super.key, this.showEggs = true});

  final bool showEggs;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catalog = context.watch<CatalogService>();
    final preps = context.watch<BreakfastPreps>();

    return Scaffold(
      appBar: AppBar(
        title: Text(showEggs ? 'Заготовки завтраков' : 'Баночки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: !catalog.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  showEggs
                      ? 'Что заготовишь к завтракам — из этого Гость и соберёт.'
                      : 'Собери банки впрок — утром Гость просто возьмёт готовую.',
                  style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // --- Банки ---
                Row(
                  children: [
                    const Text('🥣', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('Мои банки',
                        style: tt.titleLarge?.copyWith(
                            color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                if (preps.jars.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Image.asset('assets/art/empty_jar.png', width: 130),
                        const SizedBox(height: 6),
                        Text(
                          'Тут пока пусто — собери первую банку, и Гостю будет что взять.',
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                for (int i = 0; i < preps.jars.length; i++) ...[
                  _JarCard(
                    jar: preps.jars[i],
                    onRemove: () =>
                        context.read<BreakfastPreps>().removeJarAt(i),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                LeafButton(
                  onPressed: () async {
                    final jar = await Navigator.push<PlannedMeal>(
                      context,
                      MaterialPageRoute(builder: (_) => const ComposeJarScreen()),
                    );
                    if (jar != null && context.mounted) {
                      context.read<BreakfastPreps>().addJar(jar);
                    }
                  },
                  height: 48,
                  child: Builder(builder: (context) {
                    final tt = Theme.of(context).textTheme;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add,
                            size: 20, color: AppColors.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text('Собрать банку',
                            style: tt.titleMedium?.copyWith(
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w600)),
                      ],
                    );
                  }),
                ),
                if (showEggs) ...[
                  const SizedBox(height: 32),

                  // --- Яйца ---
                  Row(
                    children: [
                      const Text('🍳', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text('Яйца на завтрак',
                          style: tt.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      'Что будешь готовить и что к этому купить — '
                      'утром Гость сам достанет добавки из холодильника.',
                      style: tt.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  ModulePickerRow(
                    label: 'Виды яиц',
                    optional: false,
                    modules: catalog.modulesByCategory(ModuleCategory.eggStyle),
                    selectedIds: preps.eggStyleIds,
                    onTap: (m) =>
                        context.read<BreakfastPreps>().toggleEggStyle(m.id),
                  ),
                  const SizedBox(height: 20),
                  ModulePickerRow(
                    label: 'Добавки к яйцам',
                    optional: true,
                    modules: catalog.modulesByCategory(ModuleCategory.eggAddin),
                    selectedIds: preps.eggAddinIds,
                    onTap: (m) =>
                        context.read<BreakfastPreps>().toggleEggAddin(m.id),
                  ),
                ],
              ],
            ),
    );
  }
}

class _JarCard extends StatelessWidget {
  const _JarCard({required this.jar, required this.onRemove});
  final PlannedMeal jar;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jar.title,
                    style: tt.titleMedium?.copyWith(
                        color: AppColors.onSurface, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in jar.components)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (moduleImage(c.moduleId) != null) ...[
                              Image.asset(moduleImage(c.moduleId)!,
                                  width: 16, height: 16),
                              const SizedBox(width: 4),
                            ],
                            Text(c.name,
                                style: tt.labelSmall?.copyWith(
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.onSurfaceVariant,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
