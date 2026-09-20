import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/services/app_settings.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Настройки приложения. Главное — сколько порций даёт одна готовка:
/// на это число опираются «Запасы» после «Завершить готовку».
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final settings = context.watch<AppSettings>();
    final portions = settings.portionsPerBatch;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
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
                Text('Порций с одной готовки',
                    style: tt.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  'Сколько порций каждой заготовки получается за один раз. Например, 600 г курицы — это $portions ${_portionsWord(portions)}: на столько и пополнятся «Запасы».',
                  style: tt.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StepBtn(
                      icon: Icons.remove,
                      onTap: portions > 1
                          ? () => settings.setPortionsPerBatch(portions - 1)
                          : null,
                    ),
                    Expanded(
                      child: Center(
                        child: Text('$portions',
                            style: tt.headlineMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    _StepBtn(
                      icon: Icons.add,
                      onTap: portions < 12
                          ? () => settings.setPortionsPerBatch(portions + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
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
                Text('Человек в семье',
                    style: tt.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  'Столько порций каждого компонента уходит из «Запасов» за один приём. Обед на ${settings.householdSize} — минус ${settings.householdSize} порции курицы и риса.',
                  style: tt.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StepBtn(
                      icon: Icons.remove,
                      onTap: settings.householdSize > 1
                          ? () => settings
                              .setHouseholdSize(settings.householdSize - 1)
                          : null,
                    ),
                    Expanded(
                      child: Center(
                        child: Text('${settings.householdSize}',
                            style: tt.headlineMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    _StepBtn(
                      icon: Icons.add,
                      onTap: settings.householdSize < 8
                          ? () => settings
                              .setHouseholdSize(settings.householdSize + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
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
                Text('Завтракают человек',
                    style: tt.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  'Кто-то утром не ест — яйца и завтраки в покупках и запасах считаются по этому числу.',
                  style: tt.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StepBtn(
                      icon: Icons.remove,
                      onTap: settings.breakfastEaters > 0
                          ? () => settings
                              .setBreakfastEaters(settings.breakfastEaters - 1)
                          : null,
                    ),
                    Expanded(
                      child: Center(
                        child: Text('${settings.breakfastEaters}',
                            style: tt.headlineMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    _StepBtn(
                      icon: Icons.add,
                      onTap: settings.breakfastEaters < 8
                          ? () => settings
                              .setBreakfastEaters(settings.breakfastEaters + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightLeaf.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Остальные настройки (уведомления, дни готовки) появятся в следующих версиях.',
              style:
                  tt.bodySmall?.copyWith(color: AppColors.leafDeep, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  static String _portionsWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'порция';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'порции';
    }
    return 'порций';
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.lightLeaf,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.leafDeep, size: 26),
        ),
      ),
    );
  }
}
