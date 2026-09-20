import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/services/app_settings.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/pantry_stock.dart';
import 'package:modular_chef/shell/role.dart';
import 'package:modular_chef/shell/role_provider.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/theme/module_visuals.dart';
import 'package:modular_chef/widgets/atmospheric_header.dart';
import 'package:modular_chef/widgets/fade_in_up.dart';
import 'package:modular_chef/widgets/leaf_button.dart';

/// Гостевой экран «Запасы»: реальные порции из готовки Шефа с честной
/// свежестью (тикает от даты готовки). Пока Шеф ничего не приготовил —
/// демо-пример.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final stock = context.watch<PantryStock>();
    final catalog = context.watch<CatalogService>();
    final live = !stock.isEmpty && catalog.isLoaded;

    // Живые карточки: свежесть = сколько дней срока ещё осталось.
    final cards = <Widget>[];
    if (live) {
      final entries = stock.entries.toList();
      final now = DateTime.now();
      double fraction(StockEntry e, Module m) {
        final age = now.difference(e.cookedAt).inDays;
        return ((m.storage.days - age) / m.storage.days).clamp(0.0, 1.0);
      }

      final withMods = [
        for (final e in entries)
          if (catalog.moduleById(e.moduleId) != null)
            (entry: e, module: catalog.moduleById(e.moduleId)!),
      ]..sort((a, b) => fraction(a.entry, a.module)
          .compareTo(fraction(b.entry, b.module)));

      for (int i = 0; i < withMods.length; i++) {
        final e = withMods[i].entry;
        final m = withMods[i].module;
        final f = fraction(e, m);
        final leftDays =
            (m.storage.days - now.difference(e.cookedAt).inDays).clamp(0, 99);
        final critical = f <= 0.34 || leftDays <= 1;
        final img = moduleImage(m.id);
        cards.addAll([
          FadeInUp(
            delayMs: 140 + i * 70,
            child: _DishCard(
              image: img,
              iconImage: img,
              fallbackIcon: moduleIcon(m.category),
              badge: m.category == ModuleCategory.protein
                  ? const _Badge.protein()
                  : const _Badge.chef(),
              title: '${m.name} (${e.portions} порц.)',
              description: m.storage.tip.isNotEmpty
                  ? m.storage.tip
                  : 'Готово к разогреву.',
              freshnessLabel: leftDays <= 1
                  ? 'УПОТРЕБИТЬ ДО ЗАВТРА'
                  : 'СВЕЖЕСТЬ ${(f * 100).round()}%',
              freshnessNote: 'Осталось $leftDays дн.',
              freshness: f,
              critical: critical,
            ),
          ),
          const SizedBox(height: 20),
        ]);
      }
    }

    final soups = !live
        ? 0
        : stock.entries
            .where((e) =>
                catalog.moduleById(e.moduleId)?.category == ModuleCategory.soup)
            .fold<int>(0, (s, e) => s + e.portions);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        children: [
          const AtmosphericHeader(
            title: 'Запасы',
            subtitle:
                'Свежесть заготовок под контролем — ешь, пока они в лучшей форме.',
            background: 'assets/art/bg_stock.png',
            trailing: RoleSwitcher(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

          // Сводка
          FadeInUp(
            delayMs: 70,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: _paperDeco,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Обзор запасов',
                      style: tt.titleLarge?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                      live
                          ? 'Готово ${stock.totalPortions} порций еды на ближайшие дни'
                          : 'Шеф ещё не завершал готовку — покажу пример. Порции появятся сами после «Завершить готовку».',
                      style: tt.bodyMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!live) ...[
                        _chip(tt, Icons.soup_kitchen_rounded, '2 супа',
                            bg: AppColors.lightLeaf, fg: AppColors.leafDeep),
                        _chip(tt, Icons.restaurant_rounded, '3 основных блюда',
                            bg: const Color(0xFFE4D9C6),
                            fg: AppColors.onSurfaceVariant),
                      ] else ...[
                        if (soups > 0)
                          _chip(tt, Icons.soup_kitchen_rounded,
                              '$soups порц. супа',
                              bg: AppColors.lightLeaf, fg: AppColors.leafDeep),
                        _chip(
                            tt,
                            Icons.restaurant_rounded,
                            '${stock.totalPortions - soups} порц. основного',
                            bg: const Color(0xFFE4D9C6),
                            fg: AppColors.onSurfaceVariant),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (live)
            ...cards
          else ...[
            // Демо-карточки, пока запасы пустые.
            const FadeInUp(
              delayMs: 140,
              child: _DishCard(
                image: 'assets/art/icons/pumpkin_soup.png',
                iconImage: 'assets/art/icons/pumpkin_soup.png',
                badge: _Badge.chef(),
                title: 'Тыквенный крем-суп (2 порции)',
                description:
                    'Бархатистая текстура с нотками мускатного ореха и запечёнными семечками. Идеальный обед для уютного вечера.',
                freshnessLabel: 'СВЕЖЕСТЬ 85%',
                freshnessNote: 'Осталось 2 дня',
                freshness: 0.85,
                critical: false,
              ),
            ),
            const SizedBox(height: 20),
            const FadeInUp(
              delayMs: 210,
              child: _DishCard(
                image: 'assets/art/demo_lunch.png',
                iconImage: 'assets/art/icons/chicken_breast.png',
                badge: _Badge.protein(),
                title: 'Куриное филе с рисом (1 порция)',
                description:
                    'Нежное филе с рассыпчатым рисом. Готово к разогреву.',
                freshnessLabel: 'УПОТРЕБИТЬ ДО ЗАВТРА',
                freshnessNote: '30%',
                freshness: 0.30,
                critical: true,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Алерт пополнения — глиняная карточка
          FadeInUp(
            delayMs: 280,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.clay,
                borderRadius: BorderRadius.circular(24),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.shopping_basket_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Время пополнить запасы?',
                                style: tt.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              live
                                  // Считаем по факту: сколько семейных приёмов
                                  // осталось из того, что реально приготовлено.
                                  ? (stock.totalPortions ~/
                                              context
                                                  .read<AppSettings>()
                                                  .householdSize ==
                                          0
                                      ? 'Запасы закончились — пора собрать новое меню и приготовить.'
                                      : 'Осталось примерно ${_timesWord(stock.totalPortions ~/ context.read<AppSettings>().householdSize)} на семью. Дальше — новое меню.')
                                  : 'Соберите меню и приготовьте заготовки — здесь появится честный остаток.',
                              style: tt.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LeafButton(
                    onPressed: () =>
                        context.read<RoleProvider>().setRole(UserRole.chef),
                    height: 48,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Собрать новое меню',
                            style: tt.titleMedium?.copyWith(
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 20, color: AppColors.onPrimaryContainer),
                      ],
                    ),
                  ),
                ],
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

  static String _timesWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return '$n приём';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return '$n приёма';
    }
    return '$n приёмов';
  }

  static BoxDecoration get _paperDeco => BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint, blurRadius: 24, offset: Offset(0, 8)),
        ],
      );

  Widget _chip(TextTheme tt, IconData icon, String text,
          {required Color bg, required Color fg}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(text,
                style:
                    tt.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge.chef()
      : text = 'ШЕФ РЕКОМЕНДУЕТ',
        heart = true;
  const _Badge.protein()
      : text = 'ВЫСОКИЙ БЕЛОК',
        heart = false;
  final String text;
  final bool heart;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (heart) ...[
            const Icon(Icons.favorite_rounded, size: 14, color: AppColors.clay),
            const SizedBox(width: 5),
          ],
          Text(text,
              style: tt.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              )),
        ],
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({
    required this.image,
    required this.iconImage,
    this.fallbackIcon = Icons.restaurant_rounded,
    required this.badge,
    required this.title,
    required this.description,
    required this.freshnessLabel,
    required this.freshnessNote,
    required this.freshness,
    required this.critical,
  });

  /// null — у заготовки ещё нет своей акварели: рисуем значок категории,
  /// а не чужое демо-фото.
  final String? image;
  final String? iconImage;
  final IconData fallbackIcon;
  final Widget badge;
  final String title;
  final String description;
  final String freshnessLabel;
  final String freshnessNote;
  final double freshness;
  final bool critical;

  static const _error = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фото/иллюстрация сверху, бейдж поверх
          Stack(
            children: [
              Container(
                height: 190,
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: image == null
                    ? Center(
                        child: Icon(fallbackIcon,
                            size: 64, color: AppColors.primaryContainer))
                    : Image.asset(image!, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => iconImage == null
                            ? Center(
                                child: Icon(fallbackIcon,
                                    size: 64,
                                    color: AppColors.primaryContainer))
                            : Image.asset(iconImage!, fit: BoxFit.contain)),
              ),
              Positioned(top: 14, left: 14, child: badge),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: tt.titleLarge?.copyWith(
                        color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(description,
                    style: tt.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant, height: 1.4)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(freshnessLabel,
                          style: tt.labelMedium?.copyWith(
                            color: critical ? _error : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          )),
                    ),
                    Text(freshnessNote,
                        style: tt.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: freshness,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(
                        critical ? _error : AppColors.primaryContainer),
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
