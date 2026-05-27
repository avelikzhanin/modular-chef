import 'package:flutter/material.dart';

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

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: 'Меню',
    ),
    NavigationDestination(
      icon: Icon(Icons.shopping_cart_outlined),
      selectedIcon: Icon(Icons.shopping_cart),
      label: 'Покупки',
    ),
    NavigationDestination(
      icon: Icon(Icons.soup_kitchen_outlined),
      selectedIcon: Icon(Icons.soup_kitchen),
      label: 'Подготовка',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Хранение',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Профиль',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
