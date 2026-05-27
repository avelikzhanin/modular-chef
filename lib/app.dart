import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routing/app_router.dart';
import 'shell/role_provider.dart';
import 'theme/app_theme.dart';

class ModularChefApp extends StatefulWidget {
  const ModularChefApp({super.key});

  @override
  State<ModularChefApp> createState() => _ModularChefAppState();
}

class _ModularChefAppState extends State<ModularChefApp> {
  late final RoleProvider _role = RoleProvider();
  late final _router = buildRouter(_role);

  @override
  void dispose() {
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RoleProvider>.value(
      value: _role,
      child: MaterialApp.router(
        title: 'Modular Chef',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
