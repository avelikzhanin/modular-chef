import 'package:flutter/foundation.dart';
import 'package:modular_chef/services/local_store.dart';

/// Настройки приложения: сколько порций даёт одна готовка (на неё опираются
/// «Запасы») и сколько человек в семье (столько порций уходит за один приём).
class AppSettings extends ChangeNotifier {
  AppSettings({LocalStore? store}) : _store = store;

  static const _storeKey = 'app_settings';

  final LocalStore? _store;
  int _portionsPerBatch = 4;
  int _householdSize = 2;
  int _breakfastEaters = 2;
  int _menuWeeks = 2;

  int get portionsPerBatch => _portionsPerBatch;
  int get householdSize => _householdSize;

  /// Сколько человек реально завтракает (кто-то утром не ест).
  int get breakfastEaters => _breakfastEaters;

  /// Горизонт меню в неделях (1–3).
  int get menuWeeks => _menuWeeks;

  Future<void> loadFromStore() async {
    final json = await _store?.readJson(_storeKey);
    if (json == null) return;
    _portionsPerBatch = (json['portionsPerBatch'] as int?) ?? 4;
    _householdSize = (json['householdSize'] as int?) ?? 2;
    _breakfastEaters = (json['breakfastEaters'] as int?) ?? _householdSize;
    _menuWeeks = (json['menuWeeks'] as int?) ?? 2;
    notifyListeners();
  }

  void _save() {
    _store?.writeJson(_storeKey, {
      'portionsPerBatch': _portionsPerBatch,
      'householdSize': _householdSize,
      'breakfastEaters': _breakfastEaters,
      'menuWeeks': _menuWeeks,
    });
  }

  void setMenuWeeks(int value) {
    _menuWeeks = value.clamp(1, 3);
    _save();
    notifyListeners();
  }

  void setBreakfastEaters(int value) {
    _breakfastEaters = value.clamp(0, 8);
    _save();
    notifyListeners();
  }

  void setPortionsPerBatch(int value) {
    _portionsPerBatch = value.clamp(1, 12);
    _save();
    notifyListeners();
  }

  void setHouseholdSize(int value) {
    _householdSize = value.clamp(1, 8);
    _save();
    notifyListeners();
  }
}
