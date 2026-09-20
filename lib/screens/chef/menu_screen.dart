import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/services/active_menu.dart';
import 'package:modular_chef/services/breakfast_preps.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/local_store.dart';
import 'package:modular_chef/services/favourite_combos.dart';
import 'package:modular_chef/services/menu_generator.dart';
import 'package:modular_chef/screens/chef/breakfast_detail_screens.dart';
import 'package:modular_chef/screens/chef/breakfast_preps_screen.dart';
import 'package:modular_chef/screens/chef/category_pick_screen.dart';
import 'package:modular_chef/services/app_settings.dart';
import 'package:modular_chef/services/my_dishes.dart';
import 'package:modular_chef/services/preferences.dart';
import 'package:modular_chef/services/purchase_catalog.dart';
import 'package:modular_chef/services/prompt_builder.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/widgets/atmospheric_header.dart';
import 'package:modular_chef/widgets/leaf_button.dart';
import 'package:modular_chef/theme/module_visuals.dart';

/// Шеф-экран «Собери меню» — по макету chef_assemble_menu_refined:
/// sky-mist шапка, light-leaf инфокарта, секции с акварельными карточками,
/// зелёная CTA с бейджем-счётчиком.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Меню начинается с чистого листа — Шеф выбирает всё сам.
  final Set<String> _picked = {};

  static const _draftKey = 'menu_draft';

  @override
  void initState() {
    super.initState();
    // Черновик выбора переживает перезапуск: обидно потерять набранное,
    // если приложение закрыли до «Собрать меню».
    context.read<LocalStore>().readJson(_draftKey).then((json) {
      final ids = ((json?['picked'] as List?) ?? const []).cast<String>();
      if (ids.isEmpty || !mounted) return;
      setState(() => _picked.addAll(ids));
    });
  }

  void _saveDraft() {
    context.read<LocalStore>().writeJson(_draftKey, {
      'picked': _picked.toList(),
    });
  }

  void _toggle(String id) {
    setState(() {
      _picked.contains(id) ? _picked.remove(id) : _picked.add(id);
    });
    _saveDraft();
  }

  /// Группы выбора: заголовок секции → карточки-категории, в которые
  /// «проваливаешься» на отдельный экран с сеткой.
  List<Module> _group(CatalogService c, ModuleCategory cat,
      {Set<String>? only, Set<String>? except}) {
    return c
        .modulesByCategory(cat)
        .where((m) =>
            (only == null || only.contains(m.id)) &&
            (except == null || !except.contains(m.id)) &&
            !m.tags.contains('porridge_kind') &&
            // Бульоны — заготовка для готовки, а не блюдо меню.
            !m.tags.contains('broth'))
        .toList();
  }

  Future<void> _openGroup(
      BuildContext context, String title, String hint, List<Module> mods,
      {Widget? Function(Module)? detailScreenOf,
      String? Function(BuildContext, Module)? detailSummaryOf}) async {
    final ids = {for (final m in mods) m.id};
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryPickScreen(
          title: title,
          hint: hint,
          modules: mods,
          initiallySelected: _picked.intersection(ids),
          detailScreenOf: detailScreenOf,
          detailSummaryOf: detailSummaryOf,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _picked.removeAll(ids);
        _picked.addAll(result);
      });
      _saveDraft();
    }
  }

  /// Экран настройки для типа завтрака (null — настройки нет).
  static Widget? _breakfastDetailScreen(Module m) => switch (m.id) {
        'eggs' => const EggsPrepScreen(),
        'jar' => const BreakfastPrepsScreen(showEggs: false),
        'porridge' => const PorridgePrepScreen(),
        'sandwiches' => const SandwichPrepScreen(),
        _ => null,
      };

  /// Живая сводка настройки типа завтрака.
  static String? _breakfastDetailSummary(BuildContext context, Module m) {
    final p = context.watch<BreakfastPreps>();
    final n = switch (m.id) {
      'eggs' => p.eggStyleIds.length + p.eggAddinIds.length,
      'jar' => p.jars.length,
      'porridge' => p.porridgeKindIds.length + p.porridgeAddinIds.length,
      'sandwiches' => p.sandwichBreadPreps.length +
          p.sandwichSpreadIds.length +
          p.sandwichFillingIds.length,
      _ => 0,
    };
    if (m.id == 'jar') return n > 0 ? '$n ${_jarsWord(n)}' : 'настрой ▸';
    return n > 0 ? 'выбрано $n' : 'настрой ▸';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catalog = context.watch<CatalogService>();

    return Scaffold(
      body: !catalog.isLoaded
          ? _LoadingState(error: catalog.loadError)
          : _buildContent(context, catalog, tt),
      bottomSheet: !catalog.isLoaded ? null : _cta(tt, catalog),
    );
  }

  /// Зелёная CTA с бейджем-счётчиком — как в макете.
  Widget _cta(TextTheme tt, CatalogService catalog) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: LeafButton(
          height: 60,
          radius: 16,
          onPressed:
              _picked.isEmpty ? null : () => _generateAndOpen(context, catalog),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Собрать меню',
                  style: tt.titleMedium?.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.onPrimaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text('${_picked.length}',
                    style: tt.labelMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildContent(
      BuildContext context, CatalogService catalog, TextTheme tt) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const AtmosphericHeader(
          title: 'Составим меню на 2 недели',
          subtitle: 'Выбери, что любите, — остальное соберём сами.',
          trailing: RoleSwitcher(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Инфокарта про авто-соусы — light-leaf, как в макете.
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.lightLeaf,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.shadowTint,
                        blurRadius: 24,
                        offset: Offset(0, 8)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.leafDeep.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant_menu_rounded,
                          color: AppColors.leafDeep, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Соусы советуем сами: под каждый белок и гарнир меню подберёт свой — они попадут в список покупок автоматически.',
                          style: tt.bodyMedium?.copyWith(
                              color: AppColors.leafDeep, height: 1.35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Утверждённое меню — всегда видно и открывается.
              Builder(builder: (context) {
                final active = context.watch<ActiveMenu>();
                if (!active.hasMenu) return const SizedBox.shrink();
                final at = active.approvedAt;
                final weeks = active.menu!.weeks.length;
                String fmt(DateTime d) =>
                    '${d.day}.${d.month.toString().padLeft(2, '0')}';
                final period = at == null
                    ? 'ещё не утверждено'
                    : '${fmt(at)} – ${fmt(at.add(Duration(days: weeks * 7 - 1)))}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => context.push(Routes.chefTwoWeekMenu),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: at == null
                            ? AppColors.tertiaryContainer
                                .withValues(alpha: 0.55)
                            : AppColors.lightLeaf.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        const Text('📅', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            at == null
                                ? 'Меню собрано, но не утверждено — открой и утверди'
                                : 'Меню утверждено · $period',
                            style: tt.titleSmall?.copyWith(
                                color: at == null
                                    ? AppColors.onTertiaryContainer
                                    : AppColors.leafDeep,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 20,
                            color: at == null
                                ? AppColors.onTertiaryContainer
                                : AppColors.leafDeep),
                      ]),
                    ),
                  ),
                );
              }),
              // Едоки и горизонт — прямо здесь, где собираем меню.
              _eatersCard(context, tt),
              const SizedBox(height: 24),

              // Белки — по группам, «проваливаемся» в каждую.
              _sectionHeader(tt, 'Белки', 'выберите 3–5'),
              const SizedBox(height: 14),
              _CategoryCard(
                emoji: '🥩',
                title: 'Мясо',
                assetId: 'cat_meat',
                modules: _group(catalog, ModuleCategory.protein,
                    except: {...kFishIds, ...kPoultryIds, ...kPlantProteinIds}),
                picked: _picked,
                onTap: (mods) => _openGroup(context, 'Мясо',
                    'Говядина, свинина, баранина и субпродукты', mods),
              ),
              const SizedBox(height: 10),
              _CategoryCard(
                emoji: '🍗',
                title: 'Птица',
                assetId: 'cat_poultry',
                modules: _group(catalog, ModuleCategory.protein,
                    only: kPoultryIds),
                picked: _picked,
                onTap: (mods) => _openGroup(
                    context, 'Птица', 'Курица, индейка, утка', mods),
              ),
              const SizedBox(height: 10),
              _CategoryCard(
                emoji: '🐟',
                title: 'Рыба и морепродукты',
                assetId: 'cat_fish',
                modules:
                    _group(catalog, ModuleCategory.protein, only: kFishIds),
                picked: _picked,
                onTap: (mods) => _openGroup(context, 'Рыба и морепродукты',
                    'Свежая, слабосолёная и котлеты', mods),
              ),
              const SizedBox(height: 10),
              _CategoryCard(
                emoji: '🌱',
                title: 'Растительный белок',
                assetId: 'cat_plant',
                modules: _group(catalog, ModuleCategory.protein,
                    only: kPlantProteinIds),
                picked: _picked,
                onTap: (mods) => _openGroup(
                    context, 'Растительный белок', 'Тофу и компания', mods),
              ),
              const SizedBox(height: 32),

              // Гарниры — тоже по группам.
              _sectionHeader(tt, 'Гарниры', '2–4'),
              const SizedBox(height: 14),
              _CategoryCard(
                emoji: '🌾',
                title: 'Крупы',
                assetId: 'cat_grains',
                modules: _group(catalog, ModuleCategory.side, except: {
                  'lentils', 'chickpeas', 'red_beans', 'mung_beans',
                  'spaghetti', 'pasta', 'potato', 'soba', 'rice_noodles',
                  'sweet_potato',
                }),
                picked: _picked,
                onTap: (mods) => _openGroup(
                    context, 'Крупы', 'Рис, гречка, булгур, киноа…', mods),
              ),
              const SizedBox(height: 10),
              _CategoryCard(
                emoji: '🫘',
                title: 'Бобовые',
                assetId: 'cat_legumes',
                modules: _group(catalog, ModuleCategory.side,
                    only: {'lentils', 'chickpeas', 'red_beans', 'mung_beans'}),
                picked: _picked,
                onTap: (mods) => _openGroup(
                    context, 'Бобовые', 'Чечевица, нут, фасоль, маш', mods),
              ),
              const SizedBox(height: 10),
              _CategoryCard(
                emoji: '🍝',
                title: 'Паста и картофель',
                assetId: 'cat_pasta',
                modules: _group(catalog, ModuleCategory.side, only: {
                  'spaghetti', 'pasta', 'potato', 'soba', 'rice_noodles',
                  'sweet_potato',
                }),
                picked: _picked,
                onTap: (mods) => _openGroup(context, 'Паста и картофель',
                    'Паста, лапша, картофель и батат', mods),
              ),
              const SizedBox(height: 32),

              _sectionHeader(tt, 'Супы', 'опционально'),
              const SizedBox(height: 14),
              _CategoryCard(
                emoji: '🍲',
                title: 'Супы',
                assetId: 'cat_soups',
                modules: _group(catalog, ModuleCategory.soup),
                picked: _picked,
                onTap: (mods) => _openGroup(context, 'Супы',
                    'Основы варим сами и храним в запасах', mods),
              ),
              const SizedBox(height: 32),

              _sectionHeader(tt, 'Завтраки', '2–3'),
              const SizedBox(height: 14),
              _CategoryCard(
                emoji: '🍳',
                title: 'Типы завтраков',
                assetId: 'cat_breakfast',
                modules: _group(catalog, ModuleCategory.breakfast),
                picked: _picked,
                onTap: (mods) => _openGroup(
                  context,
                  'Завтраки',
                  'Выбрал тип — сразу настрой его: виды, добавки, слои',
                  mods,
                  detailScreenOf: _breakfastDetailScreen,
                  detailSummaryOf: _breakfastDetailSummary,
                ),
              ),
              const SizedBox(height: 14),
              ..._breakfastDetails(context, catalog, tt),
              const SizedBox(height: 10),

              // Мои блюда
              Text('Мои блюда',
                  style: tt.titleLarge?.copyWith(
                      color: AppColors.onSurface, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final n in context.watch<MyDishes>().names)
                    FilterChip(
                      label: Text(n),
                      selected: _picked.contains(n),
                      onSelected: (_) => _toggle(n),
                      showCheckmark: true,
                      checkmarkColor: AppColors.leafDeep,
                      labelStyle: tt.labelLarge?.copyWith(
                        color: _picked.contains(n)
                            ? AppColors.leafDeep
                            : AppColors.onSurface,
                      ),
                    ),
                  _addCustomButton(tt),
                ],
              ),
              const SizedBox(height: 24),
              // Сводка выбора: сколько набрала и не перебор ли.
              Builder(builder: (context) {
                int inCat(ModuleCategory c) => catalog
                    .modulesByCategory(c)
                    .where((m) => _picked.contains(m.id))
                    .length;
                final prot = inCat(ModuleCategory.protein);
                final sides = inCat(ModuleCategory.side);
                final soups = inCat(ModuleCategory.soup);
                final brf = inCat(ModuleCategory.breakfast);
                if (prot + sides + soups + brf == 0) {
                  return const SizedBox.shrink();
                }
                final tooMany = prot > 4 || sides > 4 || soups > 2;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tooMany
                        ? AppColors.tertiaryContainer.withValues(alpha: 0.55)
                        : AppColors.lightLeaf.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    tooMany
                        ? '⚖️ Выбрано: белков $prot, гарниров $sides, супов $soups, завтраков $brf — это до ${prot * (sides == 0 ? 1 : sides)} разных блюд. Для 2 недель хватает 3–4 белков, 3 гарниров и 1–2 супов: меньше видов — меньше готовки в воскресенье.'
                        : '✓ Выбрано: белков $prot, гарниров $sides, супов $soups, завтраков $brf — сбалансированно, готовка не растянется.',
                    style: tt.bodySmall?.copyWith(
                        color: tooMany
                            ? AppColors.onTertiaryContainer
                            : AppColors.leafDeep,
                        height: 1.4),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// Уточнения к выбранным типам завтраков — входы на отдельные экраны
  /// (как конструктор банки). Выбор живёт в BreakfastPreps и идёт в покупки.
  List<Widget> _breakfastDetails(
      BuildContext context, CatalogService catalog, TextTheme tt) {
    final preps = context.watch<BreakfastPreps>();
    final out = <Widget>[];

    void entry(String emoji, String label, int count, Widget screen) {
      out.addAll([
        _SilverButton(
          emoji: emoji,
          label: label,
          count: count,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => screen)),
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (_picked.contains('eggs')) {
      entry('🥚', 'Яйца — виды и добавки',
          preps.eggStyleIds.length + preps.eggAddinIds.length,
          const EggsPrepScreen());
    }
    if (_picked.contains('jar')) {
      // Не через Routes.chefBreakfastPreps: тот маршрут общий с Профилем и
      // открывает экран целиком, вместе с яйцами — в настройке банки они лишние.
      entry('🫙', 'Баночки — собрать по слоям', preps.jars.length,
          const BreakfastPrepsScreen(showEggs: false));
    }
    if (_picked.contains('porridge')) {
      entry('🥣', 'Каша — виды и добавки',
          preps.porridgeKindIds.length + preps.porridgeAddinIds.length,
          const PorridgePrepScreen());
    }
    if (_picked.contains('sandwiches')) {
      entry('🥪', 'Бутерброды — хлеб, намазка, начинка',
          preps.sandwichBreadPreps.length +
              preps.sandwichSpreadIds.length +
              preps.sandwichFillingIds.length,
          const SandwichPrepScreen());
    }
    if (out.isNotEmpty) out.add(const SizedBox(height: 22));
    return out;
  }

  /// Карточка «на сколько едоков готовим» со степпером — пишет в настройки.
  Widget _eatersCard(BuildContext context, TextTheme tt) {
    final settings = context.watch<AppSettings>();
    final n = settings.householdSize;
    Widget btn(IconData icon, VoidCallback? onTap) => Opacity(
          opacity: onTap == null ? 0.35 : 1,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.lightLeaf,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.leafDeep),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(children: [
        Row(children: [
          const Text('👨‍👩‍👧', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Готовим на $n ${_personsWord(n)}',
                style: tt.titleMedium?.copyWith(
                    color: AppColors.onSurface, fontWeight: FontWeight.w600)),
          ),
          btn(Icons.remove,
              n > 1 ? () => settings.setHouseholdSize(n - 1) : null),
          SizedBox(
            width: 36,
            child: Center(
              child: Text('$n',
                  style: tt.titleLarge?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
          ),
          btn(Icons.add,
              n < 8 ? () => settings.setHouseholdSize(n + 1) : null),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Text('🗓', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Горизонт меню',
                style: tt.titleMedium?.copyWith(
                    color: AppColors.onSurface, fontWeight: FontWeight.w600)),
          ),
          for (final w in const [1, 2, 3]) ...[
            InkWell(
              onTap: () => settings.setMenuWeeks(w),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: settings.menuWeeks == w
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$w нед.',
                    style: tt.labelMedium?.copyWith(
                      color: settings.menuWeeks == w
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                      fontWeight: settings.menuWeeks == w
                          ? FontWeight.w700
                          : FontWeight.w500,
                    )),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ]),
      ]),
    );
  }

  static String _jarsWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'банка';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'банки';
    }
    return 'банок';
  }

  static String _personsWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'персону';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'персоны';
    }
    return 'персон';
  }

  Widget _sectionHeader(TextTheme tt, String label, String hint) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: tt.titleLarge?.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(hint,
                style:
                    tt.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ],
      );

  Widget _addCustomButton(TextTheme tt) => InkWell(
        onTap: () => _showAddCustomSheet('Мои блюда'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.onSurface.withValues(alpha: 0.2),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add,
                  size: 18, color: AppColors.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text('Своё',
                  style: tt.labelLarge?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  /// Делит набор пиков на категории, зовёт генератор, открывает TwoWeekMenu.
  Future<void> _generateAndOpen(
      BuildContext context, CatalogService catalog) async {
    final activeMenu = context.read<ActiveMenu>();
    final generator = context.read<MenuGenerator>();
    final prefs = context.read<Preferences>();
    final preps = context.read<BreakfastPreps>();
    final byCategory = <ModuleCategory, List<String>>{
      for (final c in ModuleCategory.values) c: <String>[],
    };
    for (final id in _picked) {
      final m = catalog.moduleById(id);
      if (m != null) byCategory[m.category]!.add(id);
    }
    final request = GenerationRequest(
      proteinIds: byCategory[ModuleCategory.protein]!,
      sideIds: byCategory[ModuleCategory.side]!,
      soupIds: byCategory[ModuleCategory.soup]!,
      breakfastIds: byCategory[ModuleCategory.breakfast]!,
      customDishes: _picked
          .where((id) => catalog.moduleById(id) == null)
          .toList(growable: false),
      allergies: prefs.avoidList,
      prepTimeLimitMinutes: prefs.prepLimitMinutes,
      weekStyle: prefs.weekStyle,
      favourites: context.read<FavouriteCombos>().items,
      weeks: context.read<AppSettings>().menuWeeks,
      eggStyleIds: preps.eggStyleIds.toList(),
      eggAddinIds: preps.eggAddinIds.toList(),
      porridgeKindIds: preps.porridgeKindIds.toList(),
      sandwichFillingIds: preps.sandwichFillingIds.toList(),
    );

    activeMenu.beginGenerating();
    // Открываем экран сразу — он покажет loader, а по завершении перерисуется.
    if (context.mounted) context.push(Routes.chefTwoWeekMenu);
    try {
      final menu = await generator.generate(
        request,
        modules: catalog.allModules,
        pairings: catalog.allPairings,
      );
      activeMenu.set(menu);
    } catch (e) {
      activeMenu.fail(e);
    }
  }

  Future<void> _showAddCustomSheet(String sectionTitle) async {
    final controller = TextEditingController();
    final added = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Добавить в «$sectionTitle»',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Например, нут',
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
    if (added != null && added.isNotEmpty && mounted) {
      context.read<MyDishes>().add(MyDish(name: added));
      setState(() => _picked.add(added));
    }
  }
}

/// Карточка категории («Мясо», «Крупы»…): представитель-акварель,
/// перечень выбранного и «провал» на экран выбора.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.emoji,
    required this.title,
    required this.modules,
    required this.picked,
    required this.onTap,
    this.assetId,
  });
  final String emoji;
  final String title;
  final List<Module> modules;
  final Set<String> picked;
  final void Function(List<Module>) onTap;

  /// Своя категорийная акварель (cat_*.png); если её ещё нет —
  /// показываем представителя из выбранного.
  final String? assetId;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final selected = [for (final m in modules) if (picked.contains(m.id)) m];
    final repId = selected.isNotEmpty ? selected.first.id : modules.firstOrNull?.id;
    final img = (assetId != null ? moduleImage(assetId!) : null) ??
        (repId != null ? moduleImage(repId) : null);
    final subtitle = selected.isEmpty
        ? 'ничего не выбрано · всего ${modules.length}'
        : selected.map((m) => m.name).join(', ');

    return InkWell(
      onTap: modules.isEmpty ? null : () => onTap(modules),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowTint,
                blurRadius: 24,
                offset: Offset(0, 8)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(3),
            child: img != null
                ? Image.asset(img, fit: BoxFit.cover)
                : Center(
                    child:
                        Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$emoji $title',
                    style: tt.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                        color: selected.isEmpty
                            ? AppColors.onSurfaceVariant
                            : AppColors.leafDeep,
                        fontWeight: selected.isEmpty
                            ? FontWeight.w400
                            : FontWeight.w600)),
              ],
            ),
          ),
          if (selected.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightLeaf,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${selected.length}',
                  style: tt.labelSmall?.copyWith(
                      color: AppColors.leafDeep, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              size: 22, color: AppColors.onSurfaceVariant),
        ]),
      ),
    );
  }
}

/// «Серебристая» кнопка-подменю: не зелёная и не синяя — нейтральная,
/// с эмодзи, счётчиком выбранного и шевроном.
class _SilverButton extends StatelessWidget {
  const _SilverButton({
    required this.emoji,
    required this.label,
    required this.count,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: tt.titleSmall?.copyWith(
                    color: AppColors.onSurface, fontWeight: FontWeight.w600)),
          ),
          if (count > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightLeaf,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count',
                  style: tt.labelSmall?.copyWith(
                      color: AppColors.leafDeep,
                      fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right,
              size: 20, color: AppColors.onSurfaceVariant),
        ]),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Каталог не загрузился: $error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
