import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Гостевой экран «Запасы» — порт guest/v4_3 из Stitch.
/// Показывает имеющиеся модули по группам + сборка снизу.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  static const _proteinChicken =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCqUKP3vghac9whRmxBaxNWdN26JZTznLgod9nqeKC1-mhCbnvrbCtoNQSC46SLXXHU7z3eL_2zjhPDELh4kp0gjBRYyOeJfD_oSH76ti-RXugJoyRLSDsTgdWmVcjn4erhxZxkJZoKuixcayijPs0NCr66zY2AyFEs828hMA8SFlBWVv3hdL6wR3kot4Hws1lgyLBPO1JJn_5ldnLaDLDhe-1dM01JTtjeRyQ4xcAbq7B0VcZ3GQ0MFsjaC4U0imLTd4ZedJF5_8iM';
  static const _proteinSalmon =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDrmSAVixaxU_zu8Dh5Oz31dYcZIffs2LEkFj4gatI4mZzBgamInfNgcJoNBW-Nu4IcWATcLC1C07sYYZvwwybisot-4MhJRLTgi2rsZ1xrBoOz_vqAfMeYyP_5P9ZxTPYEw-KV-wxCKAJIsByunyklHT78l3WM01OYv0wk9Hc0MovWfOChk7Ce-J2LkMEDmMf-Qi7qJs0rO-Yahbt4G3IBgXxataRA9YTfhDDm2kRsV4Rf6VLE2H7WIFMar9xNfAYlSzV0cfzfj56y';
  static const _proteinSteak =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDhSc23adN4Z5Tgy0OZU_pP_SB9FNAERRnsxa-PvZGwzjY1tU_kkoT8hJga4PKWTo0Acm240GLgUPAgXoXs7ZfavJrQE5aL_0bx8kVp0160_G0V_PSJPZu4_RG0d49DuyuuUxtNO-mMkQKWl7Iq29z_HMh-sVv9_wUPKOuymX534OPdWNB6_9MBprMKZs_HFss6iasr-CLQdZDcc7oRt_FVrhYXZQCscbRhzmaEsJ5mRjt_yetsTdP1SwnS3bBUwGr3X1Z3GpQIeLLx';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
            children: [
              Text(
                'Что есть в запасе',
                style: tt.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Собери своё блюдо из готовых модулей',
                style: tt.bodyLarge,
              ),
              const SizedBox(height: 28),
              const _SuggestionBanner(
                primary: 'Свежий салат заканчивается завтра. Попробуй:',
                secondary: 'курица + салат + лимонная заправка',
              ),
              const SizedBox(height: 36),
              const _SectionHeader(title: 'Белки', meta: '3 варианта'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ModuleCard(
                      title: 'Курица гриль',
                      count: 3,
                      countBg: AppColors.primary.withValues(alpha: 0.1),
                      countFg: AppColors.primary,
                      imageUrl: _proteinChicken,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _ModuleCard(
                      title: 'Лосось',
                      count: 2,
                      countBg: AppColors.tertiaryContainer,
                      countFg: AppColors.tertiary,
                      imageUrl: _proteinSalmon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _ModuleRow(
                title: 'Стейк',
                subtitle: 'Прожарка Medium',
                badge: '2 порции',
                badgeBg: AppColors.secondaryContainer,
                badgeFg: AppColors.onSecondaryContainer,
                imageUrl: _proteinSteak,
              ),
              const SizedBox(height: 32),
              const _SectionHeader(title: 'Гарниры', meta: 'Долгого хранения'),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: _SideCard(
                      title: 'Рис',
                      subtitle: 'Жасмин',
                      count: '4',
                      countBg: AppColors.primary,
                      countFg: AppColors.onPrimary,
                      highlighted: true,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _SideCard(
                      title: 'Булгур',
                      subtitle: 'С овощами',
                      count: '3',
                      countBg: AppColors.secondary,
                      countFg: AppColors.onSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const _SectionHeader(title: 'Овощи', trailingIcon: Icons.eco),
              const SizedBox(height: 12),
              const _VegRow(name: 'Брокколи', count: '3'),
              const SizedBox(height: 8),
              const _VegRow(name: 'Салат', count: '2', highlight: true),
              const SizedBox(height: 8),
              const _VegRow(name: 'Овощи гриль', count: '2'),
              const SizedBox(height: 32),
              const _SectionHeader(title: 'Соусы'),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _SauceChip(label: 'Йогуртовый', count: 5, selected: true),
                  _SauceChip(label: 'Томатный'),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _AssemblyBar(
              summary: 'Курица + рис + йогуртовый соус',
              onAssemble: () => context.push(Routes.guestAssembleDish),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionBanner extends StatelessWidget {
  const _SuggestionBanner({required this.primary, required this.secondary});
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.onPrimaryContainer,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '$primary\n',
                    style: TextStyle(
                      color: AppColors.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  TextSpan(text: secondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.meta, this.trailingIcon});
  final String title;
  final String? meta;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: tt.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (meta != null)
          Text(
            meta!.toUpperCase(),
            style: tt.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
        if (trailingIcon != null)
          Icon(trailingIcon, color: AppColors.primary, size: 20),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.count,
    required this.countBg,
    required this.countFg,
    required this.imageUrl,
  });
  final String title;
  final int count;
  final Color countBg;
  final Color countFg;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint, blurRadius: 32, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.surfaceContainer),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surfaceContainer),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: tt.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: countBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: tt.labelSmall?.copyWith(
                    color: countFg,
                    fontWeight: FontWeight.w700,
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

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.imageUrl,
  });
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint, blurRadius: 32, offset: Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.surfaceContainer),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surfaceContainer),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: tt.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: tt.labelSmall?.copyWith(
                color: badgeFg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.countBg,
    required this.countFg,
    this.highlighted = false,
  });
  final String title;
  final String subtitle;
  final String count;
  final Color countBg;
  final Color countFg;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint, blurRadius: 32, offset: Offset(0, 12)),
        ],
        border: highlighted
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: tt.bodyLarge?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subtitle,
                style: tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: countBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  count,
                  style: tt.labelSmall?.copyWith(
                    color: countFg,
                    fontWeight: FontWeight.w700,
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

class _VegRow extends StatelessWidget {
  const _VegRow({required this.name, required this.count, this.highlight = false});
  final String name;
  final String count;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: tt.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            count,
            style: tt.bodyMedium?.copyWith(
              color: highlight
                  ? const Color(0xFFA83836)
                  : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SauceChip extends StatelessWidget {
  const _SauceChip({required this.label, this.count, this.selected = false});
  final String label;
  final int? count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bg = selected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest;
    final fg = selected ? AppColors.onPrimaryContainer : AppColors.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint, blurRadius: 32, offset: Offset(0, 12)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: tt.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: tt.labelSmall?.copyWith(color: fg.withValues(alpha: 0.6)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssemblyBar extends StatelessWidget {
  const _AssemblyBar({required this.summary, required this.onAssemble});
  final String summary;
  final VoidCallback onAssemble;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowTint, blurRadius: 32, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ВАША СБОРКА',
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: tt.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.close, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onAssemble,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
              textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Собрать'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
