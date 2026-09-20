import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/storage.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/pantry_stock.dart';
import 'package:modular_chef/services/purchase_catalog.dart';
import 'package:modular_chef/services/shopping_list.dart';
import 'package:modular_chef/services/storage_choices.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/theme/module_visuals.dart';
import 'package:modular_chef/widgets/atmospheric_header.dart';

/// «Запасы и хранение»: четыре больших места — Холодильник, Морозилка,
/// Вакуум, Кладовая. Внутри каждого: сырые продукты и готовые заготовки
/// по категориям. Партию можно разделить между зонами.
class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  static const zoneOrder = [
    StorageZone.fridge,
    StorageZone.freezer,
    StorageZone.vacuum,
    StorageZone.pantry,
  ];

  static const zoneAccents = <StorageZone, Color>{
    StorageZone.pantry: Color(0xFFE4D9C6),
    StorageZone.fridge: AppColors.primaryContainer,
    StorageZone.freezer: Color(0xFFCFE0F0),
    StorageZone.vacuum: Color(0xFFEAD7E8),
  };

  static const zoneSubtitles = <StorageZone, String>{
    StorageZone.pantry: 'сухое и запасы',
    StorageZone.fridge: 'съесть в ближайшие дни',
    StorageZone.freezer: 'долгий запас',
    StorageZone.vacuum: '+3–5 дней к сроку',
  };

  /// Срок хранения в зоне.
  static String daysLabel(Module m, StorageZone zone) {
    if (zone == m.storage.zone) return 'до ${m.storage.days} дн.';
    return switch (zone) {
      StorageZone.fridge => '3–4 дня',
      StorageZone.freezer => '2–3 месяца',
      StorageZone.vacuum => '+3–5 дней',
      StorageZone.pantry => 'до 2 недель',
    };
  }

  static const _fridgeSections = {
    'Молочное, сыры и яйца',
    'Овощи и зелень',
    'Фрукты и ягоды',
    'Мясо и птица',
    'Рыба и морепродукты',
  };

  static const _fridgeIngIds = {
    'ing_cream', 'ing_milk', 'ing_butter', 'ing_parmesan',
    'ing_processed_cheese', 'ing_tomatoes', 'ing_cucumber', 'ing_basil',
    'ing_dill', 'ing_parsley', 'ing_cilantro', 'ing_lemon', 'ing_lime',
    'ing_kefir', 'ing_radish', 'ing_ginger',
  };

  static String prepGroup(Module m) {
    if (m.category == ModuleCategory.soup) return 'Супы';
    if (m.category == ModuleCategory.side) return 'Гарниры';
    if (m.category == ModuleCategory.vegetable) return 'Овощи';
    if (m.category == ModuleCategory.sauce) return 'Соусы';
    if (kFishIds.contains(m.id)) return 'Рыба и морепродукты';
    if (kPoultryIds.contains(m.id)) return 'Птица';
    if (kPlantProteinIds.contains(m.id)) return 'Растительное';
    return 'Мясо';
  }

  static const prepGroupOrder = [
    'Мясо', 'Птица', 'Рыба и морепродукты', 'Растительное',
    'Гарниры', 'Овощи', 'Супы', 'Соусы',
  ];

  /// Домашний продукт: ключ, имя, иконка, зона по умолчанию.
  static ({String key, String name, String? iconId, StorageZone def})
      homeEntry(String key, CatalogService catalog) {
    if (key.startsWith('ing:')) {
      final name = key.substring(4);
      final iconId = kIngredientIcons[name];
      final def = (iconId != null && _fridgeIngIds.contains(iconId))
          ? StorageZone.fridge
          : StorageZone.pantry;
      return (key: key, name: name, iconId: iconId, def: def);
    }
    final m = catalog.moduleById(key);
    final name = m?.name ?? key;
    final def = (m != null && _fridgeSections.contains(shopSection(m)))
        ? StorageZone.fridge
        : StorageZone.pantry;
    return (key: key, name: name, iconId: key, def: def);
  }

  Future<void> _addHomeProduct(BuildContext context) async {
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
            Text('Что есть дома?',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Например, гречка',
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
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Добавить'),
              ),
            ),
          ],
        ),
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      final list = context.read<ShoppingList>();
      final key = 'ing:$name';
      if (!list.has(key)) list.toggle(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catalog = context.watch<CatalogService>();
    final choices = context.watch<StorageChoices>();
    final stock = context.watch<PantryStock>();
    final list = context.watch<ShoppingList>();

    final home = catalog.isLoaded
        ? [for (final k in list.haveIds) homeEntry(k, catalog)]
        : <({String key, String name, String? iconId, StorageZone def})>[];

    int productsIn(StorageZone z) =>
        home.where((h) => choices.homeZoneFor(h.key, h.def) == z).length;
    int prepsIn(StorageZone z) => stock.entries
        .where((e) => e.zone == z && e.portions > 0)
        .map((e) => e.moduleId)
        .toSet()
        .length;

    final empty = home.isEmpty && stock.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        children: [
          const AtmosphericHeader(
            title: 'Запасы и хранение',
            subtitle: 'Четыре места — всё по полкам.',
            background: 'assets/art/bg_storage.png',
            trailing: RoleSwitcher(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: Text('Где что лежит',
                        style: tt.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                  InkWell(
                    onTap: () => _addHomeProduct(context),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.lightLeaf,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('+ Продукт',
                          style: tt.labelMedium?.copyWith(
                              color: AppColors.leafDeep,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                // Хвосты — доесть или заморозить.
                Builder(builder: (context) {
                  final leftovers = [
                    for (final e in stock.entries)
                      if (e.portions > 0 &&
                          e.portions <= 2 &&
                          e.zone != StorageZone.freezer &&
                          catalog.moduleById(e.moduleId) != null)
                        '${catalog.moduleById(e.moduleId)!.name} (${e.portions} порц.)',
                  ];
                  if (leftovers.isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color:
                          AppColors.tertiaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '🍳 Хвосты: ${leftovers.join(', ')}. Доешь или переложи в морозилку.',
                      style: tt.bodySmall?.copyWith(
                          color: AppColors.onTertiaryContainer, height: 1.35),
                    ),
                  );
                }),
                if (empty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightLeaf.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Пока пусто. Отмечай «дома» в Покупках, добавляй продукты и завершай готовку — всё разложится по местам.',
                      style: tt.bodySmall
                          ?.copyWith(color: AppColors.leafDeep, height: 1.4),
                    ),
                  ),
                // Большие карточки мест 2×2.
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    for (final z in zoneOrder)
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => _ZoneDetailScreen(zone: z)),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                  color: AppColors.shadowTint,
                                  blurRadius: 24,
                                  offset: Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: zoneAccents[z],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(z.emoji,
                                    style: const TextStyle(fontSize: 22)),
                              ),
                              const Spacer(),
                              Text(z.label,
                                  style: tt.titleMedium?.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                (productsIn(z) + prepsIn(z)) == 0
                                    ? zoneSubtitles[z]!
                                    : [
                                        if (productsIn(z) > 0)
                                          '${productsIn(z)} прод.',
                                        if (prepsIn(z) > 0)
                                          '${prepsIn(z)} загот.',
                                      ].join(' · '),
                                style: tt.labelSmall?.copyWith(
                                    color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Внутренность одного места хранения.
class _ZoneDetailScreen extends StatelessWidget {
  const _ZoneDetailScreen({required this.zone});
  final StorageZone zone;

  void _moveHomeItem(BuildContext context, String key, String name) {
    final tt = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(name,
                  style: tt.titleLarge?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final z in StorageScreen.zoneOrder)
                if (z != zone)
                  ListTile(
                    dense: true,
                    leading:
                        Text(z.emoji, style: const TextStyle(fontSize: 18)),
                    title: Text('Переложить: ${z.label.toLowerCase()}'),
                    onTap: () {
                      context.read<StorageChoices>().chooseHome(key, z);
                      Navigator.pop(ctx);
                    },
                  ),
              const Divider(),
              ListTile(
                dense: true,
                leading:
                    const Icon(Icons.close, size: 18, color: AppColors.clay),
                title: const Text('Убрать — закончился'),
                onTap: () {
                  context.read<ShoppingList>().toggle(key);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// «Переложить часть»: сколько порций и куда.
  void _splitBatch(BuildContext context, Module m, int inZone) {
    var count = inZone;
    var target = zone == StorageZone.freezer
        ? StorageZone.fridge
        : StorageZone.freezer;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final tt = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${m.name} — переложить',
                    style: tt.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Сейчас здесь: $inZone порц.',
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 14),
                Row(children: [
                  Text('Сколько:',
                      style: tt.bodyLarge
                          ?.copyWith(color: AppColors.onSurface)),
                  const Spacer(),
                  IconButton(
                    onPressed: count > 1
                        ? () => setSheet(() => count--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$count',
                      style: tt.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800)),
                  IconButton(
                    onPressed: count < inZone
                        ? () => setSheet(() => count++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ]),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final z in StorageScreen.zoneOrder)
                      if (z != zone)
                        ChoiceChip(
                          label: Text('${z.emoji} ${z.label}'),
                          selected: target == z,
                          onSelected: (_) => setSheet(() => target = z),
                        ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    context
                        .read<PantryStock>()
                        .move(m.id, zone, target, count);
                    Navigator.pop(ctx);
                  },
                  child: Text('Переложить $count порц.'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final catalog = context.watch<CatalogService>();
    final choices = context.watch<StorageChoices>();
    final stock = context.watch<PantryStock>();
    final list = context.watch<ShoppingList>();

    final products = catalog.isLoaded
        ? ([
            for (final k in list.haveIds)
              StorageScreen.homeEntry(k, catalog)
          ]..retainWhere(
            (h) => choices.homeZoneFor(h.key, h.def) == zone))
        : <({String key, String name, String? iconId, StorageZone def})>[];
    products.sort((a, b) => a.name.compareTo(b.name));

    // Заготовки этой зоны: modId → порции.
    final zonePortions = <String, int>{};
    for (final e in stock.entries) {
      if (e.zone == zone && e.portions > 0) {
        zonePortions[e.moduleId] =
            (zonePortions[e.moduleId] ?? 0) + e.portions;
      }
    }
    final prepMods = [
      for (final id in zonePortions.keys)
        if (catalog.moduleById(id) != null) catalog.moduleById(id)!,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${zone.emoji} ${zone.label}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(StorageScreen.zoneSubtitles[zone] ?? '',
              style:
                  tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          if (products.isEmpty && prepMods.isEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightLeaf.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Здесь пока пусто.',
                  style: tt.bodySmall?.copyWith(color: AppColors.leafDeep)),
            ),
          ],
          if (products.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('ПРОДУКТЫ',
                style: tt.labelSmall?.copyWith(
                  color: AppColors.leafDeep,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in products)
                  InkWell(
                    onTap: () => _moveHomeItem(context, p.key, p.name),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (p.iconId != null &&
                            moduleImage(p.iconId!) != null) ...[
                          Image.asset(moduleImage(p.iconId!)!,
                              width: 18, height: 18),
                          const SizedBox(width: 5),
                        ],
                        Text(p.name,
                            style: tt.labelMedium
                                ?.copyWith(color: AppColors.onSurface)),
                      ]),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Тап — переложить или убрать.',
                  style: tt.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic)),
            ),
          ],
          if (prepMods.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('ЗАГОТОВКИ',
                style: tt.labelSmall?.copyWith(
                  color: AppColors.leafDeep,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                )),
            for (final group in StorageScreen.prepGroupOrder) ...[
              Builder(builder: (_) {
                final items = [
                  for (final m in prepMods)
                    if (StorageScreen.prepGroup(m) == group) m,
                ]..sort((a, b) => a.name.compareTo(b.name));
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(group,
                        style: tt.labelMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (final m in items) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          if (moduleImage(m.id) != null)
                            Image.asset(moduleImage(m.id)!,
                                width: 32, height: 32)
                          else
                            Text(m.emoji,
                                style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${m.name} · ${zonePortions[m.id]} порц.',
                                    style: tt.bodyLarge?.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  '${StorageScreen.daysLabel(m, zone)}'
                                  '${m.storage.tip.isNotEmpty ? ' · ${m.storage.tip}' : ''}',
                                  style: tt.labelSmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Переложить часть',
                            onPressed: () => _splitBatch(
                                context, m, zonePortions[m.id]!),
                            icon: const Icon(Icons.swap_horiz_rounded,
                                color: AppColors.leafDeep),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}
