import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/storage.dart';
import 'package:modular_chef/screens/chef/layout_plan_screen.dart';
import 'package:modular_chef/services/active_menu.dart';
import 'package:modular_chef/services/app_settings.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/method_steps.dart';
import 'package:modular_chef/services/pantry_stock.dart';
import 'package:modular_chef/services/purchase_catalog.dart';
import 'package:modular_chef/theme/module_visuals.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/widgets/atmospheric_header.dart';
import 'package:modular_chef/widgets/leaf_button.dart';

/// Шеф-экран «День заготовки» — теперь из каталога и на все типы:
/// Шаг 1 — выбор способа для белков/гарниров/овощей/супов (+ детали и хранение);
/// Шаг 2 — план заготовки из выбранного.
class PrepScreen extends StatefulWidget {
  const PrepScreen({super.key});

  @override
  State<PrepScreen> createState() => _PrepScreenState();
}

class _PrepScreenState extends State<PrepScreen> {
  int _step = 0;

  /// moduleId → выбранный способ приготовления.
  final Map<String, String> _method = {};

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    return Scaffold(
      appBar: _step == 0
          ? null
          : AppBar(
              title: const Text(''),
              actions: const [RoleSwitcher(), SizedBox(width: 8)],
            ),
      body: !catalog.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : (_step == 0 ? _buildStep1(context, catalog) : _buildStep2(context, catalog)),
    );
  }

  /// Группы готовки — как в меню: провалился в категорию и выбрал.
  static final _prepGroups = <(String, String, bool Function(Module))>[
    ('🥩', 'Мясо и птица', (m) =>
        m.category == ModuleCategory.protein &&
        !kFishIds.contains(m.id) &&
        !kPlantProteinIds.contains(m.id)),
    ('🐟', 'Рыба и морепродукты', (m) =>
        m.category == ModuleCategory.protein && kFishIds.contains(m.id)),
    ('🌱', 'Растительное', (m) =>
        m.category == ModuleCategory.protein &&
        kPlantProteinIds.contains(m.id)),
    ('🌾', 'Гарниры', (m) => m.category == ModuleCategory.side),
    ('🥦', 'Овощи', (m) => m.category == ModuleCategory.vegetable),
    ('🍲', 'Супы', (m) => m.category == ModuleCategory.soup),
    // Домашние соусы варим помногу и морозим кубиками.
    ('🥫', 'Соусы', (m) =>
        m.category == ModuleCategory.sauce &&
        kHomemadeSauceIngredients.containsKey(m.id)),
  ];

  Widget _buildStep1(BuildContext context, CatalogService catalog) {
    final tt = Theme.of(context).textTheme;
    final menuIds = context.watch<ActiveMenu>().allModuleIds;
    return Column(
      children: [
        const AtmosphericHeader(
          title: 'Подготовка',
          subtitle: 'Выбери, что и как готовим, — по категориям.',
          background: 'assets/art/bg_prep.png',
          trailing: RoleSwitcher(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              const Row(children: [
                _StepBadge(text: 'ШАГ 1 из 2', active: true),
                SizedBox(width: 8),
                _StepBadge(text: 'ШАГ 2', active: false),
              ]),
              const SizedBox(height: 16),
              for (final (emoji, title, test) in _prepGroups) ...[
                Builder(builder: (context) {
                  final all = catalog.allModules
                      .where((m) => test(m) && m.methods.isNotEmpty)
                      .toList();
                  if (all.isEmpty) return const SizedBox.shrink();
                  final inMenu =
                      all.where((m) => menuIds.contains(m.id)).length;
                  final picked =
                      all.where((m) => _method.containsKey(m.id)).length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _PrepCategoryScreen(
                              emoji: emoji,
                              title: title,
                              modules: all,
                              menuIds: menuIds,
                              method: _method,
                              onInfo: _showDetail,
                              onHowTo: _showMethodSteps,
                            ),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
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
                          Text(emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: tt.titleMedium?.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                  picked > 0
                                      ? 'способ выбран: $picked'
                                      : (inMenu > 0
                                          ? 'в меню: $inMenu позиций'
                                          : 'в меню нет — весь каталог внутри'),
                                  style: tt.bodySmall?.copyWith(
                                      color: picked > 0
                                          ? AppColors.leafDeep
                                          : AppColors.onSurfaceVariant,
                                      fontWeight: picked > 0
                                          ? FontWeight.w600
                                          : FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                          if (picked > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.lightLeaf,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('$picked',
                                  style: tt.labelSmall?.copyWith(
                                      color: AppColors.leafDeep,
                                      fontWeight: FontWeight.w700)),
                            ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              size: 22, color: AppColors.onSurfaceVariant),
                        ]),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: LeafButton(
              onPressed:
                  _method.isEmpty ? null : () => setState(() => _step = 1),
              label: _method.isEmpty
                  ? 'Выбери, что готовим'
                  : 'К плану · выбрано ${_method.length}',
            ),
          ),
        ),
      ],
    );
  }

  /// Локальные рекомендации по порядку готовки — считаются из выбранных
  /// способов, без сети и токенов.
  Widget _flowTips(
      TextTheme tt, List<({Module? module, String method})> entries) {
    List<String> names(bool Function(String m) test) => entries
        .where((e) => test(e.method))
        .map((e) => e.module!.name.toLowerCase())
        .toList();

    final oven =
        names((m) => m.contains('Запечь') || m.contains('фольге'));
    final stove = names((m) =>
        m.contains('Варка') ||
        m.contains('Отварить') ||
        m.contains('Запарка') ||
        m.contains('Тушить') ||
        m.contains('Уварить'));
    final pan = names((m) => m.contains('Сковорода') || m.contains('Гриль'));
    final cold = names((m) =>
        m.contains('Сборка') ||
        m.contains('Готовое') ||
        m.contains('Замочить') ||
        m.contains('Настоять') ||
        m.contains('Блендер') ||
        m.contains('Маринованный'));
    final total = entries.fold<int>(
        0, (s, e) => s + (e.module!.prepMinutes ?? 0));

    final tips = <String>[
      if (oven.isNotEmpty)
        'Начни с духовки: ${oven.join(', ')} — печётся само, пока ты у плиты.',
      if (stove.isNotEmpty)
        'Параллельно на плите: ${stove.join(', ')}.',
      if (pan.isNotEmpty)
        'Сковороду и гриль оставь напоследок: ${pan.join(', ')} — быстрые.',
      if (cold.isNotEmpty)
        'Без плиты: ${cold.join(', ')} — собери в паузах.',
      'Останется остудить, разложить по контейнерам и подписать даты.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightLeaf.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('КАК ВЫСТРОИТЬ ГОТОВКУ · ~$total МИН АКТИВНО',
              style: tt.labelSmall?.copyWith(
                color: AppColors.leafDeep,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              )),
          const SizedBox(height: 8),
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(color: AppColors.leafDeep)),
                  Expanded(
                    child: Text(t,
                        style: tt.bodySmall?.copyWith(
                            color: AppColors.leafDeep, height: 1.35)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context, CatalogService catalog) {
    final tt = Theme.of(context).textTheme;
    final entries = _method.entries
        .map((e) => (module: catalog.moduleById(e.key), method: e.value))
        .where((x) => x.module != null)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                TextButton.icon(
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Шаг 1'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                ),
                const Spacer(),
                const _StepBadge(text: 'ШАГ 1', active: false),
                const SizedBox(width: 8),
                const _StepBadge(text: 'ШАГ 2 из 2', active: true),
              ]),
              const SizedBox(height: 16),
              Text('План заготовки',
                  style: tt.headlineMedium?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                entries.isEmpty
                    ? 'Вернись на шаг 1 и выбери способы приготовления.'
                    : 'Готовь по порядку, раскладывай по контейнерам.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              if (entries.isNotEmpty) ...[
                _flowTips(tt, entries),
                const SizedBox(height: 16),
              ],
              // План сгруппирован по технике: духовка → плита → сковорода →
              // без огня. Сквозная нумерация сохраняется.
              ...(() {
                String tech(String m) {
                  final low = m.toLowerCase();
                  if (low.contains('запечь') || low.contains('фольге')) {
                    return 'Духовка';
                  }
                  if (low.contains('сковород') || low.contains('гриль')) {
                    return 'Сковорода и гриль';
                  }
                  if (low.contains('варка') ||
                      low.contains('отварить') ||
                      low.contains('запарка') ||
                      low.contains('тушить') ||
                      low.contains('уварить') ||
                      low.contains('на пару') ||
                      low.contains('пюрировать')) {
                    return 'Плита';
                  }
                  return 'Без огня';
                }

                const order = [
                  'Духовка', 'Плита', 'Сковорода и гриль', 'Без огня'
                ];
                const emoji = {
                  'Духовка': '🔥', 'Плита': '🍳',
                  'Сковорода и гриль': '🥘', 'Без огня': '🥣',
                };
                final widgets = <Widget>[];
                var n = 0;
                for (final t in order) {
                  final group =
                      entries.where((e) => tech(e.method) == t).toList();
                  if (group.isEmpty) continue;
                  final mins = group.fold<int>(
                      0, (s, e) => s + (e.module!.prepMinutes ?? 0));
                  widgets.addAll([
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        '${emoji[t]} ${t.toUpperCase()} · ~$mins МИН',
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.leafDeep,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    for (final e in group) ...[
                      _PlanStep(
                        index: ++n,
                        module: e.module!,
                        method: e.method,
                        onTap: () =>
                            _showMethodSteps(context, e.module!, e.method),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ]);
                }
                return widgets;
              })(),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    const Text('🧼', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Подготовь контейнеры заранее — сэкономит 10 минут в конце.',
                        style: tt.bodyMedium?.copyWith(
                            color: AppColors.onTertiaryContainer,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
        if (entries.isNotEmpty)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SafeArea(
              top: false,
              child: LeafButton(
                onPressed: () => _finishCooking(context, entries),
                label:
                    'Завершить готовку — в запасы (${entries.length})',
              ),
            ),
          ),
      ],
    );
  }

  /// Готовка окончена: подтверждаем, сколько порций дала каждая позиция
  /// (кастрюля супа ≠ два стейка), и записываем в «Запасы» Гостя.
  Future<void> _finishCooking(BuildContext context,
      List<({Module? module, String method})> entries) async {
    final defaultPortions = context.read<AppSettings>().portionsPerBatch;
    // Супам по умолчанию даём в полтора раза больше порций.
    final portions = <String, int>{
      for (final e in entries)
        e.module!.id: e.module!.category == ModuleCategory.soup
            ? (defaultPortions * 3 / 2).round()
            : defaultPortions,
    };
    // Зона хранения — сразу с рекомендацией каталога, можно поправить.
    final zones = <String, StorageZone>{
      for (final e in entries) e.module!.id: e.module!.storage.zone,
    };
    // ×2 впрок: время почти то же, а закрывает следующий цикл.
    final base = Map<String, int>.from(portions);
    final doubles = <String>{};

    final confirmed = await showModalBottomSheet<Map<String, int>>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final tt = Theme.of(ctx).textTheme;
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Сколько порций получилось?',
                        style: tt.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Подправь, если вышло больше или меньше обычного.',
                        style: tt.bodyMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    for (final e in entries) ...[
                      Row(children: [
                        if (moduleImage(e.module!.id) != null)
                          Image.asset(moduleImage(e.module!.id)!,
                              width: 30, height: 30)
                        else
                          Text(e.module!.emoji,
                              style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.module!.name,
                              style: tt.bodyLarge?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600)),
                        ),
                        _PortionStepper(
                          value: portions[e.module!.id]!,
                          onChanged: (v) =>
                              setSheet(() => portions[e.module!.id] = v),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      // Куда убираем: рекомендация уже отмечена. Плюс ×2 впрок.
                      Wrap(
                        spacing: 6,
                        children: [
                          InkWell(
                            onTap: () => setSheet(() {
                              final id = e.module!.id;
                              if (!doubles.remove(id)) {
                                doubles.add(id);
                                portions[id] = base[id]! * 2;
                              } else {
                                portions[id] = base[id]!;
                              }
                            }),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: doubles.contains(e.module!.id)
                                    ? AppColors.clay
                                    : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('×2 впрок',
                                  style: tt.labelSmall?.copyWith(
                                    color: doubles.contains(e.module!.id)
                                        ? Colors.white
                                        : AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ),
                          for (final z in const [
                            StorageZone.fridge,
                            StorageZone.freezer,
                            StorageZone.vacuum,
                            StorageZone.pantry,
                          ])
                            InkWell(
                              onTap: () => setSheet(
                                  () => zones[e.module!.id] = z),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: zones[e.module!.id] == z
                                      ? AppColors.lightLeaf
                                      : AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${z.emoji} ${z.label}'
                                  '${e.module!.storage.zone == z ? ' ✓' : ''}',
                                  style: tt.labelSmall?.copyWith(
                                    color: zones[e.module!.id] == z
                                        ? AppColors.leafDeep
                                        : AppColors.onSurfaceVariant,
                                    fontWeight: zones[e.module!.id] == z
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    LeafButton(
                      onPressed: () => Navigator.pop(ctx, portions),
                      label: 'В запасы',
                      height: 48,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (confirmed == null || !context.mounted) return;

    context.read<PantryStock>().addCookedMap(confirmed, zones: zones);
    setState(() {
      _method.clear();
      _step = 0;
    });
    // Сразу — план раскладки: тара, порции, даты, излишки в морозилку.
    final layoutItems = <LayoutItem>[
      for (final e in entries)
        if ((confirmed[e.module!.id] ?? 0) > 0)
          (
            module: e.module!,
            portions: confirmed[e.module!.id]!,
            zone: zones[e.module!.id] ?? e.module!.storage.zone,
          ),
    ];
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => LayoutPlanScreen(items: layoutItems)),
    );
  }

  /// Пошаговая инструкция для выбранного способа — локально, без токенов.
  void _showMethodSteps(BuildContext context, Module m, String method) {
    final tt = Theme.of(context).textTheme;
    final steps = methodSteps(m, method);
    final zone = m.storage.zone;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (moduleImage(m.id) != null)
                    Image.asset(moduleImage(m.id)!, width: 36, height: 36)
                  else
                    Text(m.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(m.name,
                        style: tt.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(method,
                      style: tt.labelMedium?.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.lightLeaf,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text('${i + 1}',
                              style: tt.labelSmall?.copyWith(
                                  color: AppColors.leafDeep,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(steps[i],
                              style: tt.bodyMedium?.copyWith(
                                  color: AppColors.onSurface, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${zone.emoji} Потом — ${zone.label.toLowerCase()}, до ${m.storage.days} дн.'
                    '${m.storage.tip.isNotEmpty ? ' ${m.storage.tip}' : ''}',
                    style: tt.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Module m) {
    final tt = Theme.of(context).textTheme;
    final zone = m.storage.zone;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (moduleImage(m.id) != null)
                  Image.asset(moduleImage(m.id)!, width: 32, height: 32)
                else
                  Text(m.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(m.name,
                    style: tt.titleLarge?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 14),
              Text('СПОСОБЫ',
                  style: tt.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4)),
              const SizedBox(height: 6),
              for (final method in m.methods)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    const Icon(Icons.local_fire_department_outlined,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(method, style: tt.bodyLarge?.copyWith(color: AppColors.onSurface)),
                  ]),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(zone.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('${zone.label} · до ${m.storage.days} дн.',
                          style: tt.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600)),
                    ]),
                    if (m.storage.tip.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(m.storage.tip,
                          style: tt.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Компактный степпер «− N +» для подтверждения порций.
class _PortionStepper extends StatelessWidget {
  const _PortionStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    Widget btn(IconData icon, VoidCallback? onTap) => Opacity(
          opacity: onTap == null ? 0.35 : 1,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.lightLeaf,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.leafDeep),
            ),
          ),
        );

    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn(Icons.remove, value > 1 ? () => onChanged(value - 1) : null),
      SizedBox(
        width: 34,
        child: Center(
          child: Text('$value',
              style: tt.titleMedium?.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ),
      btn(Icons.add, value < 16 ? () => onChanged(value + 1) : null),
    ]);
  }
}

/// Экран одной категории готовки: позиции с чипами способов.
/// По умолчанию — только из меню; весь каталог по ссылке.
class _PrepCategoryScreen extends StatefulWidget {
  const _PrepCategoryScreen({
    required this.emoji,
    required this.title,
    required this.modules,
    required this.menuIds,
    required this.method,
    required this.onInfo,
    required this.onHowTo,
  });
  final String emoji;
  final String title;
  final List<Module> modules;
  final Set<String> menuIds;
  final Map<String, String> method;
  final void Function(BuildContext, Module) onInfo;
  final void Function(BuildContext, Module, String) onHowTo;

  @override
  State<_PrepCategoryScreen> createState() => _PrepCategoryScreenState();
}

class _PrepCategoryScreenState extends State<_PrepCategoryScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final hasMenu =
        widget.modules.any((m) => widget.menuIds.contains(m.id));
    final items = widget.modules
        .where((m) =>
            _showAll ||
            !hasMenu ||
            widget.menuIds.contains(m.id) ||
            // Бульоны варят впрок вне меню — показываем всегда.
            m.tags.contains('broth') ||
            widget.method.containsKey(m.id))
        .toList()
      ..sort((a, b) {
        final am = widget.menuIds.contains(a.id) ? 0 : 1;
        final bm = widget.menuIds.contains(b.id) ? 0 : 1;
        return am.compareTo(bm);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.emoji} ${widget.title}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          for (final m in items) ...[
            _PrepItem(
              module: m,
              inMenu: widget.menuIds.contains(m.id),
              selected: widget.method[m.id],
              onPick: (method) =>
                  setState(() => widget.method[m.id] = method),
              onInfo: () => widget.onInfo(context, m),
              onHowTo: () =>
                  widget.onHowTo(context, m, widget.method[m.id]!),
            ),
            const SizedBox(height: 10),
          ],
          if (hasMenu)
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showAll = !_showAll),
                icon: Icon(_showAll ? Icons.unfold_less : Icons.unfold_more,
                    size: 18),
                label: Text(_showAll
                    ? 'Показать только из меню'
                    : 'Показать весь каталог'),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: LeafButton(
            onPressed: () => Navigator.maybePop(context),
            label: 'Готово',
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.text, required this.active});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: tt.labelSmall?.copyWith(
            color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          )),
    );
  }
}

class _PrepItem extends StatelessWidget {
  const _PrepItem({
    required this.module,
    required this.selected,
    required this.onPick,
    required this.onInfo,
    required this.onHowTo,
    this.inMenu = false,
  });
  final Module module;
  final String? selected;
  final ValueChanged<String> onPick;
  final VoidCallback onInfo;
  final VoidCallback onHowTo;

  /// Модуль входит в утверждённое меню — подсвечиваем бейджем.
  final bool inMenu;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(module.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(module.name,
                  style: tt.titleSmall?.copyWith(
                      color: AppColors.onSurface, fontWeight: FontWeight.w700)),
            ),
            if (inMenu) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightLeaf,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('В МЕНЮ',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.leafDeep,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    )),
              ),
              const SizedBox(width: 8),
            ],
            InkWell(
              onTap: onInfo,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.info_outline, size: 18, color: AppColors.onSurfaceVariant),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in module.methods)
                _MethodChip(
                  label: method,
                  selected: method == selected,
                  onTap: () => onPick(method),
                ),
            ],
          ),
          // Способ выбран — появляется вход в пошаговую инструкцию.
          if (selected != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onHowTo,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  const Icon(Icons.menu_book_outlined,
                      size: 16, color: AppColors.leafDeep),
                  const SizedBox(width: 6),
                  Text('Как готовить — по шагам',
                      style: tt.labelLarge?.copyWith(
                          color: AppColors.leafDeep,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.leafDeep),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: tt.labelLarge?.copyWith(
              color: selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({
    required this.index,
    required this.module,
    required this.method,
    required this.onTap,
  });
  final int index;
  final Module module;
  final String method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final zone = module.storage.zone;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('$index',
                  style: tt.labelMedium?.copyWith(
                      color: AppColors.onPrimaryContainer, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${module.emoji} ${module.name}',
                      style: tt.bodyLarge?.copyWith(
                          color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(method, style: tt.bodyMedium?.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('${zone.emoji} ${zone.label} · до ${module.storage.days} дн.',
                      style: tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.menu_book_outlined,
                  size: 18, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
