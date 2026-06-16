import 'package:flutter/foundation.dart';

/// Предпочтения пользователя: чего избегать (аллергии/диета), вкусовой стиль
/// недели и лимит времени заготовки. Передаются в генератор меню и
/// подсвечиваются на экране меню.
class Preferences extends ChangeNotifier {
  final Set<String> _avoid = {};
  String? _weekStyle;
  int _prepLimitMinutes = 120;

  // Чего избегать: key → человеческая подпись (key совпадает с тем, что
  // ожидает промпт в правиле про аллергии: dairy/meat/...).
  static const List<(String, String)> avoidOptions = [
    ('dairy', 'молочка'),
    ('gluten', 'глютен'),
    ('nuts', 'орехи'),
    ('fish', 'рыба'),
    ('meat', 'мясо'),
    ('mushrooms', 'грибы'),
  ];

  // Вкусовой стиль недели (id шаблона).
  static const List<(String, String)> styleOptions = [
    ('mediterranean', 'Средиземноморский'),
    ('asian', 'Азиатский'),
    ('russian_classic', 'Русская классика'),
    ('mixed', 'Микс'),
  ];

  // Лимит времени воскресной заготовки.
  static const List<(int, String)> prepLimitOptions = [
    (60, '1 ч'),
    (120, '2 ч'),
    (180, '3 ч+'),
  ];

  Set<String> get avoid => _avoid;
  List<String> get avoidList => _avoid.toList(growable: false);
  String? get weekStyle => _weekStyle;
  int get prepLimitMinutes => _prepLimitMinutes;

  bool avoids(String key) => _avoid.contains(key);

  void toggleAvoid(String key) {
    _avoid.contains(key) ? _avoid.remove(key) : _avoid.add(key);
    notifyListeners();
  }

  void setWeekStyle(String? id) {
    _weekStyle = id;
    notifyListeners();
  }

  void setPrepLimit(int minutes) {
    _prepLimitMinutes = minutes;
    notifyListeners();
  }

  static String _avoidLabel(String key) =>
      avoidOptions.firstWhere((o) => o.$1 == key, orElse: () => (key, key)).$2;

  static String _styleLabel(String id) =>
      styleOptions.firstWhere((o) => o.$1 == id, orElse: () => (id, id)).$2;

  /// Короткие чипы для подсветки на экране меню («без молочки», «Азиатский», «до 2 ч»).
  List<String> get appliedChips {
    final chips = <String>[
      for (final k in _avoid) 'без ${_avoidLabel(k)}',
    ];
    if (_weekStyle != null) chips.add(_styleLabel(_weekStyle!));
    final limitLabel =
        prepLimitOptions.firstWhere((o) => o.$1 == _prepLimitMinutes, orElse: () => (_prepLimitMinutes, '')).$2;
    if (limitLabel.isNotEmpty) chips.add('до $limitLabel');
    return chips;
  }
}
