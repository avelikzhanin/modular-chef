import 'package:flutter/foundation.dart';
import 'package:modular_chef/services/local_store.dart';

/// Любимое сочетание шефа: тройка белок+гарнир(+соус) с человеческим названием.
@immutable
class ComboFav {
  const ComboFav({
    required this.proteinId,
    required this.sideId,
    required this.title,
    this.sauceId,
  });

  final String proteinId;
  final String sideId;
  final String? sauceId;
  final String title;

  Map<String, dynamic> toJson() => {
        'protein': proteinId,
        'side': sideId,
        if (sauceId != null) 'sauce': sauceId,
      };

  Map<String, dynamic> toStoreJson() => {...toJson(), 'title': title};

  factory ComboFav.fromStoreJson(Map<String, dynamic> json) => ComboFav(
        proteinId: json['protein'] as String,
        sideId: json['side'] as String,
        sauceId: json['sauce'] as String?,
        title: (json['title'] as String?) ?? '',
      );

  bool sameAs(ComboFav o) =>
      proteinId == o.proteinId && sideId == o.sideId && sauceId == o.sauceId;
}

/// Хранит любимые сочетания. Они передаются генератору как приоритетные пары.
/// Сохраняется локально, переживает перезапуск.
class FavouriteCombos extends ChangeNotifier {
  FavouriteCombos({LocalStore? store}) : _store = store;

  static const _storeKey = 'favourite_combos';

  final LocalStore? _store;

  Future<void> loadFromStore() async {
    final json = await _store?.readJson(_storeKey);
    if (json == null) return;
    try {
      _items
        ..clear()
        ..addAll(((json['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ComboFav.fromStoreJson));
      notifyListeners();
    } catch (_) {/* best-effort */}
  }

  void _save() {
    _store?.writeJson(_storeKey, {
      'items': [for (final c in _items) c.toStoreJson()],
    });
  }

  final List<ComboFav> _items = [];

  List<ComboFav> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  /// true если добавили (не было дубля).
  bool add(ComboFav c) {
    if (_items.any((x) => x.sameAs(c))) return false;
    _items.add(c);
    _save();
    notifyListeners();
    return true;
  }

  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _save();
      notifyListeners();
    }
  }

  bool contains(String proteinId, String sideId, String? sauceId) =>
      _items.any((x) =>
          x.proteinId == proteinId &&
          x.sideId == sideId &&
          x.sauceId == sauceId);

  /// Добавляет, если нет; убирает, если есть. true = добавили.
  bool toggle(ComboFav c) {
    final i = _items.indexWhere((x) => x.sameAs(c));
    if (i >= 0) {
      _items.removeAt(i);
      _save();
      notifyListeners();
      return false;
    }
    _items.add(c);
    _save();
    notifyListeners();
    return true;
  }
}
