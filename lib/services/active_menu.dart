import 'package:flutter/foundation.dart';
import 'package:modular_chef/models/weekly_menu.dart';

/// Состояние процесса генерации меню.
enum MenuStatus { idle, generating, ready, error }

/// Глобальное состояние «активного» сгенерированного меню.
/// Один экземпляр живёт в провайдере приложения.
class ActiveMenu extends ChangeNotifier {
  WeeklyMenu? _menu;
  MenuStatus _status = MenuStatus.idle;
  Object? _error;

  WeeklyMenu? get menu => _menu;
  MenuStatus get status => _status;
  Object? get error => _error;

  bool get hasMenu => _menu != null;

  void beginGenerating() {
    _status = MenuStatus.generating;
    _error = null;
    notifyListeners();
  }

  void set(WeeklyMenu menu) {
    _menu = menu;
    _status = MenuStatus.ready;
    _error = null;
    notifyListeners();
  }

  void replaceMeal({
    required int weekIndex,
    required int dayIndex,
    required MealSlot slot,
    required PlannedMeal replacement,
  }) {
    final m = _menu;
    if (m == null) return;
    final week = m.weeks[weekIndex];
    final day = week.days[dayIndex];
    final newDay = DayPlan(
      weekday: day.weekday,
      shortName: day.shortName,
      breakfast: slot == MealSlot.breakfast ? replacement : day.breakfast,
      lunch: slot == MealSlot.lunch ? replacement : day.lunch,
      dinner: slot == MealSlot.dinner ? replacement : day.dinner,
      snack: slot == MealSlot.snack ? replacement : day.snack,
    );
    final newDays = [...week.days];
    newDays[dayIndex] = newDay;
    final newWeeks = [...m.weeks];
    newWeeks[weekIndex] =
        MenuWeek(index: week.index, name: week.name, days: newDays);
    _menu = WeeklyMenu(weeks: newWeeks, summary: m.summary);
    notifyListeners();
  }

  /// Точечно: заменить компонент роли в конкретной тарелке.
  void swapComponentInMeal({
    required int weekIndex,
    required int dayIndex,
    required MealSlot slot,
    required MealComponent component,
  }) {
    final m = _menu;
    if (m == null) return;
    final day = m.weeks[weekIndex].days[dayIndex];
    final meal = day.mealAt(slot);
    if (meal == null) return;
    _writeMeal(weekIndex, dayIndex, slot, meal.withComponent(component));
  }

  /// Пачкой: заменить модуль `fromModuleId` на `to` во всех тарелках недели.
  void swapModuleEverywhere({
    required int weekIndex,
    required String fromModuleId,
    required MealComponent to,
  }) {
    final m = _menu;
    if (m == null) return;
    final week = m.weeks[weekIndex];
    final newDays = <DayPlan>[];
    for (final day in week.days) {
      PlannedMeal patch(PlannedMeal? meal) {
        if (meal == null) return const PlannedMeal(title: '');
        if (!meal.moduleIds.contains(fromModuleId)) return meal;
        final next = meal.components
            .map((c) => c.moduleId == fromModuleId ? to.copyWith(role: c.role) : c)
            .toList();
        return meal.copyWith(
          components: next,
          title: PlannedMeal.titleFrom(next, meal.kind),
        );
      }

      newDays.add(DayPlan(
        weekday: day.weekday,
        shortName: day.shortName,
        breakfast: patch(day.breakfast),
        lunch: patch(day.lunch),
        dinner: patch(day.dinner),
        snack: day.snack == null ? null : patch(day.snack),
      ));
    }
    _writeWeek(weekIndex, newDays);
  }

  void _writeMeal(int weekIndex, int dayIndex, MealSlot slot, PlannedMeal meal) {
    final m = _menu!;
    final day = m.weeks[weekIndex].days[dayIndex];
    final newDay = DayPlan(
      weekday: day.weekday,
      shortName: day.shortName,
      breakfast: slot == MealSlot.breakfast ? meal : day.breakfast,
      lunch: slot == MealSlot.lunch ? meal : day.lunch,
      dinner: slot == MealSlot.dinner ? meal : day.dinner,
      snack: slot == MealSlot.snack ? meal : day.snack,
    );
    final newDays = [...m.weeks[weekIndex].days];
    newDays[dayIndex] = newDay;
    _writeWeek(weekIndex, newDays);
  }

  void _writeWeek(int weekIndex, List<DayPlan> days) {
    final m = _menu!;
    final week = m.weeks[weekIndex];
    final newWeeks = [...m.weeks];
    newWeeks[weekIndex] = MenuWeek(index: week.index, name: week.name, days: days);
    _menu = WeeklyMenu(weeks: newWeeks, summary: m.summary);
    notifyListeners();
  }

  void fail(Object e) {
    _error = e;
    _status = MenuStatus.error;
    notifyListeners();
  }
}
