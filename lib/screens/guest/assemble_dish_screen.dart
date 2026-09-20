import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/screens/chef/breakfast_detail_screens.dart'
    show kPorridgeAddinIds, kSandwichSpreadIds;
import 'package:modular_chef/services/active_menu.dart';
import 'package:modular_chef/services/app_settings.dart';
import 'package:modular_chef/services/breakfast_preps.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/meal_hints.dart';
import 'package:modular_chef/services/pantry_stock.dart';
import 'package:modular_chef/services/today_plan.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/widgets/leaf_button.dart';
import 'package:modular_chef/widgets/module_picker_row.dart';

/// Гостевая активная сборка тарелки из запасов под конкретный слот.
///  - обед/ужин → белок(+гарнир+овощ+соус) с подсказками сочетаний;
///  - завтрак → из заготовок Шефа (готовые банки / выбранные яйца), а если
///    Шеф ничего не заготовил — конструктор из каталога;
///  - перекус → одно блюдо.
class AssembleDishScreen extends StatefulWidget {
  const AssembleDishScreen({super.key, required this.slot});
  final MealSlot slot;

  @override
  State<AssembleDishScreen> createState() => _AssembleDishScreenState();
}

class _AssembleDishScreenState extends State<AssembleDishScreen> {
  final Map<MealRole, Module> _picked = {};
  Module? _bType;
  Module? _eggStyle;
  final Set<String> _eggAddins = {};
  Module? _jarBase, _jarBarrier, _jarMiddle, _jarTop;
  PlannedMeal? _selectedJar; // готовая банка из заготовок Шефа
  Module? _porridgeKind; // какая каша
  final Set<String> _porridgeAddins = {}; // с чем каша
  final Set<String> _sandwichFillings = {}; // что сверху
  final Set<String> _sandwichSpreads = {}; // намазка

  MealKind get _kind => switch (widget.slot) {
        MealSlot.breakfast => MealKind.breakfast,
        MealSlot.snack => MealKind.snack,
        MealSlot.lunch || MealSlot.dinner => MealKind.main,
      };

  bool get _isMain => _kind == MealKind.main;
  bool get _isBreakfast => _kind == MealKind.breakfast;
  bool get _isEggs => _bType?.id == 'eggs';
  bool get _isJar => _bType?.id == 'jar';

  bool _ready(BreakfastPreps preps) {
    if (_isMain) return _picked.containsKey(MealRole.protein);
    if (_isBreakfast) {
      if (_bType == null) return false;
      if (_isEggs) return _eggStyle != null;
      if (_isJar) return preps.hasJars ? _selectedJar != null : _jarBase != null;
      return true;
    }
    return _picked.containsKey(MealRole.standalone);
  }

  void _toggleSingle(MealRole role, Module m) {
    setState(() {
      if (_picked[role]?.id == m.id) {
        _picked.remove(role);
      } else {
        _picked[role] = m;
      }
    });
  }

  // ---- сборка результата ----------------------------------------------------

  void _done(BuildContext context) {
    final PlannedMeal meal = switch (_kind) {
      MealKind.main => _buildMain(),
      MealKind.breakfast => _buildBreakfast(),
      _ => _buildSnack(),
    };
    // Порции уходят из запасов (по одной на человека);
    // готовую банку забираем из заготовок Шефа.
    final stock = context.read<PantryStock>();
    final settings = context.read<AppSettings>();
    final people = widget.slot == MealSlot.breakfast
        ? settings.breakfastEaters
        : settings.householdSize;
    for (final c in meal.components) {
      stock.consume(c.moduleId, people);
    }
    if (_isJar && _selectedJar != null) {
      context.read<BreakfastPreps>().removeJar(_selectedJar!);
    }
    context.read<TodayPlan>().setMeal(widget.slot, meal);
    Navigator.maybePop(context);
  }

  PlannedMeal _buildMain() {
    const order = [MealRole.protein, MealRole.side, MealRole.vegetable, MealRole.sauce];
    final components = <MealComponent>[];
    for (final role in order) {
      final m = _picked[role];
      if (m != null) components.add(_comp(m, role));
    }
    final protein = _picked[MealRole.protein];
    return PlannedMeal(
      title: components.map((c) => c.name).join(' + '),
      kind: MealKind.main,
      components: components,
      reheatMinutes: 2,
      fromContainer: protein != null ? _containerFor(protein) : '',
    );
  }

  PlannedMeal _buildBreakfast() {
    final catalog = context.read<CatalogService>();

    // Готовая банка из заготовок Шефа — берём как есть.
    if (_isJar && _selectedJar != null) {
      return _selectedJar!.copyWith(reheatMinutes: 0, fromContainer: 'холодильник');
    }

    final components = <MealComponent>[];
    String title;
    Module? anchor = _bType;

    if (_isEggs && _eggStyle != null) {
      anchor = _eggStyle;
      components.add(_comp(_eggStyle!, MealRole.eggStyle));
      final addins = catalog
          .modulesByCategory(ModuleCategory.eggAddin)
          .where((m) => _eggAddins.contains(m.id));
      for (final a in addins) {
        components.add(_comp(a, MealRole.addition));
      }
      final extra = addins.map((m) => m.name.toLowerCase()).join(', ');
      title = extra.isEmpty ? _eggStyle!.name : '${_eggStyle!.name} · $extra';
    } else if (_isJar && _jarBase != null) {
      anchor = _jarBase;
      components.add(_comp(_jarBase!, MealRole.jarBase));
      if (_jarBarrier != null) components.add(_comp(_jarBarrier!, MealRole.jarBarrier));
      if (_jarMiddle != null) components.add(_comp(_jarMiddle!, MealRole.jarMiddle));
      if (_jarTop != null) components.add(_comp(_jarTop!, MealRole.jarTop));
      final tail = [_jarMiddle?.name, _jarTop?.name]
          .whereType<String>()
          .map((s) => s.toLowerCase())
          .join(', ');
      title = tail.isEmpty ? _jarBase!.name : '${_jarBase!.name} · $tail';
    } else if (_bType?.id == 'porridge' && _porridgeKind != null) {
      anchor = _porridgeKind;
      components.add(_comp(_porridgeKind!, MealRole.standalone));
      final catalogP = context.read<CatalogService>();
      final addinNames = <String>[];
      for (final id in _porridgeAddins) {
        final m = catalogP.moduleById(id);
        if (m != null) {
          components.add(_comp(m, MealRole.addition));
          addinNames.add(m.name.toLowerCase());
        }
      }
      title = addinNames.isEmpty
          ? 'Каша ${_porridgeKind!.name.toLowerCase()}'
          : 'Каша ${_porridgeKind!.name.toLowerCase()} · ${addinNames.join(', ')}';
    } else if (_bType?.id == 'sandwiches') {
      anchor = _bType;
      components.add(_comp(_bType!, MealRole.standalone));
      final catalog2 = context.read<CatalogService>();
      final names = <String>[];
      for (final id in [..._sandwichSpreads, ..._sandwichFillings]) {
        final m = catalog2.moduleById(id);
        if (m != null) {
          components.add(_comp(m, MealRole.addition));
          names.add(m.name.toLowerCase());
        }
      }
      title = names.isEmpty ? 'Бутерброд' : 'Бутерброд · ${names.join(', ')}';
    } else {
      components.add(_comp(_bType!, MealRole.standalone));
      title = _bType!.name;
    }

    return PlannedMeal(
      title: title,
      kind: MealKind.breakfast,
      components: components,
      reheatMinutes: anchor?.prepMinutes ?? 0,
      fromContainer: anchor != null ? _containerFor(anchor) : '',
    );
  }

  PlannedMeal _buildSnack() {
    final m = _picked[MealRole.standalone];
    return PlannedMeal(
      title: m?.name ?? 'Перекус',
      kind: MealKind.snack,
      components: m != null ? [_comp(m, MealRole.standalone)] : const [],
    );
  }

  MealComponent _comp(Module m, MealRole role) =>
      MealComponent(moduleId: m.id, role: role, name: m.name, emoji: m.emoji);

  // ---- запасы Шефа ----------------------------------------------------------

  /// id всех модулей из утверждённого меню — то, что Шеф реально готовил.
  /// null — меню ещё нет, гость видит весь каталог.
  Set<String>? _chefIds(WeeklyMenu? menu) {
    if (menu == null) return null;
    final ids = <String>{};
    for (final week in menu.weeks) {
      for (final day in week.days) {
        for (final slot in MealSlot.values) {
          final meal = day.mealAt(slot);
          if (meal != null) ids.addAll(meal.moduleIds);
        }
      }
    }
    return ids.isEmpty ? null : ids;
  }

  /// Ограничивает список модулей запасами Шефа. Если в категории из меню
  /// ничего нет (например, перекусы) — не оставляем тупик, даём весь каталог.
  List<Module> _stock(List<Module> all, Set<String>? chefIds) {
    if (chefIds == null) return all;
    final filtered = all.where((m) => chefIds.contains(m.id)).toList();
    return filtered.isEmpty ? all : filtered;
  }

  String _containerFor(Module m) => switch (m.storage.zone.jsonValue) {
        'fridge' => 'холодильник',
        'freezer' => 'морозилка',
        'vacuum' => 'вакуум',
        'pantry' => 'кладовая',
        _ => '',
      };

  // ---- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catalog = context.watch<CatalogService>();
    final preps = context.watch<BreakfastPreps>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Собрать: ${widget.slot.label.toLowerCase()}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: !catalog.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
              children: _body(catalog, preps, tt),
            ),
      bottomSheet: _bottomBar(context, preps, tt),
    );
  }

  List<Widget> _body(CatalogService catalog, BreakfastPreps preps, TextTheme tt) {
    if (_isMain) return _mainBody(catalog, tt);
    if (_isBreakfast) return _breakfastBody(catalog, preps, tt);
    return _snackBody(catalog, tt);
  }

  // --- main ---
  List<Widget> _mainBody(CatalogService catalog, TextTheme tt) {
    const sections = [
      (MealRole.protein, ModuleCategory.protein, 'Белок'),
      (MealRole.side, ModuleCategory.side, 'Гарнир'),
      (MealRole.vegetable, ModuleCategory.vegetable, 'Овощ'),
      (MealRole.sauce, ModuleCategory.sauce, 'Соус'),
    ];
    final chefIds = _chefIds(context.watch<ActiveMenu>().menu);
    final pantry = context.watch<PantryStock>();
    final trackStock = !pantry.isEmpty; // готовка была → считаем порции
    // Порции считаем только у того, что реально готовится впрок;
    // соусы через «Готовку» не проходят — их не гасим.
    const trackedCats = {
      ModuleCategory.protein,
      ModuleCategory.side,
      ModuleCategory.vegetable,
      ModuleCategory.soup,
    };
    bool tracked(Module m) => trackStock && trackedCats.contains(m.category);

    return [
      Text(
          chefIds != null
              ? 'Собери тарелку из того, что Шеф приготовил'
              : 'Меню ещё не утверждено — показываю весь каталог',
          style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 20),
      for (final (role, category, label) in sections) ...[
        ModulePickerRow(
          label: label,
          optional: role != MealRole.protein,
          modules: _stock(catalog.modulesByCategory(category), chefIds),
          selectedIds: {if (_picked[role] != null) _picked[role]!.id},
          onTap: (m) => _toggleSingle(role, m),
          captionOf: (m) {
            if (!tracked(m)) return null;
            final p = pantry.portionsOf(m.id);
            return p > 0 ? '$p порц.' : null;
          },
          enabledOf: (m) => !tracked(m) || pantry.portionsOf(m.id) > 0,
        ),
        const SizedBox(height: 20),
      ],
      _hintsCard(_mainHints(catalog)),
    ];
  }

  List<MealHint> _mainHints(CatalogService catalog) {
    final h = MealHints.mainPlate(
      protein: _picked[MealRole.protein],
      side: _picked[MealRole.side],
      sauce: _picked[MealRole.sauce],
      pairings: catalog.allPairings,
      nameOf: (id) => catalog.moduleById(id)?.name ?? id,
    );
    return h == null ? const [] : [h];
  }

  // --- breakfast ---
  List<Widget> _breakfastBody(
      CatalogService catalog, BreakfastPreps preps, TextTheme tt) {
    final widgets = <Widget>[
      Text('Какой завтрак собираем?',
          style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 20),
      ModulePickerRow(
        label: 'Тип',
        optional: false,
        // Виды каш — подвиды, в типах завтрака им не место.
        modules: catalog
            .modulesByCategory(ModuleCategory.breakfast)
            .where((m) => !m.tags.contains('porridge_kind'))
            .toList(),
        selectedIds: {if (_bType != null) _bType!.id},
        onTap: (m) => setState(() {
          _bType = _bType?.id == m.id ? null : m;
          _eggStyle = null;
          _eggAddins.clear();
          _jarBase = _jarBarrier = _jarMiddle = _jarTop = null;
          _selectedJar = null;
        }),
      ),
      const SizedBox(height: 20),
    ];

    if (_isEggs) {
      widgets.addAll(_eggsSections(catalog, preps));
    } else if (_isJar) {
      widgets.addAll(preps.hasJars
          ? _preparedJarSection(preps, tt)
          : _jarSections(catalog, tt));
    } else if (_bType?.id == 'porridge') {
      // Какая каша: если Шеф выбрал виды — только они, иначе все.
      final all = catalog
          .modulesByCategory(ModuleCategory.breakfast)
          .where((m) => m.tags.contains('porridge_kind'))
          .toList();
      final kinds = preps.porridgeKindIds.isEmpty
          ? all
          : all.where((m) => preps.porridgeKindIds.contains(m.id)).toList();
      final addinAll = [
        for (final id in kPorridgeAddinIds)
          if (catalog.moduleById(id) != null) catalog.moduleById(id)!,
      ];
      final addins = preps.porridgeAddinIds.isEmpty
          ? addinAll
          : addinAll
              .where((m) => preps.porridgeAddinIds.contains(m.id))
              .toList();
      widgets.addAll([
        ModulePickerRow(
          label: 'Какая каша',
          optional: false,
          modules: kinds,
          selectedIds: {if (_porridgeKind != null) _porridgeKind!.id},
          onTap: (m) => setState(() =>
              _porridgeKind = _porridgeKind?.id == m.id ? null : m),
        ),
        const SizedBox(height: 20),
        if (_porridgeKind != null) ...[
          ModulePickerRow(
            label: 'С чем',
            optional: true,
            modules: addins,
            selectedIds: _porridgeAddins,
            onTap: (m) => setState(() {
              _porridgeAddins.contains(m.id)
                  ? _porridgeAddins.remove(m.id)
                  : _porridgeAddins.add(m.id);
            }),
          ),
          const SizedBox(height: 20),
        ],
      ]);
    } else if (_bType?.id == 'sandwiches') {
      // С чем бутерброд: начинки Шефа, если он их выбрал.
      const fillingIds = [
        'addin_cheese', 'addin_ham', 'addin_avocado', 'addin_salmon',
        'addin_feta', 'addin_herbs', 'addin_toast',
      ];
      final all = [
        for (final id in fillingIds)
          if (catalog.moduleById(id) != null) catalog.moduleById(id)!,
      ];
      final fillings = preps.sandwichFillingIds.isEmpty
          ? all
          : all
              .where((m) => preps.sandwichFillingIds.contains(m.id))
              .toList();
      final spreadAll = [
        for (final id in kSandwichSpreadIds)
          if (catalog.moduleById(id) != null) catalog.moduleById(id)!,
      ];
      final spreads = preps.sandwichSpreadIds.isEmpty
          ? spreadAll
          : spreadAll
              .where((m) => preps.sandwichSpreadIds.contains(m.id))
              .toList();
      widgets.addAll([
        ModulePickerRow(
          label: 'Намазка',
          optional: true,
          modules: spreads,
          selectedIds: _sandwichSpreads,
          onTap: (m) => setState(() {
            _sandwichSpreads.contains(m.id)
                ? _sandwichSpreads.remove(m.id)
                : _sandwichSpreads.add(m.id);
          }),
        ),
        const SizedBox(height: 20),
        ModulePickerRow(
          label: 'Сверху',
          optional: true,
          modules: fillings,
          selectedIds: _sandwichFillings,
          onTap: (m) => setState(() {
            _sandwichFillings.contains(m.id)
                ? _sandwichFillings.remove(m.id)
                : _sandwichFillings.add(m.id);
          }),
        ),
        const SizedBox(height: 20),
      ]);
    } else if (_bType != null) {
      widgets.add(Text('${_bType!.name} — готовое блюдо. Можно собирать.',
          style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)));
    }
    return widgets;
  }

  // Гость берёт готовую банку из заготовок Шефа.
  List<Widget> _preparedJarSection(BreakfastPreps preps, TextTheme tt) {
    return [
      Text('Готовые банки от Шефа — выбери одну',
          style: tt.titleMedium?.copyWith(
              color: AppColors.onSurface, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      for (int i = 0; i < preps.jars.length; i++) ...[
        _PreparedJarTile(
          jar: preps.jars[i],
          selected: _selectedJar == preps.jars[i],
          onTap: () => setState(() => _selectedJar =
              _selectedJar == preps.jars[i] ? null : preps.jars[i]),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }

  List<Widget> _eggsSections(CatalogService catalog, BreakfastPreps preps) {
    // Виды/добавки — из заготовок Шефа, если он их задал; иначе весь каталог.
    final styleAll = catalog.modulesByCategory(ModuleCategory.eggStyle);
    final styles = preps.eggStyleIds.isEmpty
        ? styleAll
        : styleAll.where((m) => preps.eggStyleIds.contains(m.id)).toList();

    final serveOnly = _eggStyle?.tags.contains('serve_only') ?? false;
    final addinAll = catalog.modulesByCategory(ModuleCategory.eggAddin);
    final addins = addinAll.where((m) {
      if (preps.eggAddinIds.isNotEmpty && !preps.eggAddinIds.contains(m.id)) {
        return false;
      }
      if (_eggStyle == null) return true;
      if (serveOnly) return m.tags.contains('serve');
      return true;
    }).toList();

    return [
      ModulePickerRow(
        label: 'Как готовим',
        optional: false,
        modules: styles,
        selectedIds: {if (_eggStyle != null) _eggStyle!.id},
        onTap: (m) => setState(() {
          _eggStyle = _eggStyle?.id == m.id ? null : m;
          _eggAddins.clear();
        }),
      ),
      const SizedBox(height: 20),
      if (_eggStyle != null) ...[
        ModulePickerRow(
          label: serveOnly ? 'С чем подать' : 'С чем (готовка / подача)',
          optional: true,
          modules: addins,
          selectedIds: _eggAddins,
          onTap: (m) => setState(() {
            _eggAddins.contains(m.id)
                ? _eggAddins.remove(m.id)
                : _eggAddins.add(m.id);
          }),
        ),
        const SizedBox(height: 20),
      ],
    ];
  }

  List<Widget> _jarSections(CatalogService catalog, TextTheme tt) {
    Module? pickOf(MealRole role) => switch (role) {
          MealRole.jarBase => _jarBase,
          MealRole.jarBarrier => _jarBarrier,
          MealRole.jarMiddle => _jarMiddle,
          _ => _jarTop,
        };
    void setOf(MealRole role, Module m) => setState(() {
          final cur = pickOf(role);
          final next = cur?.id == m.id ? null : m;
          switch (role) {
            case MealRole.jarBase:
              _jarBase = next;
            case MealRole.jarBarrier:
              _jarBarrier = next;
            case MealRole.jarMiddle:
              _jarMiddle = next;
            default:
              _jarTop = next;
          }
        });

    const layers = [
      (MealRole.jarBase, ModuleCategory.jarBase, '1 · Основа', false),
      (MealRole.jarBarrier, ModuleCategory.jarBarrier, '2 · Прокладка', true),
      (MealRole.jarMiddle, ModuleCategory.jarMiddle, '3 · Сочный слой', true),
      (MealRole.jarTop, ModuleCategory.jarTop, '4 · Хруст / декор', true),
    ];

    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('Шеф пока не закатал банки — собери из каталога',
            style: tt.bodySmall?.copyWith(color: AppColors.onPrimaryContainer)),
      ),
      for (final (role, category, label, optional) in layers) ...[
        ModulePickerRow(
          label: label,
          optional: optional,
          modules: catalog.modulesByCategory(category),
          selectedIds: {if (pickOf(role) != null) pickOf(role)!.id},
          onTap: (m) => setOf(role, m),
        ),
        const SizedBox(height: 20),
      ],
      _hintsCard(MealHints.jar(
        base: _jarBase,
        barrier: _jarBarrier,
        middle: _jarMiddle,
        top: _jarTop,
      )),
    ];
  }

  // --- snack ---
  List<Widget> _snackBody(CatalogService catalog, TextTheme tt) {
    final chefIds = _chefIds(context.watch<ActiveMenu>().menu);
    return [
      Text('Выбери из запасов',
          style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 20),
      ModulePickerRow(
        label: 'Перекус',
        optional: false,
        modules: _stock(
            catalog.modulesByCategory(ModuleCategory.snack), chefIds),
        selectedIds: {
          if (_picked[MealRole.standalone] != null) _picked[MealRole.standalone]!.id
        },
        onTap: (m) => _toggleSingle(MealRole.standalone, m),
      ),
    ];
  }

  // --- общие куски ---
  Widget _hintsCard(List<MealHint> hints) {
    if (hints.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final h in hints)
            MealHintTile(text: h.text, positive: h.positive),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, BreakfastPreps preps, TextTheme tt) {
    final summary = _summaryText();
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary.isNotEmpty) ...[
              Text(summary,
                  style: tt.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 10),
            ],
            LeafButton(
              onPressed: _ready(preps) ? () => _done(context) : null,
              label: 'Готово',
            ),
          ],
        ),
      ),
    );
  }

  String _summaryText() {
    if (_isMain) {
      return _picked.values.map((m) => m.name).join(' + ');
    }
    if (_isBreakfast) {
      if (_isJar && _selectedJar != null) return _selectedJar!.title;
      if (_isEggs && _eggStyle != null) {
        return _eggAddins.isNotEmpty
            ? '${_eggStyle!.name} + ${_eggAddins.length} добавок'
            : _eggStyle!.name;
      }
      if (_isJar) {
        return [_jarBase, _jarBarrier, _jarMiddle, _jarTop]
            .whereType<Module>()
            .map((m) => m.name)
            .join(' › ');
      }
      return _bType?.name ?? '';
    }
    return _picked[MealRole.standalone]?.name ?? '';
  }
}

/// Карточка готовой банки из заготовок Шефа (Гость выбирает целиком).
class _PreparedJarTile extends StatelessWidget {
  const _PreparedJarTile({
    required this.jar,
    required this.selected,
    required this.onTap,
  });
  final PlannedMeal jar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: selected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jar.title,
                      style: tt.titleMedium?.copyWith(
                        color: selected
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in jar.components)
                        Text('${c.emoji} ${c.name}',
                            style: tt.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
