import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routing/app_router.dart';
import 'services/active_menu.dart';
import 'services/catalog_service.dart';
import 'services/menu_generator.dart';
import 'shell/role_provider.dart';
import 'theme/app_theme.dart';

class ModularChefApp extends StatefulWidget {
  const ModularChefApp({super.key});

  @override
  State<ModularChefApp> createState() => _ModularChefAppState();
}

class _ModularChefAppState extends State<ModularChefApp> {
  late final RoleProvider _role = RoleProvider();
  late final CatalogService _catalog = CatalogService()..load();
  late final ActiveMenu _activeMenu = ActiveMenu();
  static const MenuGenerator _generator = StubMenuGenerator();
  late final _router = buildRouter(_role);

  @override
  void dispose() {
    _role.dispose();
    _catalog.dispose();
    _activeMenu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RoleProvider>.value(value: _role),
        ChangeNotifierProvider<CatalogService>.value(value: _catalog),
        ChangeNotifierProvider<ActiveMenu>.value(value: _activeMenu),
        Provider<MenuGenerator>.value(value: _generator),
      ],
      child: MaterialApp.router(
        title: 'Modular Chef',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
