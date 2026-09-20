import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/active_menu.dart';
import 'package:modular_chef/services/app_settings.dart';
import 'package:modular_chef/services/breakfast_preps.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/my_dishes.dart';
import 'package:modular_chef/services/purchase_catalog.dart';
import 'package:modular_chef/services/shopping_list.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/theme/module_visuals.dart';
import 'package:modular_chef/widgets/atmospheric_header.dart';
import 'package:modular_chef/widgets/leaf_button.dart';
import 'package:modular_chef/widgets/fade_in_up.dart';

/// Шеф-экран «Список покупок»: позиции собираются из утверждённого меню
/// (уникальные продукты × число блюд), отметки «уже есть» и свои пункты
/// сохраняются локально. Без меню — демо-пример.
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _Item {
  _Item(this.name, this.qty,
      {this.iconId, this.have = false, this.onToggle, this.section = 'Прочее'});
  final String name;
  final String qty;
  final String? iconId; // id модуля для акварельной иконки
  bool have;
  final VoidCallback? onToggle;
  final String section; // отдел магазина
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  /// 0 / 1 — конкретная неделя, 2 — обе сразу.
  int _weekIndex = 0;

  /// Закупка с запасом ×2 — под заготовки впрок в морозилку.
  bool _stockUp = false;

  /// Бульон для супов: варим концентрат сами или покупаем готовый.
  bool _buyBroth = false;

  // Итог веса, накапливается при расчёте списка.
  int _lastGrams = 0;
  int _lastMl = 0;

  // Демо-набор для состояния «меню ещё не утверждено».
  late final List<_Item> _demo = [
    _Item('Куриное филе', '600 г', iconId: 'chicken_breast'),
    _Item('Рис Басмати', '1 упак.', iconId: 'rice'),
    _Item('Брокколи', '2 шт.', iconId: 'broccoli'),
    _Item('Греческий йогурт', '250 г', iconId: 'yogurt_sauce'),
    _Item('Оливковое масло', 'Дома', have: true),
    _Item('Черри', 'Дома', iconId: 'cherry_tomato', have: true),
  ];

  /// Граммы (или мл для супов) закупки: блюда × человек × порция × множитель.
  int? _grams(Module m, int meals, int people) {
    final perPortion = switch (m.category) {
      ModuleCategory.protein => 150,
      ModuleCategory.side => 70, // сухая крупа/паста
      ModuleCategory.vegetable => 100,
      ModuleCategory.soup => 300, // мл готового
      ModuleCategory.sauce => 30,
      _ => 0,
    };
    if (perPortion == 0) return null;
    return perPortion * meals * people * (_stockUp ? 2 : 1);
  }

  static String _fmt(int total, {bool liquid = false}) {
    final unitBig = liquid ? 'л' : 'кг';
    final unitSmall = liquid ? 'мл' : 'г';
    return total >= 1000
        ? '≈${(total / 1000).toStringAsFixed(1).replaceAll('.', ',')} $unitBig'
        : '≈$total $unitSmall';
  }

  String? _volume(Module m, int meals, int people) {
    final g = _grams(m, meals, people);
    if (g == null) return null;
    return _fmt(g, liquid: m.category == ModuleCategory.soup);
  }

  static String _slotLabel(MealSlot s) => switch (s) {
        MealSlot.breakfast => 'завтраки',
        MealSlot.lunch => 'обеды',
        MealSlot.dinner => 'ужины',
        MealSlot.snack => 'перекусы',
      };

  /// Позиции из утверждённого меню — уже как ПРОДУКТЫ для магазина:
  ///  - виды яиц (глазунья, скрэмбл…) схлопываются в «Яйца» штуками;
  ///  - супы и домашние соусы раскрываются в ингредиенты;
  ///  - покупные соусы считаются банками.
  /// Какой бульон нужен супу (пусто — суп холодный или сам бульон).
  static String _brothFor(Module soup) {
    if (soup.tags.contains('broth') || soup.tags.contains('cold')) return '';
    return switch (soup.id) {
      'borscht' || 'shchi' || 'kharcho' => 'beef_broth',
      'ukha' || 'tom_yum' => 'fish_broth',
      _ => soup.tags.contains('vegan') ? 'vegetable_broth' : 'chicken_broth',
    };
  }

  List<_Item> _menuItems(WeeklyMenu menu, CatalogService catalog,
      ShoppingList list, int people, int breakfastEaters,
      {List<(String, List<Ingredient>)> extraIngredients = const []}) {
    final counts = <String, int>{};
    final uses = <String, Set<String>>{};
    var eggMeals = 0;
    _lastGrams = 0;
    _lastMl = 0;
    // Считаем только выбранную неделю — закупаться на 14 дней сразу страшно.
    final weeks = _weekIndex >= menu.weeks.length
        ? menu.weeks
        : [menu.weeks[_weekIndex]];
    for (final week in weeks) {
      for (final day in week.days) {
        for (final slot in MealSlot.values) {
          final meal = day.mealAt(slot);
          if (meal == null) continue;
          for (final id in meal.moduleIds) {
            final mod = catalog.moduleById(id);
            // «Глазунья» — не покупка. Покупка — яйца.
            if (mod?.category == ModuleCategory.eggStyle) {
              eggMeals++;
              continue;
            }
            counts[id] = (counts[id] ?? 0) + 1;
            (uses[id] ??= {}).add(_slotLabel(slot));
          }
        }
      }
    }

    final items = <_Item>[];
    // Ингредиенты дедуплицируем по имени, назначения складываем.
    final ingQty = <String, String>{};
    final ingUses = <String, Set<String>>{};
    final ingSection = <String, String>{};

    void addIngredients(List<Ingredient> list_, String forWhat) {
      for (final ing in list_) {
        ingQty[ing.name] ??= ing.qty;
        ingSection[ing.name] ??= ing.section;
        (ingUses[ing.name] ??= {}).add(forWhat);
      }
    }

    for (final e in counts.entries) {
      final m = catalog.moduleById(e.key);
      if (m == null) continue;
      final use = (uses[e.key] ?? const <String>{}).join(', ');

      final soupIngs = kSoupIngredients[m.id];
      if (soupIngs != null) {
        addIngredients(soupIngs, 'суп «${m.name}»');
        continue; // сам суп не покупается — варим основу
      }
      final sauceIngs = kHomemadeSauceIngredients[m.id];
      if (sauceIngs != null) {
        addIngredients(sauceIngs, 'соус «${m.name}»');
        continue; // домашний соус = ингредиенты
      }
      String qty;
      if (m.category == ModuleCategory.sauce) {
        final jars =
            ((30 * e.value * people * (_stockUp ? 2 : 1)) / 250).ceil();
        qty = '$jars бан.';
      } else {
        final g = _grams(m, e.value, people);
        if (g != null) {
          if (m.category == ModuleCategory.soup) {
            _lastMl += g;
          } else {
            _lastGrams += g;
          }
        }
        qty = _volume(m, e.value, people) ??
            '${e.value} ${_mealsWord(e.value)}';
      }
      items.add(_Item(
        m.name,
        [qty, if (use.isNotEmpty) 'на $use'].join(' · '),
        iconId: m.id,
        have: list.has(m.id),
        onToggle: () => list.toggle(m.id),
        section: shopSection(m),
      ));
    }

    // Яйца из всех «глазуний и скрэмблов» — одной строкой, штуками.
    // Считаем по числу завтракающих, а не всей семьи.
    if (eggMeals > 0 && breakfastEaters > 0) {
      items.add(_Item(
        'Яйца',
        '~${eggMeals * breakfastEaters + 2} шт · на завтраки',
        iconId: 'eggs',
        have: list.has('eggs'),
        onToggle: () => list.toggle('eggs'),
        section: 'Молочное, сыры и яйца',
      ));
    }

    for (final (forWhat, ings) in extraIngredients) {
      addIngredients(ings, forWhat);
    }

    for (final name in ingQty.keys) {
      final key = 'ing:$name';
      items.add(_Item(
        name,
        '${ingQty[name]} · ${(ingUses[name] ?? const <String>{}).join(', ')}',
        iconId: kIngredientIcons[name],
        have: list.has(key),
        onToggle: () => list.toggle(key),
        section: ingSection[name] ?? 'Прочее',
      ));
    }
    return items;
  }

  static String _mealsWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'блюдо';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'блюда';
    }
    return 'блюд';
  }

  static String _peopleWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'человека';
    return 'человек';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final menu = context.watch<ActiveMenu>().menu;
    final catalog = context.watch<CatalogService>();
    final list = context.watch<ShoppingList>();
    final settings = context.watch<AppSettings>();
    final people = settings.householdSize;
    final breakfastEaters = settings.breakfastEaters;
    final live = menu != null && catalog.isLoaded;

    // Бульоны для супов выбранных недель: сварить (ингредиенты) или купить.
    final brothIds = <String>{};
    if (live) {
      final weeks = _weekIndex >= menu.weeks.length
          ? menu.weeks
          : [menu.weeks[_weekIndex]];
      for (final week in weeks) {
        for (final day in week.days) {
          for (final slot in MealSlot.values) {
            final meal = day.mealAt(slot);
            if (meal == null) continue;
            for (final id in meal.moduleIds) {
              final m = catalog.moduleById(id);
              if (m?.category == ModuleCategory.soup) {
                final b = _brothFor(m!);
                if (b.isNotEmpty) brothIds.add(b);
              }
            }
          }
        }
      }
    }

    final menuItems = live
        ? _menuItems(menu, catalog, list, people, breakfastEaters,
            extraIngredients: !_buyBroth
                ? [
                    for (final b in brothIds)
                      if (kSoupIngredients[b] != null &&
                          catalog.moduleById(b) != null)
                        (
                          'бульон «${catalog.moduleById(b)!.name}»',
                          kSoupIngredients[b]!,
                        ),
                  ]
                : const [])
        : const <_Item>[];
    final seen = <String>{
      for (final i in menuItems)
        if (i.iconId != null) i.iconId!,
    };

    _Item? extra(String id, String reason) {
      final m = catalog.moduleById(id);
      if (m == null || !seen.add(id)) return null;
      return _Item(m.name, reason,
          iconId: m.id,
          have: list.has(m.id),
          onToggle: () => list.toggle(m.id),
          section: shopSection(m));
    }

    // Состав «Моих блюд», отмеченных на неделю, — тоже в список.
    final dishItems = <_Item>[];
    if (catalog.isLoaded) {
      for (final d in context.watch<MyDishes>().thisWeek) {
        for (final id in d.moduleIds) {
          final it = extra(id, '«${d.name}»');
          if (it != null) dishItems.add(it);
        }
      }
    }

    // Заготовки завтраков: яйца, начинки бутербродов, каши, слои банок.
    final breakfastItems = <_Item>[];
    if (catalog.isLoaded) {
      final preps = context.watch<BreakfastPreps>();
      if (preps.eggStyleIds.isNotEmpty) {
        final it = extra('eggs', 'на завтраки · ~${people * 7} шт в неделю');
        if (it != null) breakfastItems.add(it);
      }
      for (final id in [
        ...preps.sandwichFillingIds,
        ...preps.sandwichSpreadIds,
        ...preps.porridgeKindIds,
        ...preps.porridgeAddinIds,
        ...preps.eggAddinIds,
      ]) {
        final it = extra(id, 'на завтраки');
        if (it != null) breakfastItems.add(it);
      }
      // Бутерброды затеяны — значит нужен хлеб.
      if (preps.sandwichBreadPreps.isNotEmpty ||
          preps.sandwichSpreadIds.isNotEmpty ||
          preps.sandwichFillingIds.isNotEmpty) {
        breakfastItems.add(_Item(
          'Хлеб',
          'на бутерброды',
          iconId: 'ing_bread',
          have: list.has('ing:Хлеб'),
          onToggle: () => list.toggle('ing:Хлеб'),
          section: 'Хлеб и выпечка',
        ));
      }
      for (final jar in preps.jars) {
        for (final c in jar.components) {
          final it = extra(c.moduleId, 'банки');
          if (it != null) breakfastItems.add(it);
        }
      }
    }

    // Купить готовый бульон вместо варки.
    final brothItems = <_Item>[
      if (live && _buyBroth)
        for (final b in brothIds)
          if (catalog.moduleById(b) != null)
            _Item(
              '${catalog.moduleById(b)!.name} (готовый)',
              '1–2 л · для супов',
              iconId: b,
              have: list.has('ing:Бульон $b'),
              onToggle: () => list.toggle('ing:Бульон $b'),
              section: 'Соусы и бакалея',
            ),
    ];

    final items = <_Item>[
      if (live) ...menuItems else ..._demo,
      ...brothItems,
      ...dishItems,
      ...breakfastItems,
      for (final c in list.custom)
        _Item(c.name, c.qty,
            have: c.have, onToggle: () => list.toggleCustom(c)),
    ];
    final toBuy = items.where((i) => !i.have).toList();
    final have = items.where((i) => i.have).toList();
    final haveCount = have.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
            children: [
              AtmosphericHeader(
                title: 'Список покупок',
                subtitle: live
                    ? 'Собран из твоего меню — отметь, что уже есть дома'
                    : 'Всё для недели в одном списке — отметь, что уже есть дома',
                background: 'assets/art/bg_shopping.png',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              if (!live) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.lightLeaf.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Утверди меню на 2 недели — и список соберётся из него сам. Пока показываю пример.',
                    style: tt.bodySmall
                        ?.copyWith(color: AppColors.leafDeep, height: 1.35),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.lightLeaf.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '👨‍👩‍👧 Готовим на $people ${_peopleWord(people)}, завтракают $breakfastEaters.'
                    '${_lastGrams > 0 ? ' Итого ${_fmt(_lastGrams)}' : ''}'
                    '${_lastMl > 0 ? ' + супы ${_fmt(_lastMl, liquid: true)}' : ''}. Изменить: Профиль → Настройки.',
                    style: tt.bodySmall
                        ?.copyWith(color: AppColors.leafDeep, height: 1.35),
                  ),
                ),
                // Закупка по неделям — сколько их в меню, столько и вкладок.
                if (menu.weeks.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      for (final (i, label) in [
                        for (int w = 0; w < menu.weeks.length; w++)
                          (w, 'Неделя ${w + 1}'),
                        (menu.weeks.length, 'Все'),
                      ]) ...[
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _weekIndex = i),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _weekIndex == i
                                    ? AppColors.primaryContainer
                                    : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(label,
                                  style: tt.labelLarge?.copyWith(
                                    color: _weekIndex == i
                                        ? AppColors.onPrimaryContainer
                                        : AppColors.onSurfaceVariant,
                                    fontWeight: _weekIndex == i
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  )),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ]),
                  ),
                // Бульон для супов: концентрат сами или готовый из магазина.
                if (brothIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Text('🍲 Бульон:',
                          style: tt.labelLarge?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      for (final (buy, label) in const [
                        (false, 'Сварю сам'),
                        (true, 'Куплю готовый'),
                      ]) ...[
                        InkWell(
                          onTap: () => setState(() => _buyBroth = buy),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: _buyBroth == buy
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(label,
                                style: tt.labelMedium?.copyWith(
                                  color: _buyBroth == buy
                                      ? AppColors.onPrimaryContainer
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: _buyBroth == buy
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                )),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ]),
                  ),
                // Впрок ×2 + итог + копирование.
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: [
                    InkWell(
                      onTap: () => setState(() => _stockUp = !_stockUp),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _stockUp
                              ? AppColors.clay
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('📦 Впрок ×2',
                            style: tt.labelLarge?.copyWith(
                              color: _stockUp
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => _copyList(context, toBuy),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.lightLeaf,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.copy_rounded,
                              size: 15, color: AppColors.leafDeep),
                          const SizedBox(width: 5),
                          Text('Скопировать',
                              style: tt.labelLarge?.copyWith(
                                  color: AppColors.leafDeep,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ],
              // Купить
              FadeInUp(
                delayMs: 70,
                child: _sectionHeader(
                  tt,
                  icon: Icons.shopping_basket_rounded,
                  iconColor: AppColors.primary,
                  title: 'Купить',
                  titleColor: AppColors.onSurface,
                  count: '${toBuy.length} поз.',
                ),
              ),
              const SizedBox(height: 14),
              // Покупки сгруппированы по отделам магазина.
              for (final section in {...kShopSections}) ...[
                Builder(builder: (_) {
                  final rows =
                      toBuy.where((i) => i.section == section).toList();
                  if (rows.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 8),
                        child: Text(section.toUpperCase(),
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.leafDeep,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            )),
                      ),
                      for (final item in rows) ...[
                        _BuyRow(
                            item: item,
                            onToggle: item.onToggle ??
                                (() => setState(
                                    () => item.have = !item.have))),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }),
              ],
              const SizedBox(height: 20),

              // Дома — запасы
              FadeInUp(
                delayMs: 140,
                child: _sectionHeader(
                  tt,
                  icon: Icons.home_rounded,
                  iconColor: AppColors.onSurfaceVariant,
                  title: 'Дома — запасы',
                  titleColor: AppColors.onSurfaceVariant,
                  count: '${have.length} предмета',
                ),
              ),
              const SizedBox(height: 14),
              for (final item in have) ...[
                _HaveRow(
                    item: item,
                    onToggle: item.onToggle ??
                        (() => setState(() => item.have = !item.have))),
                const SizedBox(height: 10),
              ],
                  ],
                ),
              ),
            ],
          ),

          // Липкий футер прогресса
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E1BC),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x1A2E2620),
                      blurRadius: 24,
                      offset: Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ВАШ ПРОГРЕСС',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.leafDeep,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            )),
                        Text('куплено $haveCount из ${items.length}',
                            style: tt.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 132,
                    child: LeafButton(
                      onPressed: _addProduct,
                      height: 44,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add,
                              size: 18, color: AppColors.onPrimaryContainer),
                          const SizedBox(width: 6),
                          Text('Добавить',
                              style: tt.titleSmall?.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(TextTheme tt,
          {required IconData icon,
          required Color iconColor,
          required String title,
          required Color titleColor,
          required String count}) =>
      Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: tt.titleMedium?.copyWith(
                    color: titleColor, fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE4D9C6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(count,
                style: tt.labelSmall
                    ?.copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ],
      );

  /// Список текстом в буфер — отправить в мессенджер тому, кто в магазине.
  void _copyList(BuildContext context, List<_Item> toBuy) {
    final buf = StringBuffer('🛒 Список покупок:\n');
    for (final section in {...kShopSections}) {
      final rows = toBuy.where((i) => i.section == section).toList();
      if (rows.isEmpty) continue;
      buf.writeln('\n$section:');
      for (final r in rows) {
        buf.writeln('– ${r.name} · ${r.qty}');
      }
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Список скопирован — вставь в любой мессенджер'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addProduct() async {
    final controller = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Добавить продукт',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Например, сливки 20%',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            const SizedBox(height: 16),
            LeafButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              label: 'Добавить',
              height: 48,
            ),
          ],
        ),
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      context.read<ShoppingList>().addCustom(name);
    }
  }
}

Widget _itemIcon(_Item item, {double size = 44, double opacity = 1}) {
  final img = item.iconId != null ? moduleImage(item.iconId!) : null;
  return Opacity(
    opacity: opacity,
    child: SizedBox(
      width: size,
      height: size,
      child: img != null
          ? Image.asset(img, fit: BoxFit.contain)
          : const Icon(Icons.local_mall_outlined,
              color: AppColors.onSurfaceVariant, size: 26),
    ),
  );
}

class _BuyRow extends StatelessWidget {
  const _BuyRow({required this.item, required this.onToggle});
  final _Item item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowTint,
                blurRadius: 24,
                offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            ),
            const SizedBox(width: 14),
            _itemIcon(item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: tt.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600)),
                  Text(item.qty,
                      style: tt.labelSmall
                          ?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.delete_outline,
                size: 20, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _HaveRow extends StatelessWidget {
  const _HaveRow({required this.item, required this.onToggle});
  final _Item item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
              ),
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 14),
            _itemIcon(item, opacity: 0.6),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: tt.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.onSurfaceVariant,
                      )),
                  Text('Дома',
                      style: tt.labelSmall
                          ?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.restore,
                size: 20, color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }
}
