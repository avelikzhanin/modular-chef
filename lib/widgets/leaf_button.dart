import 'package:flutter/material.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Кнопки с акварельной заливкой вместо плоского цвета.
/// [LeafButton] — главная, «молодой лист» (btn_leaf.png).
/// [LeafButton.lake] — вторая в паре, «глубокое озеро» (btn_lake.png).
/// Под картинкой всегда лежит цвет-подстраховка, чтобы кнопка не пропадала,
/// если ассет ещё не сгенерирован.
class LeafButton extends StatelessWidget {
  const LeafButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.height = 52,
    this.radius = 14,
  })  : asset = 'assets/art/btn_leaf.png',
        fallback = AppColors.primaryContainer,
        foreground = AppColors.onPrimaryContainer;

  const LeafButton.lake({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.height = 52,
    this.radius = 14,
  })  : asset = 'assets/art/btn_lake.png',
        fallback = AppColors.lake,
        foreground = AppColors.onLake;

  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final double height;
  final double radius;
  final String asset;
  final Color fallback;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: fallback,
            borderRadius: BorderRadius.circular(radius),
            image: DecorationImage(
              image: AssetImage(asset),
              fit: BoxFit.cover,
              onError: (_, __) {},
            ),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadowTint,
                  blurRadius: 16,
                  offset: Offset(0, 6)),
            ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(radius),
            child: Center(
              child: child ??
                  Text(
                    label ?? '',
                    style: tt.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
