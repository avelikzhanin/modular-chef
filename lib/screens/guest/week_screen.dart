import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Гостевой экран «Моя неделя» — порт guest/v4_2 из Stitch.
/// 7 дней × 3 приёма + плитки «остатков модулей».
class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  int _weekIndex = 0;

  static const _week = <_DayPlan>[
    _DayPlan('Понедельник', isToday: true, meals: [
      _MealChip('🌅', 'Овсянка'),
      _MealChip('🌞', 'Курица+рис'),
      _MealChip('🌙', 'Лосось+булгур'),
    ]),
    _DayPlan('Вторник', meals: [
      _MealChip('🌅', 'Сырники'),
      _MealChip('🌞', 'Суп куриный'),
      _MealChip('🌙', 'Стейк+спагетти'),
    ]),
    _DayPlan('Среда', meals: [
      _MealChip('🌅', 'Гранола'),
      _MealChip('🌞', 'Треска+киноа'),
      _MealChip('🌙', 'Плов'),
    ]),
    _DayPlan('Четверг', meals: [
      _MealChip('🌅', 'Омлет'),
      _MealChip('🌞', 'Борщ'),
      _MealChip('🌙', 'Тунец салат'),
    ]),
    _DayPlan('Пятница', meals: [
      _MealChip('🌅', 'Тост авокадо'),
      _MealChip('🌞', 'Паста песто'),
      _MealChip('🌙', 'Утка'),
    ]),
    _DayPlan('Суббота', meals: [
      _MealChip('🌅', 'Блины'),
      _MealChip('🌞', 'Лазанья'),
      _MealChip('🌙', 'Стейк'),
    ]),
    _DayPlan('Воскресенье', meals: [
      _MealChip('🌅', 'Фриттата'),
      _MealChip('🌞', 'Ростбиф'),
      _MealChip('🌙', 'Греческий салат'),
    ]),
  ];

  static const _stats = <_StatTile>[
    _StatTile('🥩', '4', 'Белки', AppColors.secondaryContainer, AppColors.onSecondaryContainer),
    _StatTile('🍚', '6', 'Угли', AppColors.tertiaryContainer, AppColors.onTertiaryContainer),
    _StatTile('🥗', '3', 'Овощи', AppColors.surfaceContainerHigh, AppColors.onSurface),
    _StatTile('🥣', '2', 'Супы', AppColors.primaryContainer, AppColors.onPrimaryContainer),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Меню на эту неделю',
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _WeekToggle(
            index: _weekIndex,
            onChanged: (i) => setState(() => _weekIndex = i),
          ),
          const SizedBox(height: 24),
          for (final day in _week) ...[
            _DayBlock(day: day),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 24),
          Text(
            'ОСТАЛОСЬ МОДУЛЕЙ',
            style: tt.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
            children: [for (final s in _stats) _StatCard(stat: s)],
          ),
        ],
      ),
    );
  }
}

class _DayPlan {
  const _DayPlan(this.name, {this.isToday = false, required this.meals});
  final String name;
  final bool isToday;
  final List<_MealChip> meals;
}

class _MealChip {
  const _MealChip(this.emoji, this.label);
  final String emoji;
  final String label;
}

class _StatTile {
  const _StatTile(this.emoji, this.count, this.label, this.bg, this.fg);
  final String emoji;
  final String count;
  final String label;
  final Color bg;
  final Color fg;
}

class _WeekToggle extends StatelessWidget {
  const _WeekToggle({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    Widget pill(int i, String label) {
      final selected = index == i;
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

class _DayBlock extends StatelessWidget {
  const _DayBlock({required this.day});
  final _DayPlan day;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: day.isToday
            ? AppColors.primaryContainer.withValues(alpha: 0.3)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day.name.toUpperCase(),
                style: tt.labelMedium?.copyWith(
                  color: day.isToday
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              if (day.isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Сегодня',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final m in day.meals) _MealPill(meal: m)],
          ),
        ],
      ),
    );
  }
}

class _MealPill extends StatelessWidget {
  const _MealPill({required this.meal});
  final _MealChip meal;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(meal.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            meal.label,
            style: tt.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final _StatTile stat;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: stat.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(stat.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                stat.count,
                style: tt.titleLarge?.copyWith(
                  color: stat.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            stat.label.toUpperCase(),
            style: tt.labelSmall?.copyWith(
              color: stat.fg.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
