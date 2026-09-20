import 'package:flutter/material.dart';
import 'package:modular_chef/shell/linen_nav_bar.dart';

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

  // Гость живёт «сегодня» — горизонт недели убран (v2). Два таба.
  static const _items = <LinenNavItem>[
    LinenNavItem(asset: 'assets/art/ui/nav_today.png', label: 'Сегодня'),
    LinenNavItem(asset: 'assets/art/ui/nav_stock.png', label: 'Запасы'),
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
