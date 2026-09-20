import 'package:flutter/foundation.dart';
import 'package:modular_chef/services/local_store.dart';

/// Своё блюдо Шефа: название + состав из модулей каталога.
/// Отмеченные «готовлю на этой неделе» добавляют состав в список покупок.
class MyDish {
  MyDish({
    required this.name,
    List<String>? moduleIds,
    this.cookThisWeek = false,
  }) : moduleIds = moduleIds ?? [];

  String name;
  List<String> moduleIds;
  bool cookThisWeek;

  Map<String, dynamic> toJson() => {
        'name': name,
        'moduleIds': moduleIds,
        'cookThisWeek': cookThisWeek,
      };

  factory MyDish.fromJson(Map<String, dynamic> json) => MyDish(
        name: json['name'] as String,
        moduleIds: ((json['moduleIds'] as List?) ?? const []).cast<String>(),
        cookThisWeek: (json['cookThisWeek'] as bool?) ?? false,
      );
}

/// Библиотека «Мои блюда». Сохраняется локально.
class MyDishes extends ChangeNotifier {
  MyDishes({LocalStore? store}) : _store = store;

  static const _storeKey = 'my_dishes';

  final LocalStore? _store;
  final List<MyDish> _items = [];

  List<MyDish> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  List<String> get names => [for (final d in _items) d.name];

  /// Блюда, отмеченные «готовлю на этой неделе».
  List<MyDish> get thisWeek =>
      [for (final d in _items) if (d.cookThisWeek) d];

  Future<void> loadFromStore() async {
    final json = await _store?.readJson(_storeKey);
    if (json == null) return;
    try {
      _items
        ..clear()
        ..addAll(((json['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(MyDish.fromJson));
      notifyListeners();
    } catch (_) {/* best-effort */}
  }

  void _save() {
    _store?.writeJson(_storeKey, {
      'items': [for (final d in _items) d.toJson()],
    });
  }

  void add(MyDish dish) {
    _items.add(dish);
    _save();
    notifyListeners();
  }

  void update(MyDish dish,
      {String? name, List<String>? moduleIds, bool? cookThisWeek}) {
    if (name != null) dish.name = name;
    if (moduleIds != null) dish.moduleIds = moduleIds;
    if (cookThisWeek != null) dish.cookThisWeek = cookThisWeek;
    _save();
    notifyListeners();
  }

  void remove(MyDish dish) {
    _items.remove(dish);
    _save();
    notifyListeners();
  }
}
