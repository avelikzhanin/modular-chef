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

/// Обёртка «сеть → офлайн»: пробует основной генератор (бэкенд/LLM), а при
/// любой сетевой ошибке (нет DNS/интернета, сервер лёг) тихо собирает меню
/// офлайн-стабом — кнопка «Собрать меню» работает всегда.
class FallbackMenuGenerator implements MenuGenerator {
  const FallbackMenuGenerator({
    required this.primary,
    this.fallback = const StubMenuGenerator(),
  });

  final MenuGenerator primary;
  final MenuGenerator fallback;

  @override
  Future<WeeklyMenu> generate(
    GenerationRequest request, {
    required List<Module> modules,
    required List<Pairing> pairings,
  }) async {
    try {
      return await primary.generate(request,
          modules: modules, pairings: pairings);
    } catch (_) {
      // Сервер недоступен (DNS/сеть/5xx) — собираем офлайн.
      return fallback.generate(request, modules: modules, pairings: pairings);
    }
  }
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

    // Любимые сочетания шефа — приоритетные пары (идут первыми в пуле).
    final favPairings = request.favourites
        .map((f) => Pairing(
              proteinId: f.proteinId,
              sideId: f.sideId,
              sauceId: f.sauceId,
              tags: const ['favourite'],
              name: f.title,
            ))
        .toList();

    final pool = _PickedPool(
      byId: byId,
      proteins: pick(request.proteinIds),
      sides: pick(request.sideIds),
      soups: pick(request.soupIds),
      breakfasts: pick(request.breakfastIds),
      // Узкий авто-пул: 3 овоща и 3 простых соуса на всё меню — иначе
      // покупки требуют весь каталог соусов сразу.
      vegetables: _limitedPool(
          modules, ModuleCategory.vegetable,
          const ['broccoli', 'cherry_tomato', 'salad_mix']),
      sauces: _limitedPool(modules, ModuleCategory.sauce,
          const ['yogurt_sauce', 'pesto', 'tomato_sauce']),
      // Виды яиц и добавки — только те, что Шеф держит наготове.
      eggStyles: _prefer(
          modules.where((m) => m.category == ModuleCategory.eggStyle).toList(),
          request.eggStyleIds),
      eggAddins: _prefer(
          modules.where((m) => m.category == ModuleCategory.eggAddin).toList(),
          request.eggAddinIds),
      jarBases:
          modules.where((m) => m.category == ModuleCategory.jarBase).toList(),
      jarBarriers:
          modules.where((m) => m.category == ModuleCategory.jarBarrier).toList(),
      jarMiddles:
          modules.where((m) => m.category == ModuleCategory.jarMiddle).toList(),
      jarTops:
          modules.where((m) => m.category == ModuleCategory.jarTop).toList(),
      pairings: [
        // фавориты первыми → выбираются раньше каталожных пар
        ...favPairings,
        ...pairings.where((p) =>
            request.proteinIds.contains(p.proteinId) &&
            request.sideIds.contains(p.sideId)),
      ],
    );

    final allMeals = <PlannedMeal>[];
    final weeks = <MenuWeek>[];

    for (int weekIdx = 0; weekIdx < request.weeks.clamp(1, 3); weekIdx++) {
      final days = <DayPlan>[];
      for (int d = 0; d < _weekdays.length; d++) {
        final globalIdx = weekIdx * 7 + d;
        final (weekday, shortName) = _weekdays[d];
        final breakfast = _buildBreakfast(pool, globalIdx);
        // Выбранные супы идут обедом каждый третий день — иначе Шеф их
        // выбирает, а в меню и покупках они не появляются вовсе.
        final lunch = (pool.soups.isNotEmpty && globalIdx % 3 == 1)
            ? _buildSoupMeal(pool, globalIdx)
            : _buildMainMeal(pool, globalIdx);
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

  /// Оставляет только выбранное Шефом; пусто — берём всё, что есть.
  static List<Module> _prefer(List<Module> all, List<String> allowed) {
    if (allowed.isEmpty) return all;
    final picked = all.where((m) => allowed.contains(m.id)).toList();
    return picked.isEmpty ? all : picked;
  }

  /// Первые из [preferred], что есть в каталоге; добор до 3 из категории.
  static List<Module> _limitedPool(
      List<Module> modules, ModuleCategory cat, List<String> preferred) {
    final all = modules.where((m) => m.category == cat).toList();
    final out = <Module>[
      for (final id in preferred)
        ...all.where((m) => m.id == id),
    ];
    for (final m in all) {
      if (out.length >= 3) break;
      if (!out.contains(m)) out.add(m);
    }
    return out;
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
    // batch-тип завтрака: один и тот же тип на 2 дня подряд
    final type = pool.breakfasts[(dayIdx ~/ 2) % pool.breakfasts.length];

    // Яйца: вид + 1–2 добавки (по режиму готовка/подача).
    if (type.id == 'eggs' && pool.eggStyles.isNotEmpty) {
      final style = pool.eggStyles[dayIdx % pool.eggStyles.length];
      final serveOnly = style.tags.contains('serve_only');
      final addinPool = serveOnly
          ? pool.eggAddins.where((m) => m.tags.contains('serve')).toList()
          : pool.eggAddins;
      final comps = <MealComponent>[_comp(style, MealRole.eggStyle)];
      final picks = <Module>{};
      if (addinPool.isNotEmpty) {
        picks.add(addinPool[dayIdx % addinPool.length]);
        if (addinPool.length > 1) {
          picks.add(addinPool[(dayIdx + 2) % addinPool.length]);
        }
      }
      for (final a in picks) {
        comps.add(_comp(a, MealRole.addition));
      }
      final extra = picks.map((m) => m.name.toLowerCase()).join(', ');
      return PlannedMeal(
        title: extra.isEmpty ? style.name : '${style.name} · $extra',
        kind: MealKind.breakfast,
        components: comps,
        reheatMinutes: style.prepMinutes ?? 0,
        fromContainer: _containerFor(style),
      );
    }

    // Баночка: основа + прокладка + сочный слой + хруст (с учётом совместимости).
    if (type.id == 'jar' && pool.jarBases.isNotEmpty) {
      final base = pool.jarBases[dayIdx % pool.jarBases.length];
      final comps = <MealComponent>[_comp(base, MealRole.jarBase)];
      if (pool.jarBarriers.isNotEmpty) {
        comps.add(_comp(
            pool.jarBarriers[dayIdx % pool.jarBarriers.length],
            MealRole.jarBarrier));
      }
      Module? middle;
      if (pool.jarMiddles.isNotEmpty) {
        // кислый фрукт не кладём на молочную основу (свернётся при хранении)
        final dairy = base.tags.contains('dairy');
        final pl = dairy
            ? pool.jarMiddles.where((m) => !m.tags.contains('acidic')).toList()
            : pool.jarMiddles;
        final use = pl.isEmpty ? pool.jarMiddles : pl;
        middle = use[dayIdx % use.length];
        comps.add(_comp(middle, MealRole.jarMiddle));
      }
      Module? top;
      if (pool.jarTops.isNotEmpty) {
        top = pool.jarTops[dayIdx % pool.jarTops.length];
        comps.add(_comp(top, MealRole.jarTop));
      }
      final tail = [middle?.name, top?.name]
          .whereType<String>()
          .map((s) => s.toLowerCase())
          .join(', ');
      return PlannedMeal(
        title: tail.isEmpty ? base.name : '${base.name} · $tail',
        kind: MealKind.breakfast,
        components: comps,
        reheatMinutes: 0,
        fromContainer: 'холодильник',
      );
    }

    // Простой тип (сырники/каша/бутерброд/гранола).
    return PlannedMeal(
      title: type.name,
      kind: MealKind.breakfast,
      components: [_comp(type, MealRole.standalone)],
      reheatMinutes: type.prepMinutes ?? 0,
      fromContainer: _containerFor(type),
    );
  }

  /// Суп как отдельный обед: основа сварена заранее, из запасов.
  PlannedMeal _buildSoupMeal(_PickedPool pool, int slotIdx) {
    final soup = pool.soups[slotIdx % pool.soups.length];
    return PlannedMeal(
      title: soup.name,
      kind: MealKind.main,
      components: [_comp(soup, MealRole.standalone)],
      reheatMinutes: 5,
      fromContainer: _containerFor(soup),
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
    required this.eggStyles,
    required this.eggAddins,
    required this.jarBases,
    required this.jarBarriers,
    required this.jarMiddles,
    required this.jarTops,
  });
  final Map<String, Module> byId;
  final List<Module> proteins;
  final List<Module> sides;
  final List<Module> soups;
  final List<Module> breakfasts;
  final List<Module> vegetables;
  final List<Module> sauces;
  final List<Pairing> pairings;
  // конструктор завтрака
  final List<Module> eggStyles;
  final List<Module> eggAddins;
  final List<Module> jarBases;
  final List<Module> jarBarriers;
  final List<Module> jarMiddles;
  final List<Module> jarTops;
}
