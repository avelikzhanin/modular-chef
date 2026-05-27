import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 2+: настройки, «Мои блюда»')),
    );
  }
}
