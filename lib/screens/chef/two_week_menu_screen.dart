import 'package:flutter/material.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Push-экран Шефа «Меню на 2 недели» — критический для флоу.
/// Открывается после нажатия «Собрать меню» на BuildMenuScreen.
/// Сетка 7 дней × 3 приёма × 2 недели, замена блюд по long-press, кнопка «Утвердить».
class TwoWeekMenuScreen extends StatefulWidget {
  const TwoWeekMenuScreen({super.key});

  @override
  State<TwoWeekMenuScreen> createState() => _TwoWeekMenuScreenState();
}

class _TwoWeekMenuScreenState extends State<TwoWeekMenuScreen> {
  int _weekIndex = 0;

  // Мок: 2 недели × 7 дней × 3 приёма. Stage 3 заменит на результат генерации.
  static const _weeks = <List<_DayPlan>>[
    [
      _DayPlan('Пн', [_M('🌅', 'Овсянка'), _M('🌞', 'Курица+рис'), _M('🌙', 'Лосось+булгур')]),
      _DayPlan('Вт', [_M('🌅', 'Сырники'), _M('🌞', 'Суп куриный'), _M('🌙', 'Стейк+спагетти')]),
      _DayPlan('Ср', [_M('🌅', 'Гранола'), _M('🌞', 'Треска+киноа'), _M('🌙', 'Плов')]),
      _DayPlan('Чт', [_M('🌅', 'Омлет'), _M('🌞', 'Борщ'), _M('🌙', 'Тунец салат')]),
      _DayPlan('Пт', [_M('🌅', 'Тост авокадо'), _M('🌞', 'Паста песто'), _M('🌙', 'Курица гриль')]),
      _DayPlan('Сб', [_M('🌅', 'Блины'), _M('🌞', 'Лазанья'), _M('🌙', 'Стейк')]),
      _DayPlan('Вс', [_M('🌅', 'Фриттата'), _M('🌞', 'Ростбиф'), _M('🌙', 'Греческий салат')]),
    ],
    [
      _DayPlan('Пн', [_M('🌅', 'Йогурт+мюсли'), _M('🌞', 'Курица+гречка'), _M('🌙', 'Лосось+рис')]),
      _DayPlan('Вт', [_M('🌅', 'Сырники'), _M('🌞', 'Суп грибной'), _M('🌙', 'Индейка+булгур')]),
      _DayPlan('Ср', [_M('🌅', 'Овсянка'), _M('🌞', 'Креветки+киноа'), _M('🌙', 'Стейк')]),
      _DayPlan('Чт', [_M('🌅', 'Омлет'), _M('🌞', 'Минестроне'), _M('🌙', 'Тунец+спагетти')]),
      _DayPlan('Пт', [_M('🌅', 'Гранола'), _M('🌞', 'Куриные котлеты'), _M('🌙', 'Лосось')]),
      _DayPlan('Сб', [_M('🌅', 'Панкейки'), _M('🌞', 'Паста карбонара'), _M('🌙', 'Жаркое')]),
      _DayPlan('Вс', [_M('🌅', 'Шакшука'), _M('🌞', 'Куриный суп'), _M('🌙', 'Запеканка')]),
    ],
  ];

  // Альтернативы для замены блюда (Stage 3 это вернёт умный generator).
  static const _alternatives = <String>[
    'Курица+рис', 'Лосось+булгур', 'Стейк+спагетти', 'Треска+киноа',
    'Креветки гриль', 'Индейка+гречка', 'Тунец салат',
  ];

  late final List<List<_DayPlan>> _state =
      _weeks.map((w) => w.map((d) => d.copy()).toList()).toList();

  void _replaceMeal(int dayIdx, int mealIdx) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReplaceSheet(alternatives: _alternatives),
    );
    if (picked != null && mounted) {
      setState(() {
        final day = _state[_weekIndex][dayIdx];
        final newMeals = [...day.meals];
        newMeals[mealIdx] = _M(newMeals[mealIdx].emoji, picked);
        _state[_weekIndex][dayIdx] = _DayPlan(day.name, newMeals);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final days = _state[_weekIndex];
    final allMeals = _state.expand((w) => w).expand((d) => d.meals).length;
    final unique = _state.expand((w) => w).expand((d) => d.meals).map((m) => m.title).toSet().length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Меню на 2 недели'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          _WeekTabs(
            index: _weekIndex,
            onChanged: (i) => setState(() => _weekIndex = i),
          ),
          const SizedBox(height: 16),
          _Badge(unique: unique, total: allMeals),
          const SizedBox(height: 20),
          for (int i = 0; i < days.length; i++) ...[
            _DayBlock(
              day: days[i],
              onReplace: (mealIdx) => _replaceMeal(i, mealIdx),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomSheet: Container(
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
}

class _DayPlan {
  const _DayPlan(this.name, this.meals);
  final String name;
  final List<_M> meals;
  _DayPlan copy() => _DayPlan(name, [...meals]);
}

class _M {
  const _M(this.emoji, this.title);
  final String emoji;
  final String title;
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
                color: selected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
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
  const _Badge({required this.unique, required this.total});
  final int unique;
  final int total;

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
                    text: '$unique уникальных блюд',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ' из 6 модулей · $total приёмов суммарно',
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
  final _DayPlan day;
  final ValueChanged<int> onReplace;

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
            day.name.toUpperCase(),
            style: tt.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < day.meals.length; i++) ...[
            _MealRow(meal: day.meals[i], onReplace: () => onReplace(i)),
            if (i < day.meals.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal, required this.onReplace});
  final _M meal;
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
            Text(meal.emoji, style: const TextStyle(fontSize: 18)),
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
                size: 18, color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
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
