import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/my_dishes.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/theme/module_visuals.dart';
import 'package:modular_chef/widgets/leaf_button.dart';

/// Push-экран Шефа «Мои блюда»: личная библиотека с составом из модулей.
/// Блюда с флагом «готовлю на этой неделе» добавляют состав в покупки.
class MyDishesScreen extends StatelessWidget {
  const MyDishesScreen({super.key});

  static const _composeCats = <(ModuleCategory, String)>[
    (ModuleCategory.protein, 'Белки'),
    (ModuleCategory.side, 'Гарниры'),
    (ModuleCategory.vegetable, 'Овощи'),
    (ModuleCategory.sauce, 'Соусы'),
    (ModuleCategory.breakfast, 'Завтраки'),
  ];

  Future<void> _editDish(BuildContext context, {MyDish? dish}) async {
    final catalog = context.read<CatalogService>();
    final dishes = context.read<MyDishes>();
    final controller = TextEditingController(text: dish?.name ?? '');
    final picked = <String>{...(dish?.moduleIds ?? const [])};

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final tt = Theme.of(ctx).textTheme;
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(dish == null ? 'Новое блюдо' : 'Изменить блюдо',
                          style: tt.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        autofocus: dish == null,
                        decoration: InputDecoration(
                          hintText: 'Например, шакшука с фетой',
                          filled: true,
                          fillColor: AppColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Состав (по нему блюдо попадёт в список покупок):',
                        style: tt.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      for (final (cat, label) in _composeCats) ...[
                        Builder(builder: (_) {
                          final mods = catalog.modulesByCategory(cat);
                          if (mods.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(label.toUpperCase(),
                                  style: tt.labelSmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  )),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final m in mods)
                                    InkWell(
                                      onTap: () => setSheet(() {
                                        picked.contains(m.id)
                                            ? picked.remove(m.id)
                                            : picked.add(m.id);
                                      }),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: picked.contains(m.id)
                                              ? AppColors.primaryContainer
                                              : AppColors.surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(m.name,
                                            style: tt.labelLarge?.copyWith(
                                              color: picked.contains(m.id)
                                                  ? AppColors
                                                      .onPrimaryContainer
                                                  : AppColors
                                                      .onSurfaceVariant,
                                              fontWeight:
                                                  picked.contains(m.id)
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                            )),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        }),
                      ],
                      const SizedBox(height: 20),
                      LeafButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        label: dish == null ? 'Добавить блюдо' : 'Сохранить',
                        height: 48,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    final name = controller.text.trim();
    if (saved != true || name.isEmpty) return;
    if (dish == null) {
      dishes.add(MyDish(name: name, moduleIds: picked.toList()));
    } else {
      dishes.update(dish, name: name, moduleIds: picked.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dishes = context.watch<MyDishes>();
    final catalog = context.watch<CatalogService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои блюда'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        onPressed: () => _editDish(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'БИБЛИОТЕКА РЕЦЕПТОВ',
            style: tt.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ваша коллекция',
            style: tt.displaySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          if (dishes.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text('Добавьте своё блюдо',
                      style: tt.titleMedium?.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'Укажи состав из продуктов — блюдо само попадёт в список покупок, когда отметишь «готовлю на этой неделе».',
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: AppColors.onSecondaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final d in dishes.items) ...[
              _MyDishCard(
                dish: d,
                catalog: catalog,
                onEdit: () => _editDish(context, dish: d),
                onDelete: () => dishes.remove(d),
                onWeekToggle: (v) =>
                    dishes.update(d, cookThisWeek: v),
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}

class _MyDishCard extends StatelessWidget {
  const _MyDishCard({
    required this.dish,
    required this.catalog,
    required this.onEdit,
    required this.onDelete,
    required this.onWeekToggle,
  });
  final MyDish dish;
  final CatalogService catalog;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onWeekToggle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mods = [
      for (final id in dish.moduleIds)
        if (catalog.moduleById(id) != null) catalog.moduleById(id)!,
    ];

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowTint,
                blurRadius: 24,
                offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(dish.name,
                    style: tt.titleLarge?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700)),
              ),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.delete_outline,
                      size: 20, color: AppColors.onSurfaceVariant),
                ),
              ),
            ]),
            if (mods.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in mods)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (moduleImage(m.id) != null) ...[
                            Image.asset(moduleImage(m.id)!,
                                width: 18, height: 18),
                            const SizedBox(width: 5),
                          ],
                          Text(m.name,
                              style: tt.labelMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text('Состав не указан — тапни, чтобы добавить.',
                  style: tt.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text('Готовлю на этой неделе',
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.onSurface)),
              ),
              Switch(
                value: dish.cookThisWeek,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryContainer,
                onChanged: onWeekToggle,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
