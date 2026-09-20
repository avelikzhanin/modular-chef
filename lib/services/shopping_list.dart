import 'package:flutter/foundation.dart';
import 'package:modular_chef/services/local_store.dart';

/// Свой пункт списка покупок (добавлен вручную).
class CustomShopItem {
  CustomShopItem({required this.name, this.qty = '1 шт.', this.have = false});

  final String name;
  final String qty;
  bool have;

  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'have': have};

  factory CustomShopItem.fromJson(Map<String, dynamic> json) => CustomShopItem(
        name: json['name'] as String,
        qty: (json['qty'] as String?) ?? '1 шт.',
        have: (json['have'] as bool?) ?? false,
      );
}

/// Состояние списка покупок: сами позиции считаются из утверждённого меню,
/// здесь — отметки «уже есть» (по id модуля) и добавленные вручную пункты.
/// Сохраняется локально.
class ShoppingList extends ChangeNotifier {
  ShoppingList({LocalStore? store}) : _store = store;

  static const _storeKey = 'shopping_list';

  final LocalStore? _store;
  final Set<String> _haveIds = {};
  final List<CustomShopItem> _custom = [];

  Set<String> get haveIds => Set.unmodifiable(_haveIds);
  List<CustomShopItem> get custom => List.unmodifiable(_custom);

  Future<void> loadFromStore() async {
    final json = await _store?.readJson(_storeKey);
    if (json == null) return;
    try {
      _haveIds
        ..clear()
        ..addAll(((json['have'] as List?) ?? const []).cast<String>());
      _custom
        ..clear()
        ..addAll(((json['custom'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(CustomShopItem.fromJson));
      notifyListeners();
    } catch (_) {/* best-effort */}
  }

  void _save() {
    _store?.writeJson(_storeKey, {
      'have': _haveIds.toList(),
      'custom': [for (final c in _custom) c.toJson()],
    });
  }

  bool has(String moduleId) => _haveIds.contains(moduleId);

  void toggle(String moduleId) {
    if (!_haveIds.remove(moduleId)) _haveIds.add(moduleId);
    _save();
    notifyListeners();
  }

  void addCustom(String name) {
    _custom.insert(0, CustomShopItem(name: name));
    _save();
    notifyListeners();
  }

  void toggleCustom(CustomShopItem item) {
    item.have = !item.have;
    _save();
    notifyListeners();
  }

  void removeCustom(CustomShopItem item) {
    _custom.remove(item);
    _save();
    notifyListeners();
  }
}
