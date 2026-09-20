import 'package:flutter/material.dart';
import 'package:modular_chef/shell/linen_nav_bar.dart';

/// Скаффолд для роли Шефа: верхнее «оформление» в AppBar делает экран сам,
/// shell отвечает только за нижнюю навигацию и текущее тело.
class ChefShell extends StatelessWidget {
  const ChefShell({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  static const _items = <LinenNavItem>[
    LinenNavItem(asset: 'assets/art/ui/nav_menu.png', label: 'Меню'),
    LinenNavItem(asset: 'assets/art/ui/nav_shopping.png', label: 'Покупки'),
    LinenNavItem(asset: 'assets/art/ui/nav_prep.png', label: 'Готовка'),
    LinenNavItem(asset: 'assets/art/ui/nav_storage.png', label: 'Запасы'),
    LinenNavItem(asset: 'assets/art/ui/nav_profile.png', label: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: LinenNavBar(
        items: _items,
        currentIndex: currentIndex,
        onSelected: onDestinationSelected,
      ),
    );
  }
}
