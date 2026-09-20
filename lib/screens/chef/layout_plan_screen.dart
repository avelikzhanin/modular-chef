import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/storage.dart';
import 'package:modular_chef/services/app_settings.dart';
import 'package:modular_chef/services/pantry_stock.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/theme/module_visuals.dart';
import 'package:modular_chef/widgets/leaf_button.dart';

/// Позиция плана раскладки: что, сколько порций, куда убрано.
typedef LayoutItem = ({Module module, int portions, StorageZone zone});

/// «План раскладки» — модульная порционка (вариант Б):
/// каждой заготовке — своя тара, семейные порции, скоропорт с датами,
/// излишек из холодильника — в морозилку одной кнопкой.
class LayoutPlanScreen extends StatelessWidget {
  const LayoutPlanScreen({super.key, required this.items});

  final List<LayoutItem> items;

  static const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  /// Сколько семейных приёмов разумно держать в холодильнике.
  static const _fridgeMeals = 3;

  bool _isCubes(Module m) => m.category == ModuleCategory.sauce;
  bool _isJars(Module m) =>
      m.category == ModuleCategory.soup; // и супы, и бульоны
  bool _isFlat(Module m) => const {
        'meatballs', 'chicken_cutlets', 'fish_cutlets', 'chickpea_cutlets',
        'falafel', 'ground_beef', 'chicken_mince', 'turkey_mince',
      }.contains(m.id);

  /// Рекомендованный перенос в морозилку из холодильника (излишек).
  int _overflow(LayoutItem it, int household) {
    if (it.zone != StorageZone.fridge) return 0;
    final keep = household * _fridgeMeals;
    return it.portions > keep ? it.portions - keep : 0;
  }

  /// Человеческая инструкция раскладки для позиции.
  List<String> _lines(LayoutItem it, int household, DateTime now) {
    final m = it.module;
    final p = it.portions;

    if (_isCubes(m)) {
      return [
        'Разлей по силиконовой форме кубиками.',
        if (it.zone == StorageZone.freezer)
          'Заморозь, завтра пересыпь кубики в zip-пакет с датой.'
        else
          'Часть — в баночку в холодильник, остальное кубиками в морозилку.',
      ];
    }
    if (_isJars(m)) {
      final jars = (p / 2).ceil();
      final fridgeJars = it.zone == StorageZone.fridge
          ? jars
          : (p >= 2 ? 1 : 0);
      return [
        'Разлей по банкам 0,5 л (~2 порц.) — всего $jars шт.',
        if (it.zone == StorageZone.freezer && fridgeJars > 0)
          '$fridgeJars банку — в холодильник на ближайшие дни, '
              '${jars - fridgeJars} — в морозилку (1 см до крышки!).'
        else if (it.zone == StorageZone.freezer)
          'Все в морозилку, оставь 1 см до крышки.',
      ];
    }
    if (_isFlat(m)) {
      return [
        'Выложи пластом на пергамент, порциями по $household шт/приём.',
        'Заморозь пластом, потом сложи в пакет — не слипнутся.',
      ];
    }
    // Обычный модуль: контейнеры по семейному приёму.
    final containers = (p / household).ceil();
    final over = _overflow(it, household);
    final fridgeCont = ((p - over) / household).ceil();
    final lines = <String>[
      'Разложи по контейнерам: $containers шт × $household порц.',
    ];
    if (it.zone == StorageZone.fridge) {
      final days = [
        for (int i = 0; i < fridgeCont && i < 5; i++)
          _weekdays[(now.weekday - 1 + i) % 7],
      ];
      lines.add('В холодильник: $fridgeCont шт — подпиши ${days.join(', ')}.');
      if (over > 0) {
        lines.add(
            'Излишек $over порц. — в морозилку: за $_fridgeMeals дня столько не съесть.');
      }
    } else {
      lines.add('Убери в ${it.zone.label.toLowerCase()} с датой.');
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final household = context.watch<AppSettings>().householdSize;
    final now = DateTime.now();

    final overflowItems = [
      for (final it in items)
        if (_overflow(it, household) > 0) it,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('План раскладки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
        children: [
          Text(
            'Модульная порционка: каждой заготовке — своя тара, порции семейные (по $household). Бери и грей, ничего не отламывая.',
            style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final it in items) ...[
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (moduleImage(it.module.id) != null)
                      Image.asset(moduleImage(it.module.id)!,
                          width: 34, height: 34)
                    else
                      Text(it.module.emoji,
                          style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${it.module.name} · ${it.portions} порц. → ${it.zone.emoji} ${it.zone.label.toLowerCase()}',
                        style: tt.titleSmall?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  for (final line in _lines(it, household, now))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(color: AppColors.leafDeep)),
                          Expanded(
                            child: Text(line,
                                style: tt.bodySmall?.copyWith(
                                    color: AppColors.onSurface,
                                    height: 1.35)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightLeaf.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '🏷 Подписывай малярным скотчем: что + дата. Тара: контейнеры ~800 мл (семейный приём), малые ~350 мл, банки 0,5 л, силиконовая форма для кубиков, zip-пакеты.',
              style: tt.bodySmall
                  ?.copyWith(color: AppColors.leafDeep, height: 1.4),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: overflowItems.isEmpty
              ? LeafButton(
                  onPressed: () => Navigator.maybePop(context),
                  label: 'Готово — разложено',
                )
              : LeafButton(
                  onPressed: () {
                    final stock = context.read<PantryStock>();
                    for (final it in overflowItems) {
                      stock.move(it.module.id, StorageZone.fridge,
                          StorageZone.freezer, _overflow(it, household));
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Излишки перенесены в морозилку — запасы обновлены'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.maybePop(context);
                  },
                  label:
                      'Разложить по плану (излишки → морозилка)',
                ),
        ),
      ),
    );
  }
}
