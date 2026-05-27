import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сегодня'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1b: порт guest/v4_4')),
    );
  }
}
