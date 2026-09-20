import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/pairing.dart';

/// Одна подсказка по сборке тарелки.
/// [positive] = подтверждение (✓), иначе — совет/предупреждение (💡/⚠️).
class MealHint {
  const MealHint(this.text, {this.positive = false});
  final String text;
  final bool positive;
}

/// Чистые правила подсказок: сочетаемость main-тарелки (по матрице pairings)
/// и совместимость слоёв баночки (по тегам модулей). Без UI и состояния —
/// удобно тестировать.
class MealHints {
  const MealHints._();

  /// Подсказка для main-тарелки по выбранным белку/гарниру/соусу.
  /// [nameOf] — резолвер имени модуля по id (для красивых советов).
  static MealHint? mainPlate({
    required Module? protein,
    required Module? side,
    required Module? sauce,
    required List<Pairing> pairings,
    required String Function(String id) nameOf,
  }) {
    if (protein == null) return null;
    final forProtein =
        pairings.where((p) => p.proteinId == protein.id).toList();
    if (forProtein.isEmpty) return null;

    if (side == null) {
      final sides = _distinct(forProtein.map((p) => p.sideId)).take(2).toList();
      if (sides.isEmpty) return null;
      return MealHint(
        'К ${protein.name.toLowerCase()} хорошо идёт: '
        '${sides.map(nameOf).join(', ')}',
      );
    }

    final exact = forProtein.where((p) => p.sideId == side.id).toList();
    if (exact.isEmpty) {
      final sides = _distinct(forProtein.map((p) => p.sideId))
          .where((id) => id != side.id)
          .take(2)
          .toList();
      final tail = sides.isEmpty
          ? ''
          : ' — чаще берут ${sides.map(nameOf).join(', ')}';
      return MealHint(
        'Необычная пара: ${protein.name.toLowerCase()} + ${side.name.toLowerCase()}$tail',
      );
    }

    // Есть пара белок+гарнир. Смотрим соус.
    if (sauce == null) {
      final sauced = exact.firstWhere(
        (p) => p.sauceId != null,
        orElse: () => exact.first,
      );
      if (sauced.sauceId != null) {
        return MealHint('Добавь соус — отлично подойдёт ${nameOf(sauced.sauceId!)}');
      }
      return null;
    }

    final matchesSauce = exact.any((p) => p.sauceId == sauce.id);
    if (matchesSauce) {
      final tags = exact
          .firstWhere((p) => p.sauceId == sauce.id)
          .tags
          .where((t) => _flavourRu.containsKey(t))
          .map((t) => _flavourRu[t])
          .toList();
      final tail = tags.isEmpty ? '' : ' (${tags.join(', ')})';
      return MealHint('Проверенное сочетание$tail', positive: true);
    }

    // Соус другой — мягкий совет, без давления.
    final suggested = exact.firstWhere(
      (p) => p.sauceId != null,
      orElse: () => exact.first,
    );
    if (suggested.sauceId != null && suggested.sauceId != sauce.id) {
      return MealHint(
        'Можно и так. Классика к этой паре — ${nameOf(suggested.sauceId!)}',
      );
    }
    return const MealHint('Хорошее сочетание', positive: true);
  }

  /// Подсказки по слоям баночки (снизу вверх).
  static List<MealHint> jar({
    required Module? base,
    required Module? barrier,
    required Module? middle,
    required Module? top,
  }) {
    final hints = <MealHint>[];

    final middleJuicy = middle != null &&
        (middle.tags.contains('juicy') || middle.tags.contains('frozen'));

    if (middleJuicy && barrier == null) {
      hints.add(MealHint(
        'Сочный слой (${middle.name.toLowerCase()}) без прокладки зальёт основу — добавь прокладку',
      ));
    } else if (middleJuicy && barrier != null) {
      hints.add(const MealHint('Прокладка защитит основу от сока', positive: true));
    }

    if (base != null &&
        base.tags.contains('dairy') &&
        middle != null &&
        middle.tags.contains('acidic')) {
      hints.add(MealHint(
        '${middle.name} — кислый фрукт на молочной основе: съешь в день сборки, не храни 3–4 дня',
      ));
    }

    if (middle != null && middle.tags.contains('banana')) {
      hints.add(const MealHint('Банан темнеет — клади под прокладку или добавляй утром'));
    }

    if (top != null && top.tags.contains('crunchy')) {
      hints.add(MealHint('${top.name} — добавь утром, иначе размокнет'));
    }

    return hints;
  }

  static List<String> _distinct(Iterable<String> ids) {
    final seen = <String>{};
    final out = <String>[];
    for (final id in ids) {
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  static const _flavourRu = {
    'russian': 'русская',
    'mediterranean': 'средиземноморская',
    'italian': 'итальянская',
    'asian': 'азиатская',
    'comfort': 'комфорт',
    'classic': 'классика',
    'fresh': 'свежо',
    'spicy': 'остро',
    'favourite': 'любимое',
    'georgian': 'грузинская',
    'lean': 'лёгкая',
    'vegan': 'веган',
  };
}
