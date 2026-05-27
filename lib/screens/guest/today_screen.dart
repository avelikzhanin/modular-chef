import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Гостевой экран «Сегодня» — порт guest/v4_4 из Stitch.
/// Показывает 3 приёма пищи на день + предупреждение о скоропортящихся.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  static const _meals = <_Meal>[
    _Meal(
      label: 'Завтрак',
      title: 'Овсянка с ягодами и мёдом',
      durationMin: 0,
      note: 'Достать из холодильника. Перемешать, есть.',
      noteColor: Color(0xFF22C55E),
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD3mzy5PY7JxcjzLmVvtVTXUEpygeqRaiaz7piD4YqlQUzyPSqk9V39D4jYY8lglYisH4HOS3gP9Oyvf26euX6WI3VkaQq3OA2TZTOCQ346G2f8OGfQ7BgSEbaB0C2BzAd2ZBYyq9qzj2VEriqurYlB7qpQ6fDmnZY6siwk2OWiBb6BnF8pUpIssgMakKrpd3OFqszHLQ3dPuH4gkjXm8-dgeVlpDH6Fk8yoTVJj5WICOc_yTd8zOSWKDioZ78BWRBU3DBSnlKb5yRm',
    ),
    _Meal(
      label: 'Обед',
      title: 'Курица гриль + рис + брокколи',
      durationMin: 2,
      note: 'Разогреть 2 мин. Добавить йогуртовый соус.',
      noteColor: Color(0xFF22C55E),
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAZ6jmbKEIl0neuzboqXRPP7urO-vIR3HF9bvtUDfn8_rKwH-72aE8RhjENu-IkGpg0Ith2gxCGFmbV0YgOJ-apFJjfIzV_LfWTYOK0vUQZuPQ_Urx0KzKMuX1Ia3YWhw1vbHDChC0759zg3bXsMzmiN_GH0NL3QP2JCFLf7UHIJHOpvLApgXON0jOOdBWb6S-3ZqmcZvmphaDENb-dYbAw6NDUTipImsWS74AD_SOYhwR-iTovZZAKVd7H5D7QqGC58EV3vmMc_IsO',
    ),
    _Meal(
      label: 'Ужин',
      title: 'Лосось + булгур + салат из овощей',
      durationMin: 5,
      note: 'Лосось из вакуума. Булгур разогреть 2 мин.',
      noteColor: Color(0xFFA855F7),
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAPerW9GUYzdA3hwDDPag4IIEoJfTM0UyHKkxjOn2kJngfypx4JB6KLH1pB-wKOpsEdSApg5Fcev-CJMgewcGAaYPIrC05ssEQezezKi7x9M6Av4to7Zb6CPOVNZeZ2mfw0WlxrKa6FKt4KT4d9LsxTwGwN6FZWVbQpXSP7e7-nrJ8UIs0l8vfbth2emiccZvtTIydnld2nsRNY5DqGl53pA2M7Z0wsue1e8KxAM0sFypvMt_ibsAVdNJUBB5NxqzIfRrY7mMPRmRnW',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
        toolbarHeight: 56,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Понедельник, 14 апреля',
            style: tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'Привет! Вот твоё меню на сегодня',
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          const _AlertBanner(text: 'Йогуртовый соус — последний день, используй сегодня'),
          const SizedBox(height: 24),
          for (final m in _meals) ...[
            _MealCard(meal: m),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.3),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: const StadiumBorder(),
                textStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              onPressed: () => context.push(Routes.guestAssembleDish),
              label: const Text('Хочу что-то другое'),
              icon: const Icon(Icons.trending_flat, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meal {
  const _Meal({
    required this.label,
    required this.title,
    required this.durationMin,
    required this.note,
    required this.noteColor,
    required this.imageUrl,
  });
  final String label;
  final String title;
  final int durationMin;
  final String note;
  final Color noteColor;
  final String imageUrl;
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFA83836)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: tt.bodyMedium?.copyWith(
                color: AppColors.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});
  final _Meal meal;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: AppColors.surfaceContainerLowest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: meal.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surfaceContainer),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceContainer),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${meal.durationMin} мин',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
                    meal.label.toUpperCase(),
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meal.title,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: meal.noteColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          meal.note,
                          style: tt.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
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
      ),
    );
  }
}
