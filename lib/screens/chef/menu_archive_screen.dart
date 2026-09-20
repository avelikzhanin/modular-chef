import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/active_menu.dart';
import 'package:modular_chef/services/local_store.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Архив утверждённых меню: дата, состав — только посмотреть.
class MenuArchiveScreen extends StatelessWidget {
  const MenuArchiveScreen({super.key});

  static String _fmt(DateTime d) => '${d.day}.${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final store = context.read<LocalStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Прошлые меню'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: store.readJson(ActiveMenu.historyKey),
        builder: (context, snap) {
          final items = ((snap.data?['items'] as List?) ?? const [])
              .cast<Map<String, dynamic>>();
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Пока пусто: каждое утверждённое меню будет сохраняться здесь.',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final approvedAt =
                  DateTime.tryParse(items[i]['approvedAt'] as String? ?? '');
              WeeklyMenu? menu;
              try {
                menu = WeeklyMenu.fromJson(
                    items[i]['menu'] as Map<String, dynamic>);
              } catch (_) {}
              final weeks = menu?.weeks.length ?? 0;
              final until = approvedAt?.add(Duration(days: weeks * 7 - 1));
              return InkWell(
                onTap: menu == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => _ArchivedMenuView(
                                  menu: menu!, approvedAt: approvedAt)),
                        ),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.shadowTint,
                          blurRadius: 24,
                          offset: Offset(0, 8)),
                    ],
                  ),
                  child: Row(children: [
                    const Text('📅', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            approvedAt == null
                                ? 'Меню'
                                : 'Меню ${_fmt(approvedAt)} – ${until != null ? _fmt(until) : ''}',
                            style: tt.titleMedium?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            menu == null
                                ? ''
                                : '$weeks нед. · ${menu.summary.uniqueDishes} блюд',
                            style: tt.labelSmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 22, color: AppColors.onSurfaceVariant),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Просмотр архивного меню — только чтение.
class _ArchivedMenuView extends StatelessWidget {
  const _ArchivedMenuView({required this.menu, this.approvedAt});
  final WeeklyMenu menu;
  final DateTime? approvedAt;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(approvedAt == null
            ? 'Меню'
            : 'Меню от ${MenuArchiveScreen._fmt(approvedAt!)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final week in menu.weeks) ...[
            Text(week.name,
                style: tt.titleLarge?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final day in week.days) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.shortName.toUpperCase(),
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.leafDeep,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 4),
                    for (final (label, meal) in <(String, PlannedMeal?)>[
                      ('Завтрак', day.breakfast),
                      ('Обед', day.lunch),
                      ('Ужин', day.dinner),
                    ])
                      if (meal != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('$label: ${meal.title}',
                              style: tt.bodySmall?.copyWith(
                                  color: AppColors.onSurface, height: 1.3)),
                        ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
