import 'package:flutter/material.dart';

/// Мягкое появление со сдвигом вверх (soft fade-up из §5A «Переходы»).
/// Без таймеров (чтобы не ломать widget-тесты): анимация идёт через
/// [TweenAnimationBuilder]; лёгкий стаггер задаётся через длительность —
/// карточки ниже «доезжают» чуть позже.
class FadeInUp extends StatelessWidget {
  const FadeInUp({super.key, required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
