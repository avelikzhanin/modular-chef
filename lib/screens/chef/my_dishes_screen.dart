import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Push-экран Шефа «Мои блюда» — порт chef/serene_4 из Stitch.
/// Личная библиотека рецептов с фильтрами по категориям.
class MyDishesScreen extends StatefulWidget {
  const MyDishesScreen({super.key});

  @override
  State<MyDishesScreen> createState() => _MyDishesScreenState();
}

class _MyDishesScreenState extends State<MyDishesScreen> {
  int _filterIndex = 0;
  static const _filters = ['Все блюда', 'Завтраки', 'Обеды', 'Ужины', 'Десерты'];

  static const _dishes = <_Dish>[
    _Dish(
      title: 'Салат с киноа и авокадо',
      tag: 'ПП',
      timeMin: 20,
      kcal: 340,
      storage: 'Хранение: до 2 дней в герметичном контейнере.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB5RI0GY9wVH2TlDtT01AJRdD4tYffaDjiVXy3vApbEiISqFLgaI474vGxhx-t8ZSi_cXzD6jxJM-VlAcO0_omkYtNsDRIw6f7HRx14hOSRyVmE_vvSdHZoyt1HqWAVdabgvdrriHYkdHrBgetACWC8ycVQ0YabXhPWNO5TaOKDFyg9IDtwaWxfBjP5iZKMYILCVFgfnDfo18O1LjvkKDUy1Mt7Cgw_N4OcR0DSWZFpYWOyMdRgKIAUCnqRvAkQ9j7fE7UKsWf07cqX',
    ),
    _Dish(
      title: 'Крем-суп из тыквы',
      tag: 'Веган',
      timeMin: 35,
      kcal: 210,
      storage: 'Хранение: можно замораживать на срок до 1 месяца.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBNJ08Qc93gHjUCANm3F5GZYiPgJuJ29nCWL0gIhnLM6eU4_lpONdrIPY3Ka9z5i7UiOIBP_9CaMOyg7KaXmgQRwA1d6RH_Ta1J3UU2g2BVwrsKNSgDyppK-mi1MuQHLaOFk1C4th0yCQ4p62xDIgyn3297aKbUgJXj4zt3aMKwBNxvDGNgZyPxg-dyUNcgt3o0OK5J5TCgCWZj8xCL68J4Dv0-QstUfzABSuDx-7uShZI7HEHAWbny1Wr84YyajTaU4iQeKkgbSZ2F',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои блюда'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'БИБЛИОТЕКА РЕЦЕПТОВ',
            style: tt.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Ваша коллекция',
                  style: tt.displaySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = i == _filterIndex;
                return InkWell(
                  onTap: () => setState(() => _filterIndex = i),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _filters[i],
                      style: tt.labelLarge?.copyWith(
                        color: selected
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          for (final d in _dishes) ...[
            _DishCard(dish: d),
            const SizedBox(height: 16),
          ],
          _AddDishGhost(),
        ],
      ),
    );
  }
}

class _Dish {
  const _Dish({
    required this.title,
    required this.tag,
    required this.timeMin,
    required this.kcal,
    required this.storage,
    required this.imageUrl,
  });
  final String title;
  final String tag;
  final int timeMin;
  final int kcal;
  final String storage;
  final String imageUrl;
}

class _DishCard extends StatelessWidget {
  const _DishCard({required this.dish});
  final _Dish dish;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: AppColors.surfaceContainerLowest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: CachedNetworkImage(
                    imageUrl: dish.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surfaceContainer),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceContainer),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      dish.tag.toUpperCase(),
                      style: tt.labelSmall?.copyWith(
                        color: AppColors.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.title,
                    style: tt.titleLarge?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${dish.timeMin} мин',
                        style: tt.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.local_fire_department_outlined,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${dish.kcal} ккал',
                        style: tt.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(
                            color: AppColors.primaryContainer, width: 4),
                      ),
                    ),
                    child: Text(
                      dish.storage,
                      style: tt.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDishGhost extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Добавьте свое блюдо',
            style: tt.titleMedium?.copyWith(
              color: AppColors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Пополните свою библиотеку новыми кулинарными шедеврами',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              color: AppColors.onSecondaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
