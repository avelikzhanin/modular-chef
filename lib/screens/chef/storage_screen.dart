import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Шеф-экран «Карта хранения» — переделанный chef/serene_3.
/// Конкретные позиции с днями недели и подсказками вместо абстрактных зон.
class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  static const _zones = <_Zone>[
    _Zone(
      emoji: '🟩',
      title: 'Холодильник',
      subtitle: '3–4 дня',
      accent: AppColors.primaryContainer,
      items: [
        _Item('Курица порции 1–3', 'пн-ср', tip: 'Контейнеры подписаны №1–3'),
        _Item('Лосось 1–2', 'пн-вт', tip: 'Самый скоропортящийся — съесть первым'),
        _Item('Рис жасмин', 'пн-ср', tip: 'Глубокий контейнер, отделить от соусов'),
        _Item('Йогуртовый соус', 'пн-ср', tip: 'Стеклянная банка, до 3 дней'),
        _Item('Куриный бульон', 'пн-чт', tip: 'Использовать в супах'),
      ],
    ),
    _Zone(
      emoji: '🟦',
      title: 'Морозилка',
      subtitle: 'на 2-ю неделю',
      accent: Color(0xFFCFE0F0),
      items: [
        _Item('Курица порции 4–6', 'разморозить в ср',
            tip: 'За 12 часов в холодильник, не СВЧ'),
        _Item('Индейка', 'разморозить в чт', tip: 'Сразу две порции'),
        _Item('Бешамель кубиками', 'по 30 г',
            tip: 'При разогреве добавь ложку молока'),
        _Item('Томатный соус кубиками', 'на 4 раза',
            tip: 'Заморозка 3 месяца — делай с запасом'),
        _Item('Бульон в банках', '500 мл × 3', tip: 'Оставь 1 см на расширение'),
      ],
    ),
    _Zone(
      emoji: '🟣',
      title: 'Вакуум',
      subtitle: '+3–5 дней к сроку',
      accent: Color(0xFFEAD7E8),
      items: [
        _Item('Лосось 3–4', 'до чт-пт',
            tip: 'Без вакуума пропадёт во вторник'),
        _Item('Стейк', 'до ср',
            tip: 'Можно после маринования — вкус только усилится'),
        _Item('Сыр пармезан', 'до 2 недель', tip: 'Открытый кусок'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Карта хранения',
            style: tt.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Конкретные позиции — куда, когда и с какой подсказкой.',
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 24),
          for (final z in _zones) ...[
            _ZoneBlock(zone: z),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Правило «первым пришёл — первым ушёл»: ставь свежие порции вглубь, доедай ближние.',
                    style: tt.bodyMedium?.copyWith(
                      color: AppColors.onTertiaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Zone {
  const _Zone({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.items,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final List<_Item> items;
}

class _Item {
  const _Item(this.name, this.when, {required this.tip});
  final String name;
  final String when;
  final String tip;
}

class _ZoneBlock extends StatelessWidget {
  const _ZoneBlock({required this.zone});
  final _Zone zone;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: zone.accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(zone.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  zone.title.toUpperCase(),
                  style: tt.labelMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            zone.subtitle,
            style: tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final item in zone.items) ...[
            _StorageItemTile(item: item),
            if (item != zone.items.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _StorageItemTile extends StatelessWidget {
  const _StorageItemTile({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: tt.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.when,
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.tip,
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
