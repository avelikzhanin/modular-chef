import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/services/active_menu.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/app_settings.dart';
import 'package:modular_chef/services/pantry_stock.dart';
import 'package:modular_chef/services/today_plan.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/theme/module_visuals.dart';
import 'package:modular_chef/widgets/atmospheric_header.dart';
import 'package:modular_chef/widgets/fade_in_up.dart';
import 'package:modular_chef/widgets/leaf_button.dart';

/// Гостевой хаб «Сегодня» — собран точно по дизайну Stitch:
/// топ-бар (логотип + колокольчик) → герой (переключатель + заголовок) →
/// карточки приёмов с акварельными картинками.
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

  static String _mealsWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'обед';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'обеда';
    }
    return 'обедов';
  }

  /// Тап по собранному слоту — инструкция «как разогреть».
  void _showReheat(BuildContext context, MealSlot slot, PlannedMeal meal) {
    final tt = Theme.of(context).textTheme;
    final hasSauce =
        meal.components.any((c) => c.role == MealRole.sauce);
    final steps = <String>[
      if (meal.fromContainer.isNotEmpty)
        'Достань из: ${meal.fromContainer}.',
      meal.reheatMinutes > 0
          ? 'Разогрей ${meal.reheatMinutes} мин под крышкой — так не высохнет.'
          : 'Разогрев не нужен — можно есть сразу.',
      if (hasSauce) 'Соус добавь после разогрева, не грей его.',
      'Приятного аппетита!',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(meal.title,
                  style: tt.titleLarge?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in meal.components)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (moduleImage(c.moduleId) != null) ...[
                          Image.asset(moduleImage(c.moduleId)!,
                              width: 18, height: 18),
                          const SizedBox(width: 5),
                        ],
                        Text(c.name,
                            style: tt.labelMedium?.copyWith(
                                color: AppColors.onSurfaceVariant)),
                      ]),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.lightLeaf,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text('${i + 1}',
                            style: tt.labelSmall?.copyWith(
                                color: AppColors.leafDeep,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(steps[i],
                            style: tt.bodyMedium?.copyWith(
                                color: AppColors.onSurface, height: 1.35)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              LeafButton.lake(
                onPressed: () {
                  Navigator.pop(ctx);
                  _assemble(context, slot);
                },
                label: 'Пересобрать',
                height: 46,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Взять блюдо из плана меню одним тапом: слот заполняется,
  /// порции списываются из запасов — по одной на каждого в семье.
  void _takePlanned(BuildContext context, MealSlot slot, PlannedMeal meal) {
    context.read<TodayPlan>().setMeal(slot, meal);
    final stock = context.read<PantryStock>();
    final settings = context.read<AppSettings>();
    final people = slot == MealSlot.breakfast
        ? settings.breakfastEaters
        : settings.householdSize;
    for (final c in meal.components) {
      stock.consume(c.moduleId, people);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<TodayPlan>();
    final today = context.watch<ActiveMenu>().dayPlanFor(DateTime.now());
    final stock = context.watch<PantryStock>();
    final catalog = context.watch<CatalogService>();
    // На сколько семейных обедов хватит белков в запасах.
    final people = context.watch<AppSettings>().householdSize;
    final proteinPortions = !catalog.isLoaded
        ? 0
        : stock.entries
            .where((e) =>
                catalog.moduleById(e.moduleId)?.category ==
                ModuleCategory.protein)
            .fold<int>(0, (s, e) => s + e.portions);
    final mealsLeft = proteinPortions ~/ people;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Единая шапка с акварельным небом — как у Шефа.
          const AtmosphericHeader(
            title: 'Сегодня',
            subtitle: 'Собери день из того, что Шеф приготовил заранее',
            trailing: RoleSwitcher(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              children: [
                // Подсказка нужна и когда белок кончился — это как раз момент,
                // когда Гостю важно понять, что готовить уже нечего.
                if (!stock.isEmpty || proteinPortions == 0) ...[
                  Builder(builder: (context) {
                    final tt = Theme.of(context).textTheme;
                    final empty = proteinPortions == 0;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: empty
                            ? AppColors.tertiaryContainer.withValues(alpha: 0.55)
                            : AppColors.lightLeaf.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        switch (mealsLeft) {
                          0 when empty =>
                            '🥘 Белок закончился — попроси Шефа приготовить',
                          0 => '🥘 Запасы на исходе — время Шефу готовить',
                          _ =>
                            '🥘 Запасов хватит ещё примерно на $mealsLeft ${_mealsWord(mealsLeft)} на ${people == 1 ? 'одного' : '$people человек'}',
                        },
                        style: tt.bodySmall?.copyWith(
                            color: empty
                                ? AppColors.onTertiaryContainer
                                : AppColors.leafDeep,
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                for (int i = 0; i < _slots.length; i++) ...[
                  FadeInUp(
                    delayMs: i * 70,
                    child: Builder(builder: (context) {
                      final slot = _slots[i];
                      final planned = today?.mealAt(slot);
                      final hasPlan = planned != null &&
                          planned.components.isNotEmpty;
                      final filled = plan.slot(slot).meal;
                      return _SlotCard(
                        slot: slot,
                        state: plan.slot(slot),
                        planned: hasPlan ? planned : null,
                        onAssemble: () => _assemble(context, slot),
                        onTakePlanned: hasPlan
                            ? () => _takePlanned(context, slot, planned)
                            : null,
                        onOpenMeal: filled != null
                            ? () => _showReheat(context, slot, filled)
                            : null,
                        onSkip: () => plan.skip(slot),
                        onClear: () => plan.clear(slot),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
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
    this.planned,
    this.onTakePlanned,
    this.onOpenMeal,
  });
  final MealSlot slot;
  final TodaySlot state;
  final VoidCallback onAssemble;
  final VoidCallback onSkip;
  final VoidCallback onClear;

  /// Тап по собранному слоту — инструкция разогрева.
  final VoidCallback? onOpenMeal;

  /// Что по утверждённому меню полагается на этот слот сегодня.
  final PlannedMeal? planned;
  final VoidCallback? onTakePlanned;

  // Картинка блюда: акварель первого компонента, иначе демо по слоту.
  String? get _image {
    final id = state.meal?.components.firstOrNull?.moduleId;
    final img = id != null ? moduleImage(id) : null;
    if (img != null) return img;
    return switch (slot) {
      MealSlot.breakfast => 'assets/art/demo_oats.png',
      MealSlot.lunch => 'assets/art/demo_lunch.png',
      _ => null,
    };
  }

  BoxDecoration get _cardDeco => BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint, blurRadius: 24, offset: Offset(0, 8)),
        ],
      );

  Widget _slotLabel(TextTheme tt) => Text(
        slot.label.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final meal = state.meal;

    // Пропущен / пусто — управляющие состояния.
    if (state.skipped) return _skipped(tt);
    if (meal == null) {
      return slot == MealSlot.snack ? _emptySnack(tt) : _emptyMeal(tt);
    }

    // Собрано — карточка с картинкой блюда.
    final main = meal.kind == MealKind.main;
    final parts = meal.title.split(' · ');
    final title = main
        ? meal.components
            .where((c) => c.role != MealRole.sauce)
            .map((c) => c.name)
            .join(' · ')
        : parts.first;
    final subtitle = (!main && parts.length > 1) ? parts.sublist(1).join(', ') : '';

    return InkWell(
      onTap: onOpenMeal ?? onAssemble,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: _cardDeco,
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageBox(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _slotLabel(tt)),
                      if (meal.reheatMinutes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${meal.reheatMinutes} мин',
                              style: tt.labelSmall?.copyWith(
                                  color: AppColors.onSecondaryContainer)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title,
                      style: tt.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      )),
                  if (main) ...[
                    const SizedBox(height: 8),
                    _checkChip(tt, 'Проверенное сочетание'),
                  ] else if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: tt.bodyMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageBox() {
    final img = _image;
    return Container(
      width: 80,
      height: 80,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: img != null
          ? Image.asset(img, fit: BoxFit.cover)
          : const Icon(Icons.restaurant_rounded,
              color: AppColors.primaryContainer, size: 30),
    );
  }

  Widget _checkChip(TextTheme tt, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.lightLeaf,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 15, color: AppColors.leafDeep),
            const SizedBox(width: 4),
            Text(text,
                style: tt.labelMedium?.copyWith(
                    color: AppColors.leafDeep, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // Пустой обед/ужин: если в меню есть план на сегодня — предлагаем его
  // одной кнопкой, сборка вручную остаётся ссылкой.
  Widget _emptyMeal(TextTheme tt) => Container(
        decoration: _cardDeco,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _slotLabel(tt)),
                Text('Ничего не выбрано',
                    style: tt.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontStyle: FontStyle.italic)),
              ],
            ),
            if (planned != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.event_note_rounded,
                    size: 16, color: AppColors.leafDeep),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('По плану: ${planned!.title}',
                      style: tt.bodyMedium?.copyWith(
                          color: AppColors.leafDeep,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            // Пара кнопок: главное действие + сборка руками.
            // «Пропустить» — редкий случай, ему хватает ссылки снизу.
            Row(
              children: [
                Expanded(
                  child: planned != null
                      ? LeafButton(
                          onPressed: onTakePlanned,
                          label: 'Взять по плану',
                          height: 48)
                      : LeafButton(
                          onPressed: onAssemble, label: 'Собрать', height: 48),
                ),
                if (planned != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: LeafButton.lake(
                        onPressed: onAssemble,
                        label: 'Собрать самому',
                        height: 48),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: onSkip,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('Пропустить →',
                    style: tt.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );

  // Пустой перекус — компактная карточка с призрачной иконкой.
  Widget _emptySnack(TextTheme tt) => InkWell(
        onTap: onAssemble,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: _cardDeco,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Opacity(
                opacity: 0.5,
                child: Container(
                  width: 48,
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/art/icons/fruit.png',
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _slotLabel(tt),
                    const SizedBox(height: 2),
                    Text('Ничего не выбрано',
                        style: tt.bodyMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.primary, size: 26),
            ],
          ),
        ),
      );

  // Пропущен.
  Widget _skipped(TextTheme tt) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _slotLabel(tt),
                  const SizedBox(height: 4),
                  Text('Пропущен',
                      style: tt.bodyMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('Вернуть')),
          ],
        ),
      );
}
