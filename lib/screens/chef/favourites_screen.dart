import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/services/favourite_combos.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Push-экран Шефа «Мои сочетания» (из Профиля). Любимые тройки, которые
/// генератор использует приоритетно. Добавляются по ♥ на тарелках меню.
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final fav = context.watch<FavouriteCombos>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои сочетания'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: fav.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border,
                        size: 48, color: AppColors.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'Пока пусто. Отмечай ♥ на тарелках в «Меню на 2 недели» — '
                      'они будут попадать сюда и в новые меню приоритетно.',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Эти сочетания генератор старается включить в новые меню.',
                  style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < fav.items.length; i++) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, size: 18, color: AppColors.secondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fav.items[i].title,
                            style: tt.bodyLarge?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 18, color: AppColors.onSurfaceVariant),
                          onPressed: () => context.read<FavouriteCombos>().removeAt(i),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}
