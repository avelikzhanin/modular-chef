import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/pairing.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/prompt_builder.dart';

/// Контракт генератора меню. `HttpMenuGenerator` (Stage 5) POST'ит запрос
/// в FastAPI-бэкенд и возвращает уже сгенерированный JSON от LLM.
abstract class MenuGenerator {
  Future<WeeklyMenu> generate(
    GenerationRequest request, {
    required List<Module> modules,
    required List<Pairing> pairings,
  });
}

/// Детерминированный stub: собирает полные тарелки (белок+гарнир+овощ+соус)
/// из пиков пользователя + автоподбор овощей/соусов из каталога. Без сети —
/// работает на телефоне и в тестах. Прод заменяет на сетевой генератор.
class StubMenuGenerator implements MenuGenerator {
  const StubMenuGenerator();

  static const _weekdays = [
    ('monday', 'Пн'),
    ('tuesday', 'Вт'),
    ('wednesday', 'Ср'),
    ('thursday', 'Чт'),
    ('friday', 'Пт'),
    ('saturday', 'Сб'),
    ('sunday', 'Вс'),
  ];

  @override
  Future<WeeklyMenu> generate(
    GenerationRequest request, {
    required List<Module> modules,
    required List<Pairing> pairings,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final byId = <String, Module>{for (final m in modules) m.id: m};
    List<Module> pick(List<String> ids) =>
        ids.map((id) => byId[id]).whereType<Module>().toList();

    final pool = _PickedPool(
      byId: byId,
      proteins: pick(request.proteinIds),
      sides: pick(request.sideIds),
      soups: pick(request.soupIds),
      breakfasts: pick(request.breakfastIds),
      vegetables:
          modules.where((m) => m.category == ModuleCategory.vegetable).toList(),
      sauces: modules.where((m) => m.category == ModuleCategory.sauce).toList(),
      pairings: pairings
          .where((p) =>
              request.proteinIds.contains(p.proteinId) &&
              request.sideIds.contains(p.sideId))
          .toList(),
    );

    final allMeals = <PlannedMeal>[];
    final weeks = <MenuWeek>[];

    for (int weekIdx = 0; weekIdx < 2; weekIdx++) {
      final days = <DayPlan>[];
      for (int d = 0; d < _weekdays.length; d++) {
        final globalIdx = weekIdx * 7 + d;
        final (weekday, shortName) = _weekdays[d];
        final breakfast = _buildBreakfast(pool, globalIdx);
        final lunch = _buildMainMeal(pool, globalIdx);
        final dinnerProtein =
            lunch.componentOf(MealRole.protein)?.moduleId;
        final dinner =
            _buildMainMeal(pool, globalIdx + 1, avoidProteinId: dinnerProtein);
        days.add(DayPlan(
          weekday: weekday,
          shortName: shortName,
          breakfast: breakfast,
          lunch: lunch,
          dinner: dinner,
        ));
        allMeals.addAll([breakfast, lunch, dinner]);
      }
      weeks.add(MenuWeek(
        index: weekIdx,
        name: 'Неделя ${weekIdx + 1}',
        days: days,
      ));
    }

    final uniqueTitles = allMeals.map((m) => m.title).toSet();
    final allModuleIds = allMeals.expand((m) => m.moduleIds).toSet();
    return WeeklyMenu(
      weeks: weeks,
      summary: MenuSummary(
        uniqueDishes: uniqueTitles.length,
        totalMeals: allMeals.length,
        modulesUsed: allModuleIds.length,
        flavourProfiles: _profilesFrom(pool.pairings),
      ),
    );
  }

  MealComponent _comp(Module m, MealRole role) =>
      MealComponent(moduleId: m.id, role: role, name: m.name, emoji: m.emoji);

  PlannedMeal _buildBreakfast(_PickedPool pool, int dayIdx) {
    if (pool.breakfasts.isEmpty) {
      return const PlannedMeal(
        title: 'Завтрак на выбор',
        kind: MealKind.breakfast,
        fromContainer: 'кладовая',
      );
    }
    // batch-завтрак: один и тот же на 2 дня подряд
    final b = pool.breakfasts[(dayIdx ~/ 2) % pool.breakfasts.length];
    return PlannedMeal(
      title: b.name,
      kind: MealKind.breakfast,
      components: [_comp(b, MealRole.standalone)],
      reheatMinutes: b.prepMinutes ?? 0,
      fromContainer: _containerFor(b),
    );
  }

  PlannedMeal _buildMainMeal(
    _PickedPool pool,
    int slotIdx, {
    String? avoidProteinId,
  }) {
    if (pool.proteins.isEmpty) {
      return const PlannedMeal(
        title: 'Выберите белки',
        fromContainer: 'каталог',
      );
    }

    final proteinPool = avoidProteinId == null
        ? pool.proteins
        : pool.proteins.where((p) => p.id != avoidProteinId).toList();
    final protein = (proteinPool.isEmpty ? pool.proteins : proteinPool)[
        slotIdx % (proteinPool.isEmpty ? pool.proteins : proteinPool).length];

    // подходящая pairing с этим белком (для гарнира/соуса/тегов)
    final matching =
        pool.pairings.where((p) => p.proteinId == protein.id).toList()
          ..sort((a, b) => a.sideId.compareTo(b.sideId));
    Pairing? pairing = matching.isNotEmpty ? matching[slotIdx % matching.length] : null;

    final components = <MealComponent>[_comp(protein, MealRole.protein)];

    // гарнир — из pairing или round-robin из пиков
    Module? side;
    if (pairing != null) side = pool.byId[pairing.sideId];
    side ??= pool.sides.isNotEmpty ? pool.sides[slotIdx % pool.sides.length] : null;
    if (side != null) components.add(_comp(side, MealRole.side));

    // овощ — автоподбор из каталога
    if (pool.vegetables.isNotEmpty) {
      final veg = pool.vegetables[slotIdx % pool.vegetables.length];
      components.add(_comp(veg, MealRole.vegetable));
    }

    // соус — из pairing или round-robin
    Module? sauce;
    if (pairing?.sauceId != null) sauce = pool.byId[pairing!.sauceId!];
    sauce ??= pool.sauces.isNotEmpty ? pool.sauces[slotIdx % pool.sauces.length] : null;
    if (sauce != null) components.add(_comp(sauce, MealRole.sauce));

    final title = pairing?.name ?? components.map((c) => c.name).join(' + ');

    return PlannedMeal(
      title: title,
      kind: MealKind.main,
      components: components,
      reheatMinutes: 2 + slotIdx % 3,
      fromContainer: _containerFor(protein),
    );
  }

  String _containerFor(Module m) {
    return switch (m.storage.zone.jsonValue) {
      'fridge' => 'холодильник',
      'freezer' => 'морозилка',
      'vacuum' => 'вакуум',
      'pantry' => 'кладовая',
      _ => '',
    };
  }

  List<String> _profilesFrom(List<Pairing> pairings) {
    final all = <String>{};
    for (final p in pairings) {
      all.addAll(p.tags);
    }
    return all.toList(growable: false);
  }
}

class _PickedPool {
  _PickedPool({
    required this.byId,
    required this.proteins,
    required this.sides,
    required this.soups,
    required this.breakfasts,
    required this.vegetables,
    required this.sauces,
    required this.pairings,
  });
  final Map<String, Module> byId;
  final List<Module> proteins;
  final List<Module> sides;
  final List<Module> soups;
  final List<Module> breakfasts;
  final List<Module> vegetables;
  final List<Module> sauces;
  final List<Pairing> pairings;
}
