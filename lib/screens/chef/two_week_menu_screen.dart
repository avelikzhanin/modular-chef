import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/active_menu.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Push-экран Шефа «Меню на 2 недели» — читает реальное сгенерированное
/// меню из ActiveMenu. Замена блюда обновляет провайдер, «Утвердить» —
/// SnackBar и возврат (persistence — Stage 4 / БД).
class TwoWeekMenuScreen extends StatefulWidget {
  const TwoWeekMenuScreen({super.key});

  @override
  State<TwoWeekMenuScreen> createState() => _TwoWeekMenuScreenState();
}

class _TwoWeekMenuScreenState extends State<TwoWeekMenuScreen> {
  int _weekIndex = 0;

  static const _alternatives = <String>[
    'Курица гриль + рис',
    'Лосось + булгур + лимон',
    'Стейк + спагетти',
    'Треска + киноа',
    'Креветки + рис',
    'Индейка + гречка',
    'Тунец + салат',
  ];

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
                            'Меню утверждено — следующий шаг: «Список покупок»',
                            style: tt.bodyMedium?.copyWith(color: AppColors.onPrimary),
                          ),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.maybePop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const StadiumBorder(),
                      textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        _WeekTabs(
          index: _weekIndex,
          onChanged: (i) => setState(() => _weekIndex = i),
        ),
        const SizedBox(height: 16),
        _Badge(summary: menu.summary),
        const SizedBox(height: 20),
        for (int i = 0; i < week.days.length; i++) ...[
          _DayBlock(
            day: week.days[i],
            onReplace: (slot) => _replaceMeal(context, i, slot),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _replaceMeal(
      BuildContext context, int dayIdx, MealSlot slot) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReplaceSheet(alternatives: _alternatives),
    );
    if (picked == null || !context.mounted) return;
    final active = context.read<ActiveMenu>();
    final current = active.menu!.weeks[_weekIndex].days[dayIdx].mealAt(slot);
    active.replaceMeal(
      weekIndex: _weekIndex,
      dayIndex: dayIdx,
      slot: slot,
      replacement: PlannedMeal(
        title: picked,
        moduleIds: current.moduleIds,
        reheatMinutes: current.reheatMinutes,
        fromContainer: current.fromContainer,
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
      _ => 'Сначала выберите ингредиенты на экране «Меню» и нажмите «Собрать меню»',
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
              color: selected
                  ? AppColors.surfaceContainerLowest
                  : Colors.transparent,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.summary});
  final MenuSummary summary;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.onPrimaryContainer,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '${summary.uniqueDishes} уникальных блюд',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        ' из ${summary.modulesUsed} модулей · ${summary.totalMeals} приёмов',
                    style: TextStyle(
                      color: AppColors.onPrimaryContainer.withValues(alpha: 0.7),
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

class _DayBlock extends StatelessWidget {
  const _DayBlock({required this.day, required this.onReplace});
  final DayPlan day;
  final ValueChanged<MealSlot> onReplace;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
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
          _MealRow(
            slot: MealSlot.breakfast,
            meal: day.breakfast,
            onReplace: () => onReplace(MealSlot.breakfast),
          ),
          const SizedBox(height: 6),
          _MealRow(
            slot: MealSlot.lunch,
            meal: day.lunch,
            onReplace: () => onReplace(MealSlot.lunch),
          ),
          const SizedBox(height: 6),
          _MealRow(
            slot: MealSlot.dinner,
            meal: day.dinner,
            onReplace: () => onReplace(MealSlot.dinner),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.slot,
    required this.meal,
    required this.onReplace,
  });
  final MealSlot slot;
  final PlannedMeal meal;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onReplace,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Text(slot.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                meal.title,
                style: tt.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.swap_horiz,
                size: 18,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _ReplaceSheet extends StatelessWidget {
  const _ReplaceSheet({required this.alternatives});
  final List<String> alternatives;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16, left: 140),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Заменить блюдо',
              style: tt.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Выберите альтернативу из ваших модулей',
              style: tt.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final alt in alternatives)
                  InkWell(
                    onTap: () => Navigator.pop(context, alt),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        alt,
                        style: tt.labelLarge?.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
