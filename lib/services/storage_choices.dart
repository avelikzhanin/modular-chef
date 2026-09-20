import 'package:flutter/foundation.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/storage.dart';
import 'package:modular_chef/services/local_store.dart';

/// Выбор Шефа, где хранить каждую заготовку.
/// По умолчанию — рекомендация из каталога (module.storage.zone),
/// но Шеф может сам решить: холодильник / морозилка / вакуум.
/// Выбор сохраняется локально и переживает перезапуск.
class StorageChoices extends ChangeNotifier {
  StorageChoices({LocalStore? store}) : _store = store;

  static const _storeKey = 'storage_choices';

  final LocalStore? _store;
  final Map<String, StorageZone> _chosen = {};
  final Map<String, StorageZone> _home = {};

  Future<void> loadFromStore() async {
    final json = await _store?.readJson(_storeKey);
    if (json == null) return;
    try {
      final cooked = (json['cooked'] as Map<String, dynamic>?) ??
          // Легаси-формат: плоская карта.
          (json..remove('home'));
      cooked.forEach((id, zone) {
        _chosen[id] = StorageZone.fromJson(zone as String);
      });
      ((json['home'] as Map<String, dynamic>?) ?? const {})
          .forEach((id, zone) {
        _home[id] = StorageZone.fromJson(zone as String);
      });
      notifyListeners();
    } catch (_) {/* best-effort */}
  }

  void _save() {
    _store?.writeJson(_storeKey, {
      'cooked': {
        for (final e in _chosen.entries) e.key: e.value.jsonValue,
      },
      'home': {
        for (final e in _home.entries) e.key: e.value.jsonValue,
      },
    });
  }

  /// Зона домашнего (сырого) продукта: выбор Шефа или дефолт-эвристика.
  StorageZone homeZoneFor(String key, StorageZone fallback) =>
      _home[key] ?? fallback;

  void chooseHome(String key, StorageZone zone) {
    _home[key] = zone;
    _save();
    notifyListeners();
  }

  /// Текущая зона модуля: выбор Шефа или рекомендация.
  StorageZone zoneFor(Module m) => _chosen[m.id] ?? m.storage.zone;

  bool isOverridden(Module m) =>
      _chosen.containsKey(m.id) && _chosen[m.id] != m.storage.zone;

  void choose(String moduleId, StorageZone zone) {
    _chosen[moduleId] = zone;
    _save();
    notifyListeners();
  }

  /// Срок хранения для выбранной зоны. Точные дни знаем только для
  /// рекомендованной; для остальных — типовые сроки зоны.
  String daysLabel(Module m, StorageZone zone) {
    if (zone == m.storage.zone) return 'до ${m.storage.days} дн.';
    return switch (zone) {
      StorageZone.fridge => '3–4 дня',
      StorageZone.freezer => '2–3 месяца',
      StorageZone.vacuum => '+3–5 дней к сроку',
      StorageZone.pantry => 'до 2 недель',
    };
  }
}
