import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Push-экран Гостя «Собрать блюдо» — порт guest/v4_1 из Stitch.
/// Детали одного выбранного блюда: ингредиенты, инструкция, статы, "Готово".
class AssembleDishScreen extends StatelessWidget {
  const AssembleDishScreen({super.key});

  static const _heroUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAwfJnN5pXsIkqRngCeGAzoXxm4zHhuyK_sM9ovoJBHiL5muxphYvNXaIrjr5fpTMdQ66OyJ6fJxfdv3kHioilFbkdr1NbTPoaqjwyzpoEDr127o9SrHenwNas9J30AY3Qe4Lqkif6ZoEP8xz6-OekEZkqWwyau8hPvehLgmbulWyq8E2Ays2cosnqpWTJvmkYzxBE7LutIvaKVm_Tw0KxNj9Gq0oU_zlCn1oAoyJKUEzQKaqN0xnhZN7KQH54sH645nYGFB--kOgGn';

  static const _ingredients = <_Ingredient>[
    _Ingredient('Курица гриль', '1 порция (контейнер №2 в холодильнике)'),
    _Ingredient('Рис', '1 порция'),
    _Ingredient('Брокколи', '100 г'),
    _Ingredient('Йогуртовый соус', '2 ст. ложки'),
  ];

  static const _steps = <String>[
    'Разогрейте курицу и рис в микроволновке 2 минуты.',
    'Выложите на тарелку, добавьте брокколи.',
    'Полейте йогуртовым соусом.',
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Собрать блюдо'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedNetworkImage(
                    imageUrl: _heroUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surfaceContainer),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceContainer),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: Text(
                      'Курица гриль + рис + брокколи + йогуртовый соус',
                      style: tt.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _BentoSection(
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.primary,
            title: 'Возьмите',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final ing in _ingredients) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ing.name,
                                style: tt.bodyLarge?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ing.qty,
                                style: tt.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _BentoSection(
            icon: Icons.restaurant_menu_outlined,
            iconColor: AppColors.secondary,
            title: 'Инструкция',
            backgroundColor: AppColors.secondaryContainer.withValues(alpha: 0.3),
            child: Column(
              children: [
                for (int i = 0; i < _steps.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (i + 1).toString().padLeft(2, '0'),
                          style: tt.headlineSmall?.copyWith(
                            color: AppColors.secondary.withValues(alpha: 0.25),
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _steps[i],
                            style: tt.bodyLarge?.copyWith(
                              color: AppColors.onSurface,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StatsBar(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: FilledButton(
          onPressed: () => Navigator.maybePop(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            shape: const StadiumBorder(),
            textStyle: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          child: const Text('Готово! 🍽️'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _Ingredient {
  const _Ingredient(this.name, this.qty);
  final String name;
  final String qty;
}

class _BentoSection extends StatelessWidget {
  const _BentoSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: tt.titleLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    Widget cell(String label, String value) {
      return Column(
        children: [
          Text(
            label.toUpperCase(),
            style: tt.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          cell('Калории', '450 ккал'),
          Container(width: 1, height: 32, color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          cell('Время', '5 мин'),
          Container(width: 1, height: 32, color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          cell('Сложность', 'Легко'),
        ],
      ),
    );
  }
}
