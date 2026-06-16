import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/services/today_plan.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Гостевой хаб «Сегодня» — 4 слота. По каждому: собрать / заменить / пропустить.
/// Гость живёт сегодняшним днём.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  static const _slots = [
    MealSlot.breakfast,
    MealSlot.lunch,
    MealSlot.dinner,
    MealSlot.snack,
  ];

  void _assemble(BuildContext context, MealSlot slot) {
    context.push('${Routes.guestAssembleDish}?slot=${slot.jsonValue}');
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final plan = context.watch<TodayPlan>();

    final hasPerishable = plan.slot(MealSlot.lunch).meal != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Понедельник, 14 апреля',
            style: tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'Что сегодня едим?',
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          if (hasPerishable) ...[
            const _AlertBanner(text: 'Йогуртовый соус — последний день, используй сегодня'),
            const SizedBox(height: 16),
          ],
          for (final slot in _slots) ...[
            _SlotCard(
              slot: slot,
              state: plan.slot(slot),
              onAssemble: () => _assemble(context, slot),
              onSkip: () => plan.skip(slot),
              onClear: () => plan.clear(slot),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule, color: AppColors.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: tt.bodyMedium?.copyWith(
                color: AppColors.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.state,
    required this.onAssemble,
    required this.onSkip,
    required this.onClear,
  });
  final MealSlot slot;
  final TodaySlot state;
  final VoidCallback onAssemble;
  final VoidCallback onSkip;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    Widget header() => Row(
          children: [
            Text(slot.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              slot.label,
              style: tt.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        );

    // Пропущен
    if (state.skipped) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header(),
                  const SizedBox(height: 6),
                  Text('Пропущен',
                      style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('Вернуть')),
          ],
        ),
      );
    }

    // Пусто — собрать
    final meal = state.meal;
    if (meal == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAssemble,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Собрать ${slot.label.toLowerCase()}'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: onSkip, child: const Text('Пропустить')),
              ],
            ),
          ],
        ),
      );
    }

    // Собрано — карточка тарелки
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowTint, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: header()),
              if (meal.reheatMinutes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${meal.reheatMinutes} мин',
                      style: tt.labelSmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            meal.title,
            style: tt.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (meal.fromContainer.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(meal.fromContainer,
                    style: tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(onPressed: onAssemble, child: const Text('Заменить')),
              const SizedBox(width: 8),
              TextButton(onPressed: onClear, child: const Text('Убрать')),
            ],
          ),
        ],
      ),
    );
  }
}
