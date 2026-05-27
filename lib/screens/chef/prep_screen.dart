import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class PrepScreen extends StatelessWidget {
  const PrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подготовка'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1c: «День заготовки» (шаг 1 + шаг 2)')),
    );
  }
}
