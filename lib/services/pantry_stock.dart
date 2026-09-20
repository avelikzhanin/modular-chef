import 'package:flutter/foundation.dart';
import 'package:modular_chef/models/storage.dart';
import 'package:modular_chef/services/local_store.dart';

/// Одна партия заготовки: что, сколько порций, когда приготовлено и ГДЕ лежит.
/// Одна и та же курица может лежать двумя партиями: 4 порции в холодильнике
/// и 4 в морозилке.
class StockEntry {
  StockEntry({
    required this.moduleId,
    required this.portions,
    required this.cookedAt,
    this.zone = StorageZone.fridge,
  });

  final String moduleId;
  int portions;
  final DateTime cookedAt;
  StorageZone zone;

  Map<String, dynamic> toJson() => {
        'moduleId': moduleId,
        'portions': portions,
        'cookedAt': cookedAt.toIso8601String(),
        'zone': zone.jsonValue,
      };

  factory StockEntry.fromJson(Map<String, dynamic> json) => StockEntry(
        moduleId: json['moduleId'] as String,
        portions: json['portions'] as int,
        cookedAt:
            DateTime.tryParse((json['cookedAt'] as String?) ?? '') ?? DateTime.now(),
        zone: json['zone'] != null
            ? StorageZone.fromJson(json['zone'] as String)
            : StorageZone.fridge,
      );
}

/// Реальные запасы: Шеф завершил готовку → порции появились (в выбранных
/// зонах), Гость собрал тарелку → порции ушли. Сохраняется локально.
class PantryStock extends ChangeNotifier {
  PantryStock({LocalStore? store}) : _store = store;

  static const _storeKey = 'pantry_stock';

  /// Скоропорт списываем первым: холодильник → вакуум → кладовая → морозилка.
  static const _consumeOrder = [
    StorageZone.fridge,
    StorageZone.vacuum,
    StorageZone.pantry,
    StorageZone.freezer,
  ];

  final LocalStore? _store;
  final List<StockEntry> _entries = [];

  List<StockEntry> get entries => List.unmodifiable(_entries);
  bool get isEmpty => _entries.isEmpty;
  int get totalPortions => _entries.fold(0, (s, e) => s + e.portions);

  Future<void> loadFromStore() async {
    final json = await _store?.readJson(_storeKey);
    if (json == null) return;
    try {
      _entries
        ..clear()
        ..addAll(((json['entries'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(StockEntry.fromJson));
      notifyListeners();
    } catch (_) {/* best-effort */}
  }

  void _save() {
    _store?.writeJson(_storeKey, {
      'entries': [for (final e in _entries) e.toJson()],
    });
  }

  int portionsOf(String moduleId) => _entries
      .where((e) => e.moduleId == moduleId)
      .fold(0, (s, e) => s + e.portions);

  int portionsIn(String moduleId, StorageZone zone) => _entries
      .where((e) => e.moduleId == moduleId && e.zone == zone)
      .fold(0, (s, e) => s + e.portions);

  /// Шеф завершил готовку: позиции с порциями и зонами хранения.
  void addCookedMap(Map<String, int> portionsById,
      {Map<String, StorageZone>? zones}) {
    final now = DateTime.now();
    portionsById.forEach((id, portions) {
      if (portions <= 0) return;
      _entries.removeWhere((e) => e.moduleId == id);
      _entries.add(StockEntry(
        moduleId: id,
        portions: portions,
        cookedAt: now,
        zone: zones?[id] ?? StorageZone.fridge,
      ));
    });
    _save();
    notifyListeners();
  }

  /// Совместимость: одна зона по умолчанию.
  void addCooked(Iterable<String> moduleIds, int portionsEach) {
    addCookedMap({for (final id in moduleIds) id: portionsEach});
  }

  /// Гость взял порции: сначала скоропорт (холодильник), морозилку — последней.
  void consume(String moduleId, [int n = 1]) {
    var left = n;
    for (final zone in _consumeOrder) {
      if (left <= 0) break;
      final batches = _entries
          .where((e) => e.moduleId == moduleId && e.zone == zone)
          .toList()
        ..sort((a, b) => a.cookedAt.compareTo(b.cookedAt));
      for (final b in batches) {
        if (left <= 0) break;
        final take = left.clamp(0, b.portions);
        b.portions -= take;
        left -= take;
      }
    }
    _entries.removeWhere((e) => e.portions <= 0);
    _save();
    notifyListeners();
  }

  /// Переложить часть партии в другую зону («4 порции курицы — в морозилку»).
  void move(String moduleId, StorageZone from, StorageZone to, int n) {
    if (from == to || n <= 0) return;
    var left = n;
    final batches = _entries
        .where((e) => e.moduleId == moduleId && e.zone == from)
        .toList()
      ..sort((a, b) => a.cookedAt.compareTo(b.cookedAt));
    for (final b in batches) {
      if (left <= 0) break;
      final take = left.clamp(0, b.portions);
      b.portions -= take;
      left -= take;
      final existing = _entries.where(
          (e) => e.moduleId == moduleId && e.zone == to).toList();
      if (existing.isNotEmpty) {
        existing.first.portions += take;
      } else {
        _entries.add(StockEntry(
          moduleId: moduleId,
          portions: take,
          cookedAt: b.cookedAt,
          zone: to,
        ));
      }
    }
    _entries.removeWhere((e) => e.portions <= 0);
    _save();
    notifyListeners();
  }
}
