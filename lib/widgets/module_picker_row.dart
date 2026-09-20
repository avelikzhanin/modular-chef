import 'package:flutter/material.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/theme/app_colors.dart';
import 'package:modular_chef/theme/module_visuals.dart';

/// Горизонтальная лента карточек выбора модулей — по макету Stitch:
/// облачная карточка, акварельная картинка, название по центру;
/// выбранная — зелёная рамка + галочка. [selectedIds] — множество (0/1 для
/// одиночного выбора).
class ModulePickerRow extends StatelessWidget {
  const ModulePickerRow({
    super.key,
    required this.label,
    required this.optional,
    required this.modules,
    required this.selectedIds,
    required this.onTap,
    this.captionOf,
    this.enabledOf,
  });

  final String label;
  final bool optional;
  final List<Module> modules;
  final Set<String> selectedIds;
  final ValueChanged<Module> onTap;

  /// Подпись под карточкой (например, «2 порц.»). null — без подписи.
  final String? Function(Module)? captionOf;

  /// false — карточка «кончилось»: гаснет и не выбирается.
  final bool Function(Module)? enabledOf;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              label,
              style: tt.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('по желанию',
                    style: tt.labelSmall
                        ?.copyWith(color: AppColors.onSurfaceVariant)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: modules.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Пусто',
                      style: tt.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant)),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: modules.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ModuleTile(
                    module: modules[i],
                    selected: selectedIds.contains(modules[i].id),
                    onTap: () => onTap(modules[i]),
                    caption: captionOf?.call(modules[i]),
                    enabled: enabledOf?.call(modules[i]) ?? true,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Одна карточка модуля (переиспользуется на экранах выбора).
class ModuleTile extends StatelessWidget {
  const ModuleTile({
    super.key,
    required this.module,
    required this.selected,
    required this.onTap,
    this.width = 110,
    this.caption,
    this.enabled = true,
  });

  final Module module;
  final bool selected;
  final VoidCallback onTap;
  final double width;

  /// Подпись под названием (например, «2 порц.» из запасов).
  final String? caption;

  /// false — «кончилось»: карточка полупрозрачная, тап показывает снекбар.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final img = moduleImage(module.id);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
      onTap: enabled
          ? onTap
          : () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text('${module.name} — порции закончились'),
              behavior: SnackBarBehavior.floating,
            )),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          // Мягкая акварельная кайма выбора (сейдж) вместо жёсткой зелёной.
          border: Border.all(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.55)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowTint,
                blurRadius: 24,
                offset: Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  // Белая «паспарту»-рамка: у акварелей разные запечённые фоны,
                  // единая подложка собирает их в один альбомный стиль.
                  // Выбрано → вся картинка затемняется + крупная галочка.
                  child: Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (img != null)
                          Image.asset(img, fit: BoxFit.cover)
                        else
                          Center(
                              child: Icon(moduleIcon(module.category),
                                  size: 34,
                                  color: AppColors.primaryContainer)),
                        if (selected) ...[
                          Container(
                            color: AppColors.onPrimaryContainer
                                .withValues(alpha: 0.38),
                          ),
                          Center(
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest
                                    .withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(7),
                              child: Image.asset(
                                  'assets/art/ui/check_leaf.png',
                                  fit: BoxFit.contain),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  module.name,
                  maxLines: caption != null ? 1 : 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.leafDeep,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Карточка одной подсказки (✓ / 💡).
class MealHintTile extends StatelessWidget {
  const MealHintTile({super.key, required this.text, required this.positive});
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(positive ? Icons.check_rounded : Icons.tips_and_updates_outlined,
              size: 16,
              color: positive ? AppColors.leafDeep : AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: tt.bodySmall?.copyWith(
                  color: positive
                      ? AppColors.leafDeep
                      : AppColors.onSurfaceVariant,
                  fontWeight: positive ? FontWeight.w600 : FontWeight.w400,
                )),
          ),
        ],
      ),
    );
  }
}
