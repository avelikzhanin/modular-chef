import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запасы'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1b: порт guest/v4_3')),
    );
  }
}
