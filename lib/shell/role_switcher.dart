import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'role.dart';
import 'role_provider.dart';

/// Кнопка в AppBar для переключения между Шефом и Гостем.
/// Текст подсказки и SnackBar после тапа объясняют, в какую роль перешли.
class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>().role;
    final isChef = role == UserRole.chef;
    final tooltip = isChef ? 'Стать Гостем' : 'Стать Шефом';

    return IconButton(
      icon: const Icon(Icons.swap_horiz),
      tooltip: tooltip,
      onPressed: () {
        context.read<RoleProvider>().toggle();
        final next = isChef ? 'Гость' : 'Шеф';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Роль: $next'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
