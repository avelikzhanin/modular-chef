import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/pairing.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/prompt_builder.dart';

/// Контракт генератора меню. Stage 5 даст `HttpMenuGenerator`,
/// который POST'ит запрос в FastAPI-бэкенд и возвращает уже
/// сгенерированный JSON от Claude.
abstract class MenuGenerator {
  Future<WeeklyMenu> generate(
    GenerationRequest request, {
    required List<Module> modules,
    required List<Pairing> pairings,
  });
}

/// Детерминированный stub: использует round-robin по пикам пользователя
/// и готовые pairings из каталога. Без сети — работает на телефоне
/// и в тестах. Stage 5 заменит на сетевой генератор.
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
    // Имитация работы — даёт UI шанс показать loader
    await Future.delayed(const Duration(milliseconds: 300));

    final byId = <String, Module>{for (final m in modules) m.id: m};
    final breakfasts = request.breakfastIds
        .map((id) => byId[id])
        .whereType<Module>()
        .toList();
    final picked = _PickedPool(
      proteins: request.proteinIds
          .map((id) => byId[id])
          .whereType<Module>()
          .toList(),
      sides:
          request.sideIds.map((id) => byId[id]).whereType<Module>().toList(),
      soups:
          request.soupIds.map((id) => byId[id]).whereType<Module>().toList(),
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
        final breakfast = _buildBreakfast(breakfasts, globalIdx);
        final lunch = _buildMainMeal(picked, globalIdx, allMeals,
            preferLightCarbs: false);
        final dinner = _buildMainMeal(picked, globalIdx + 1, allMeals,
            preferLightCarbs: true,
            // ужин не повторяется с обедом того же дня
            avoidProteinId: lunch.moduleIds.isNotEmpty ? lunch.moduleIds.first : null);
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
        flavourProfiles: _profilesFrom(picked.pairings),
      ),
    );
  }

  PlannedMeal _buildBreakfast(List<Module> breakfasts, int dayIdx) {
    if (breakfasts.isEmpty) {
      return const PlannedMeal(
        title: 'Завтрак на выбор',
        moduleIds: [],
        reheatMinutes: 0,
        fromContainer: 'кладовая',
      );
    }
    // batch-завтрак: один и тот же на 2-3 дня подряд
    final b = breakfasts[(dayIdx ~/ 2) % breakfasts.length];
    return PlannedMeal(
      title: '${b.name} — ${b.emoji}',
      moduleIds: [b.id],
      reheatMinutes: b.prepMinutes ?? 0,
      fromContainer: _containerFor(b),
    );
  }

  PlannedMeal _buildMainMeal(
    _PickedPool pool,
    int slotIdx,
    List<PlannedMeal> previous, {
    required bool preferLightCarbs,
    String? avoidProteinId,
  }) {
    if (pool.proteins.isEmpty) {
      return const PlannedMeal(
        title: 'Выберите белки',
        moduleIds: [],
        reheatMinutes: 0,
        fromContainer: 'каталог',
      );
    }

    // выбираем белок с round-robin, избегая повтор подряд
    final proteinPool = avoidProteinId == null
        ? pool.proteins
        : pool.proteins.where((p) => p.id != avoidProteinId).toList();
    final protein = proteinPool.isEmpty
        ? pool.proteins[slotIdx % pool.proteins.length]
        : proteinPool[slotIdx % proteinPool.length];

    // если есть готовая pairing с этим белком — используем её
    final pairing = pool.pairings
        .where((p) => p.proteinId == protein.id)
        .toList()
      ..sort((a, b) => a.proteinId.compareTo(b.proteinId));
    if (pairing.isNotEmpty) {
      final pick = pairing[slotIdx % pairing.length];
      final title = pick.name ??
          [
            protein.name,
            pool.sides.firstWhere(
              (s) => s.id == pick.sideId,
              orElse: () => protein,
            ).name,
            if (pick.sauceId != null) _sauceLabel(pick.sauceId!),
          ].join(' + ');
      return PlannedMeal(
        title: title,
        moduleIds: [
          pick.proteinId,
          pick.sideId,
          if (pick.sauceId != null) pick.sauceId!,
        ],
        reheatMinutes: 2 + slotIdx % 3,
        fromContainer: _containerFor(protein),
      );
    }

    // fallback: round-robin белок × гарнир
    if (pool.sides.isEmpty) {
      return PlannedMeal(
        title: protein.name,
        moduleIds: [protein.id],
        reheatMinutes: 2,
        fromContainer: _containerFor(protein),
      );
    }
    final side = pool.sides[slotIdx % pool.sides.length];
    return PlannedMeal(
      title: '${protein.name} + ${side.name}',
      moduleIds: [protein.id, side.id],
      reheatMinutes: 2 + slotIdx % 3,
      fromContainer: _containerFor(protein),
    );
  }

  String _containerFor(Module m) {
    final z = m.storage.zone;
    return switch (z.jsonValue) {
      'fridge' => 'холодильник',
      'freezer' => 'морозилка',
      'vacuum' => 'вакуум',
      'pantry' => 'кладовая',
      _ => '',
    };
  }

  String _sauceLabel(String sauceId) {
    // Простая маркировка — генератор не знает имя соуса без модуля.
    // Stage 5 (реальный Claude) подставит человеческое имя.
    return sauceId.replaceAll('_', ' ');
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
    required this.proteins,
    required this.sides,
    required this.soups,
    required this.pairings,
  });
  final List<Module> proteins;
  final List<Module> sides;
  final List<Module> soups;
  final List<Pairing> pairings;
}
