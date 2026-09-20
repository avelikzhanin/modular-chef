import 'package:flutter/foundation.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/local_store.dart';

/// Состояние одного слота дня у Гостя.
class TodaySlot {
  const TodaySlot({this.meal, this.skipped = false});
  final PlannedMeal? meal;
  final bool skipped;

  bool get isEmpty => meal == null && !skipped;

  Map<String, dynamic> toJson() => {
        if (meal != null) 'meal': meal!.toJson(),
        'skipped': skipped,
      };

  factory TodaySlot.fromJson(Map<String, dynamic> json) => TodaySlot(
        meal: json['meal'] == null
            ? null
            : PlannedMeal.fromJson(json['meal'] as Map<String, dynamic>),
        skipped: (json['skipped'] as bool?) ?? false,
      );
}

/// Состояние гостевого дня: 4 слота (завтрак/обед/ужин/перекус).
/// Привязан к дате: наступил новый день — слоты сбрасываются.
/// Сохраняется локально, переживает перезапуск.
class TodayPlan extends ChangeNotifier {
  TodayPlan({LocalStore? store}) : _store = store;

  static const _storeKey = 'today_plan';

  final LocalStore? _store;

  final Map<MealSlot, TodaySlot> _slots = {
    MealSlot.breakfast: const TodaySlot(),
    MealSlot.lunch: const TodaySlot(),
    MealSlot.dinner: const TodaySlot(),
    MealSlot.snack: const TodaySlot(),
  };

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadFromStore() async {
    final json = await _store?.readJson(_storeKey);
    if (json == null) return;
    // Вчерашний план не тащим в новый день.
    if ((json['date'] as String?) != _dateKey(DateTime.now())) return;
    try {
      final slots = json['slots'] as Map<String, dynamic>;
      for (final s in MealSlot.values) {
        final raw = slots[s.name];
        if (raw != null) {
          _slots[s] = TodaySlot.fromJson(raw as Map<String, dynamic>);
        }
      }
      notifyListeners();
    } catch (_) {/* битые данные — начинаем день с чистого листа */}
  }

  void _save() {
    _store?.writeJson(_storeKey, {
      'date': _dateKey(DateTime.now()),
      'slots': {
        for (final e in _slots.entries) e.key.name: e.value.toJson(),
      },
    });
  }

  TodaySlot slot(MealSlot s) => _slots[s] ?? const TodaySlot();

  void setMeal(MealSlot s, PlannedMeal meal) {
    _slots[s] = TodaySlot(meal: meal);
    _save();
    notifyListeners();
  }

  void skip(MealSlot s) {
    _slots[s] = const TodaySlot(skipped: true);
    _save();
    notifyListeners();
  }

  void clear(MealSlot s) {
    _slots[s] = const TodaySlot();
    _save();
    notifyListeners();
  }
}
