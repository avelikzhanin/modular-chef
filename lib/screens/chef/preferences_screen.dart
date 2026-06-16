import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/services/preferences.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Push-экран Шефа «Предпочтения» (из Профиля). Чего избегать, вкусовой стиль,
/// лимит времени заготовки. Учитывается генератором и подсвечивается на меню.
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final prefs = context.watch<Preferences>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Предпочтения'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Учтём при сборке меню',
            style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Не ем / аллергии'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (key, label) in Preferences.avoidOptions)
                _ChoiceChip(
                  label: label,
                  selected: prefs.avoids(key),
                  onTap: () => context.read<Preferences>().toggleAvoid(key),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Вкусовой стиль недели'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (id, label) in Preferences.styleOptions)
                _ChoiceChip(
                  label: label,
                  selected: prefs.weekStyle == id,
                  onTap: () => context
                      .read<Preferences>()
                      .setWeekStyle(prefs.weekStyle == id ? null : id),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Время воскресной заготовки'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (minutes, label) in Preferences.prepLimitOptions)
                _ChoiceChip(
                  label: label,
                  selected: prefs.prepLimitMinutes == minutes,
                  onTap: () => context.read<Preferences>().setPrepLimit(minutes),
                ),
            ],
          ),
          const SizedBox(height: 32),
          if (prefs.appliedChips.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Учтём: ${prefs.appliedChips.join(', ')}',
                      style: tt.bodyMedium?.copyWith(
                        color: AppColors.onPrimaryContainer,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          border: selected ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: AppColors.onPrimaryContainer),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: tt.labelLarge?.copyWith(
                color: selected ? AppColors.onPrimaryContainer : AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
