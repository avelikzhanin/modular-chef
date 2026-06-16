import 'package:flutter/foundation.dart';
import 'package:modular_chef/models/weekly_menu.dart';

/// Состояние одного слота дня у Гостя.
class TodaySlot {
  const TodaySlot({this.meal, this.skipped = false});
  final PlannedMeal? meal;
  final bool skipped;

  bool get isEmpty => meal == null && !skipped;
}

/// Состояние гостевого дня: 4 слота (завтрак/обед/ужин/перекус).
/// Гость может собрать слот, пропустить его или очистить. Локально, без бэка.
class TodayPlan extends ChangeNotifier {
  TodayPlan() {
    // Демо-наполнение, чтобы «Сегодня» не был пустым на первом открытии.
    _slots[MealSlot.breakfast] = const TodaySlot(
      meal: PlannedMeal(
        title: 'Овсянка с ягодами',
        kind: MealKind.breakfast,
        components: [
          MealComponent(
              moduleId: 'oatmeal_jar',
              role: MealRole.standalone,
              name: 'Овсянка в банке',
              emoji: '🥣'),
        ],
        reheatMinutes: 0,
        fromContainer: 'холодильник, банка №1',
      ),
    );
    _slots[MealSlot.lunch] = const TodaySlot(
      meal: PlannedMeal(
        title: 'Курица гриль + рис + брокколи + йогуртовый соус',
        kind: MealKind.main,
        components: [
          MealComponent(moduleId: 'chicken_breast', role: MealRole.protein, name: 'Курица', emoji: '🍗'),
          MealComponent(moduleId: 'rice', role: MealRole.side, name: 'Рис', emoji: '🍚'),
          MealComponent(moduleId: 'broccoli', role: MealRole.vegetable, name: 'Брокколи', emoji: '🥦'),
          MealComponent(moduleId: 'yogurt_sauce', role: MealRole.sauce, name: 'Йогуртовый соус', emoji: '🥛'),
        ],
        reheatMinutes: 2,
        fromContainer: 'холодильник, контейнер №2',
      ),
    );
    // ужин и перекус — пустые, чтобы показать сценарий «собрать»
  }

  final Map<MealSlot, TodaySlot> _slots = {
    MealSlot.breakfast: const TodaySlot(),
    MealSlot.lunch: const TodaySlot(),
    MealSlot.dinner: const TodaySlot(),
    MealSlot.snack: const TodaySlot(),
  };

  TodaySlot slot(MealSlot s) => _slots[s] ?? const TodaySlot();

  void setMeal(MealSlot s, PlannedMeal meal) {
    _slots[s] = TodaySlot(meal: meal);
    notifyListeners();
  }

  void skip(MealSlot s) {
    _slots[s] = const TodaySlot(skipped: true);
    notifyListeners();
  }

  void clear(MealSlot s) {
    _slots[s] = const TodaySlot();
    notifyListeners();
  }
}
