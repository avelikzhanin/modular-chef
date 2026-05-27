import 'package:flutter/material.dart';

class GuestShell extends StatelessWidget {
  const GuestShell({
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
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today),
      label: 'Сегодня',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Неделя',
    ),
    NavigationDestination(
      icon: Icon(Icons.kitchen_outlined),
      selectedIcon: Icon(Icons.kitchen),
      label: 'Запасы',
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
