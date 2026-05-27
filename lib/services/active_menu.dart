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
    );
    final newDays = [...week.days];
    newDays[dayIndex] = newDay;
    final newWeeks = [...m.weeks];
    newWeeks[weekIndex] =
        MenuWeek(index: week.index, name: week.name, days: newDays);
    _menu = WeeklyMenu(weeks: newWeeks, summary: m.summary);
    notifyListeners();
  }

  void fail(Object e) {
    _error = e;
    _status = MenuStatus.error;
    notifyListeners();
  }
}
