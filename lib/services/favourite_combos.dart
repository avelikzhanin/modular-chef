import 'package:flutter/foundation.dart';

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

  bool sameAs(ComboFav o) =>
      proteinId == o.proteinId && sideId == o.sideId && sauceId == o.sauceId;
}

/// Хранит любимые сочетания. Они передаются генератору как приоритетные пары.
/// Пока в памяти; persistence можно добавить позже.
class FavouriteCombos extends ChangeNotifier {
  final List<ComboFav> _items = [];

  List<ComboFav> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  /// true если добавили (не было дубля).
  bool add(ComboFav c) {
    if (_items.any((x) => x.sameAs(c))) return false;
    _items.add(c);
    notifyListeners();
    return true;
  }

  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }
}
