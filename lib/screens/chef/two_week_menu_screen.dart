import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/active_menu.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/preferences.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Push-экран Шефа «Меню на 2 недели» — полные тарелки + три уровня правки:
/// предпочтения (подсветка, Stage 12), обзор по компонентам (батч) и точечная.
class TwoWeekMenuScreen extends StatefulWidget {
  const TwoWeekMenuScreen({super.key});

  @override
  State<TwoWeekMenuScreen> createState() => _TwoWeekMenuScreenState();
}

class _TwoWeekMenuScreenState extends State<TwoWeekMenuScreen> {
  int _weekIndex = 0;

  // роль компонента → категория каталога для подбора альтернатив
  ModuleCategory _categoryFor(MealRole role, MealKind kind) {
    switch (role) {
      case MealRole.protein:
        return ModuleCategory.protein;
      case MealRole.side:
      case MealRole.base:
        return ModuleCategory.side;
      case MealRole.vegetable:
        return ModuleCategory.vegetable;
      case MealRole.sauce:
        return ModuleCategory.sauce;
      case MealRole.standalone:
        return switch (kind) {
          MealKind.breakfast => ModuleCategory.breakfast,
          MealKind.soup => ModuleCategory.soup,
          MealKind.snack => ModuleCategory.snack,
          MealKind.main => ModuleCategory.protein,
        };
    }
  }

  MealComponent _toComponent(Module m, MealRole role) =>
      MealComponent(moduleId: m.id, role: role, name: m.name, emoji: m.emoji);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final active = context.watch<ActiveMenu>();
    final menu = active.menu;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Меню на 2 недели'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: menu == null
          ? _EmptyState(status: active.status, error: active.error)
          : _buildContent(context, tt, menu),
      bottomSheet: menu == null
          ? null
          : Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Меню утверждено — дальше «Список покупок»',
                            style: tt.bodyMedium?.copyWith(color: AppColors.onPrimary),
                          ),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.maybePop(context);
                    },
                    child: const Text('Утвердить'),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildContent(BuildContext context, TextTheme tt, WeeklyMenu menu) {
    final week = menu.weeks[_weekIndex];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        _WeekTabs(index: _weekIndex, onChanged: (i) => setState(() => _weekIndex = i)),
        const SizedBox(height: 16),
        _PrefsChips(chips: context.watch<Preferences>().appliedChips),
        _Badge(summary: menu.summary),
        const SizedBox(height: 16),
        _ComponentOverview(
          week: week,
          onBatchSwap: (role, fromId) => _openBatchSwap(context, role, fromId),
        ),
        const SizedBox(height: 20),
        for (int i = 0; i < week.days.length; i++) ...[
          _DayCard(
            day: week.days[i],
            onEditMeal: (slot) => _openMealEditor(context, i, slot),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // Точечная правка: выбрать компонент → выбрать замену.
  Future<void> _openMealEditor(BuildContext context, int dayIdx, MealSlot slot) async {
    final active = context.read<ActiveMenu>();
    final meal = active.menu!.weeks[_weekIndex].days[dayIdx].mealAt(slot);
    if (meal == null || meal.components.isEmpty) return;

    final comp = await showModalBottomSheet<MealComponent>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PickList<MealComponent>(
        title: meal.title,
        subtitle: 'Что заменить?',
        items: meal.components,
        labelOf: (c) => '${c.emoji} ${c.role.label}: ${c.name}',
        valueOf: (c) => c,
      ),
    );
    if (comp == null || !context.mounted) return;

    final catalog = context.read<CatalogService>();
    final category = _categoryFor(comp.role, meal.kind);
    final options = catalog.modulesByCategory(category);
    final chosen = await _pickModule(context, options, 'Заменить «${comp.name}»');
    if (chosen == null || !context.mounted) return;

    active.swapComponentInMeal(
      weekIndex: _weekIndex,
      dayIndex: dayIdx,
      slot: slot,
      component: _toComponent(chosen, comp.role),
    );
  }

  // Батч: заменить модуль во всех тарелках недели.
  Future<void> _openBatchSwap(BuildContext context, MealRole role, String fromModuleId) async {
    final catalog = context.read<CatalogService>();
    final from = catalog.moduleById(fromModuleId);
    final category = _categoryFor(role, MealKind.main);
    final options = catalog.modulesByCategory(category).where((m) => m.id != fromModuleId).toList();
    final chosen = await _pickModule(
      context,
      options,
      'Заменить «${from?.name ?? fromModuleId}» везде',
    );
    if (chosen == null || !context.mounted) return;
    context.read<ActiveMenu>().swapModuleEverywhere(
          weekIndex: _weekIndex,
          fromModuleId: fromModuleId,
          to: _toComponent(chosen, role),
        );
  }

  Future<Module?> _pickModule(
      BuildContext context, List<Module> options, String title) {
    return showModalBottomSheet<Module>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PickList<Module>(
        title: title,
        subtitle: 'Совет: держи один вкусовой профиль в тарелке',
        items: options,
        labelOf: (m) => '${m.emoji} ${m.name}',
        valueOf: (m) => m,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status, this.error});
  final MenuStatus status;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final text = switch (status) {
      MenuStatus.generating => 'Собираем меню…',
      MenuStatus.error => 'Не удалось собрать меню: $error',
      _ => 'Сначала выберите ингредиенты на «Меню» и нажмите «Собрать меню»',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == MenuStatus.generating)
              const CircularProgressIndicator()
            else
              Icon(
                status == MenuStatus.error
                    ? Icons.error_outline
                    : Icons.restaurant_menu_outlined,
                size: 48,
                color: AppColors.onSurfaceVariant,
              ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: tt.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _WeekTabs extends StatelessWidget {
  const _WeekTabs({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    Widget pill(int i, String label) {
      final selected = i == index;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(i),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: tt.labelLarge?.copyWith(
                color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: [pill(0, 'Неделя 1'), pill(1, 'Неделя 2')]),
    );
  }
}

/// Подсветка учтённых предпочтений над меню.
class _PrefsChips extends StatelessWidget {
  const _PrefsChips({required this.chips});
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Учтено:',
              style: tt.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          for (final c in chips)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$c ✓',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  )),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.summary});
  final MenuSummary summary;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: tt.bodyMedium?.copyWith(color: AppColors.onPrimaryContainer, height: 1.4),
                children: [
                  TextSpan(
                    text: '${summary.uniqueDishes} уникальных блюд',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ' из ${summary.modulesUsed} модулей · ${summary.totalMeals} приёмов',
                    style: TextStyle(
                      color: AppColors.onPrimaryContainer.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Обзор по компонентам: сколько каких гарниров/овощей/соусов в неделе.
/// Тап по модулю → батч-замена везде.
class _ComponentOverview extends StatelessWidget {
  const _ComponentOverview({required this.week, required this.onBatchSwap});
  final MenuWeek week;
  final void Function(MealRole role, String fromModuleId) onBatchSwap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    // role → (moduleId → (name, count))
    final stats = <MealRole, Map<String, ({String name, int count})>>{};
    for (final day in week.days) {
      for (final meal in [day.breakfast, day.lunch, day.dinner, day.snack]) {
        if (meal == null) continue;
        for (final c in meal.components) {
          if (c.role == MealRole.standalone) continue; // только составные роли
          final byId = stats.putIfAbsent(c.role, () => {});
          final cur = byId[c.moduleId];
          byId[c.moduleId] = (name: c.name, count: (cur?.count ?? 0) + 1);
        }
      }
    }
    if (stats.isEmpty) return const SizedBox.shrink();

    const order = [MealRole.protein, MealRole.side, MealRole.vegetable, MealRole.sauce];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Обзор меню — тап, чтобы заменить пачкой',
            style: tt.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          for (final role in order)
            if (stats[role] != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 78,
                      child: Text(
                        role.label,
                        style: tt.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in stats[role]!.entries)
                            InkWell(
                              onTap: () => onBatchSwap(role, e.key),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${e.value.name} ×${e.value.count}',
                                  style: tt.labelMedium?.copyWith(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.onEditMeal});
  final DayPlan day;
  final ValueChanged<MealSlot> onEditMeal;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final meals = <(MealSlot, PlannedMeal)>[
      (MealSlot.breakfast, day.breakfast),
      (MealSlot.lunch, day.lunch),
      (MealSlot.dinner, day.dinner),
      if (day.snack != null) (MealSlot.snack, day.snack!),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.shortName.toUpperCase(),
            style: tt.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < meals.length; i++) ...[
            _MealRow(slot: meals[i].$1, meal: meals[i].$2, onTap: () => onEditMeal(meals[i].$1)),
            if (i < meals.length - 1) const Divider(height: 18, color: Colors.transparent),
          ],
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.slot, required this.meal, required this.onTap});
  final MealSlot slot;
  final PlannedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(slot.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.title,
                    style: tt.bodyLarge?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (meal.components.length > 1) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final c in meal.components)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${c.emoji} ${c.name}',
                              style: tt.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.tune, size: 16, color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

/// Универсальный bottom-sheet выбора из списка.
class _PickList<T> extends StatelessWidget {
  const _PickList({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.labelOf,
    required this.valueOf,
  });
  final String title;
  final String subtitle;
  final List<T> items;
  final String Function(T) labelOf;
  final T Function(T) valueOf;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: tt.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: tt.bodySmall),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in items)
                      InkWell(
                        onTap: () => Navigator.pop(context, valueOf(item)),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            labelOf(item),
                            style: tt.labelLarge?.copyWith(
                              color: AppColors.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
