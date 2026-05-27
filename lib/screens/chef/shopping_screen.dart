import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Покупки'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1b: порт chef/serene_5')),
    );
  }
}
