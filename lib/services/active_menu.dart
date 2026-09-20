import 'package:flutter/foundation.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/local_store.dart';

/// Состояние процесса генерации меню.
enum MenuStatus { idle, generating, ready, error }

/// Глобальное состояние «активного» сгенерированного меню.
/// Один экземпляр живёт в провайдере приложения. Утверждённое меню
/// сохраняется локально (переживает перезапуск и отсутствие сети).
class ActiveMenu extends ChangeNotifier {
  ActiveMenu({LocalStore? store}) : _store = store;

  static const _storeKey = 'active_menu';

  final LocalStore? _store;
  WeeklyMenu? _menu;
  MenuStatus _status = MenuStatus.idle;
  Object? _error;
  DateTime? _approvedAt;

  WeeklyMenu? get menu => _menu;
  MenuStatus get status => _status;
  Object? get error => _error;
  DateTime? get approvedAt => _approvedAt;

  bool get hasMenu => _menu != null;

  /// Восстанавливает утверждённое меню с диска. true — что-то восстановили.
  Future<bool> loadFromStore() async {
    final json = await _store?.readJson(_storeKey);
    if (json == null) return false;
    try {
      _menu = WeeklyMenu.fromJson(json['menu'] as Map<String, dynamic>);
      _approvedAt = DateTime.tryParse((json['approvedAt'] as String?) ?? '');
      _status = MenuStatus.ready;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// «Утвердить»: фиксирует дату старта плана, сохраняет меню локально
  /// и добавляет копию в историю — к прошлым меню можно вернуться.
  void approve() {
    if (_menu == null) return;
    _approvedAt = DateTime.now();
    _store?.writeJson(_storeKey, {
      'menu': _menu!.toJson(),
      'approvedAt': _approvedAt!.toIso8601String(),
    });
    _appendHistory();
    notifyListeners();
  }

  static const historyKey = 'menu_history';

  Future<void> _appendHistory() async {
    final store = _store;
    if (store == null || _menu == null) return;
    final json = await store.readJson(historyKey);
    final items = ((json?['items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .toList();
    items.insert(0, {
      'approvedAt': _approvedAt!.toIso8601String(),
      'menu': _menu!.toJson(),
    });
    while (items.length > 6) {
      items.removeLast();
    }
    await store.writeJson(historyKey, {'items': items});
  }

  /// План на конкретную дату: дни считаются от даты утверждения по кругу.
  DayPlan? dayPlanFor(DateTime date) {
    final m = _menu;
    if (m == null || m.weeks.isEmpty) return null;
    final anchor = _approvedAt ?? DateTime.now();
    final a = DateTime(anchor.year, anchor.month, anchor.day);
    final d = DateTime(date.year, date.month, date.day);
    var offset = d.difference(a).inDays;
    final total = m.weeks.fold<int>(0, (s, w) => s + w.days.length);
    if (total == 0) return null;
    offset = ((offset % total) + total) % total;
    for (final week in m.weeks) {
      if (offset < week.days.length) return week.days[offset];
      offset -= week.days.length;
    }
    return null;
  }

  /// id всех модулей утверждённого меню — «что готовит Шеф».
  Set<String> get allModuleIds {
    final m = _menu;
    if (m == null) return const {};
    final ids = <String>{};
    for (final week in m.weeks) {
      for (final day in week.days) {
        for (final slot in MealSlot.values) {
          final meal = day.mealAt(slot);
          if (meal != null) ids.addAll(meal.moduleIds);
        }
      }
    }
    return ids;
  }

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

  /// Все тарелки недели, содержащие модуль — для выбора, где именно заменить.
  List<({int dayIndex, String dayShort, MealSlot slot, String title})>
      mealsWithModule(int weekIndex, String moduleId) {
    final m = _menu;
    if (m == null) return const [];
    final week = m.weeks[weekIndex];
    final out =
        <({int dayIndex, String dayShort, MealSlot slot, String title})>[];
    for (int d = 0; d < week.days.length; d++) {
      final day = week.days[d];
      for (final slot in MealSlot.values) {
        final meal = day.mealAt(slot);
        if (meal != null && meal.moduleIds.contains(moduleId)) {
          out.add((
            dayIndex: d,
            dayShort: day.shortName,
            slot: slot,
            title: meal.title
          ));
        }
      }
    }
    return out;
  }

  /// Точечно-пачкой: заменить модуль только в выбранных тарелках (день+слот).
  void swapModuleInTargets({
    required int weekIndex,
    required String fromModuleId,
    required MealComponent to,
    required Set<(int, MealSlot)> targets,
  }) {
    if (_menu == null) return;
    for (final (dayIndex, slot) in targets) {
      final meal = _menu!.weeks[weekIndex].days[dayIndex].mealAt(slot);
      if (meal == null || !meal.moduleIds.contains(fromModuleId)) continue;
      final next = meal.components
          .map((c) =>
              c.moduleId == fromModuleId ? to.copyWith(role: c.role) : c)
          .toList();
      _writeMeal(
        weekIndex,
        dayIndex,
        slot,
        meal.copyWith(
            components: next, title: PlannedMeal.titleFrom(next, meal.kind)),
      );
    }
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
