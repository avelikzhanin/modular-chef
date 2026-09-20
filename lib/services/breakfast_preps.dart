import 'package:flutter/foundation.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/local_store.dart';

/// Заготовки завтраков, которые Шеф делает впрок:
///  - **банки** — собраны целиком (4 слоя), Гость просто берёт готовую;
///  - **яйца** — виды и добавки, которые Шеф держит наготове (яйца жарятся утром,
///    но начинку/варёные яйца Шеф готовит заранее).
///
/// Сохраняется локально, переживает перезапуск.
class BreakfastPreps extends ChangeNotifier {
  BreakfastPreps({LocalStore? store}) : _store = store;

  static const _storeKey = 'breakfast_preps';

  final LocalStore? _store;
  final List<PlannedMeal> _jars = [];
  final Set<String> _eggStyleIds = {};
  final Set<String> _eggAddinIds = {};
  final Set<String> _porridgeKindIds = {};
  final Set<String> _porridgeAddinIds = {};
  final Set<String> _sandwichFillingIds = {};
  final Set<String> _sandwichSpreadIds = {};
  final Set<String> _sandwichBreadPreps = {};

  List<PlannedMeal> get jars => List.unmodifiable(_jars);
  Set<String> get eggStyleIds => Set.unmodifiable(_eggStyleIds);
  Set<String> get eggAddinIds => Set.unmodifiable(_eggAddinIds);
  Set<String> get porridgeKindIds => Set.unmodifiable(_porridgeKindIds);
  Set<String> get porridgeAddinIds => Set.unmodifiable(_porridgeAddinIds);
  Set<String> get sandwichFillingIds => Set.unmodifiable(_sandwichFillingIds);
  Set<String> get sandwichSpreadIds => Set.unmodifiable(_sandwichSpreadIds);
  Set<String> get sandwichBreadPreps => Set.unmodifiable(_sandwichBreadPreps);

  bool get hasJars => _jars.isNotEmpty;
  bool get hasEggs => _eggStyleIds.isNotEmpty;
  bool get isEmpty => _jars.isEmpty && _eggStyleIds.isEmpty;

  Future<void> loadFromStore() async {
    final json = await _store?.readJson(_storeKey);
    if (json == null) return;
    try {
      _jars
        ..clear()
        ..addAll(((json['jars'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PlannedMeal.fromJson));
      _eggStyleIds
        ..clear()
        ..addAll(((json['eggStyles'] as List?) ?? const []).cast<String>());
      _eggAddinIds
        ..clear()
        ..addAll(((json['eggAddins'] as List?) ?? const []).cast<String>());
      _porridgeKindIds
        ..clear()
        ..addAll(((json['porridgeKinds'] as List?) ?? const []).cast<String>());
      _porridgeAddinIds
        ..clear()
        ..addAll(((json['porridgeAddins'] as List?) ?? const []).cast<String>());
      _sandwichFillingIds
        ..clear()
        ..addAll(
            ((json['sandwichFillings'] as List?) ?? const []).cast<String>());
      _sandwichSpreadIds
        ..clear()
        ..addAll(
            ((json['sandwichSpreads'] as List?) ?? const []).cast<String>());
      _sandwichBreadPreps
        ..clear()
        ..addAll(
            ((json['sandwichBreadPreps'] as List?) ?? const []).cast<String>());
      notifyListeners();
    } catch (_) {/* best-effort */}
  }

  void _save() {
    _store?.writeJson(_storeKey, {
      'jars': [for (final j in _jars) j.toJson()],
      'eggStyles': _eggStyleIds.toList(),
      'eggAddins': _eggAddinIds.toList(),
      'porridgeKinds': _porridgeKindIds.toList(),
      'porridgeAddins': _porridgeAddinIds.toList(),
      'sandwichFillings': _sandwichFillingIds.toList(),
      'sandwichSpreads': _sandwichSpreadIds.toList(),
      'sandwichBreadPreps': _sandwichBreadPreps.toList(),
    });
  }

  void addJar(PlannedMeal jar) {
    _jars.add(jar);
    _save();
    notifyListeners();
  }

  void removeJarAt(int index) {
    if (index >= 0 && index < _jars.length) {
      _jars.removeAt(index);
      _save();
      notifyListeners();
    }
  }

  /// Гость забрал готовую банку — убираем её из заготовок.
  void removeJar(PlannedMeal jar) {
    if (_jars.remove(jar)) {
      _save();
      notifyListeners();
    }
  }

  void toggleEggStyle(String id) {
    if (!_eggStyleIds.remove(id)) _eggStyleIds.add(id);
    _save();
    notifyListeners();
  }

  void toggleEggAddin(String id) {
    if (!_eggAddinIds.remove(id)) _eggAddinIds.add(id);
    _save();
    notifyListeners();
  }

  void togglePorridgeKind(String id) {
    if (!_porridgeKindIds.remove(id)) _porridgeKindIds.add(id);
    _save();
    notifyListeners();
  }

  void toggleSandwichFilling(String id) {
    if (!_sandwichFillingIds.remove(id)) _sandwichFillingIds.add(id);
    _save();
    notifyListeners();
  }

  void togglePorridgeAddin(String id) {
    if (!_porridgeAddinIds.remove(id)) _porridgeAddinIds.add(id);
    _save();
    notifyListeners();
  }

  void toggleSandwichSpread(String id) {
    if (!_sandwichSpreadIds.remove(id)) _sandwichSpreadIds.add(id);
    _save();
    notifyListeners();
  }

  void toggleSandwichBreadPrep(String label) {
    if (!_sandwichBreadPreps.remove(label)) _sandwichBreadPreps.add(label);
    _save();
    notifyListeners();
  }
}
