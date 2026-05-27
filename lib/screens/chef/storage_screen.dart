import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Хранение'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1c: «Карта хранения» с конкретными позициями')),
    );
  }
}
