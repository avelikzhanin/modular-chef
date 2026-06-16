import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'routing/app_router.dart';
import 'services/active_menu.dart';
import 'services/catalog_service.dart';
import 'services/http_menu_generator.dart';
import 'services/menu_generator.dart';
import 'services/menu_repository.dart';
import 'services/preferences.dart';
import 'services/today_plan.dart';
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
  late final TodayPlan _todayPlan = TodayPlan();
  late final Preferences _preferences = Preferences();

  /// Выбор генератора решается на старте по `--dart-define=API_BASE_URL`.
  /// Без флага — оффлайн stub; с флагом — сетевой через FastAPI на Railway.
  late final MenuGenerator _generator = ApiConfig.isBackendConfigured
      ? HttpMenuGenerator(baseUrl: ApiConfig.baseUrl)
      : const StubMenuGenerator();

  late final MenuRepository _menuRepo = ApiConfig.isBackendConfigured
      ? HttpMenuRepository(baseUrl: ApiConfig.baseUrl)
      : const NoopMenuRepository();

  late final _router = buildRouter(_role);

  @override
  void initState() {
    super.initState();
    // Восстанавливаем сохранённое меню (best-effort, не блокирует старт).
    _menuRepo.fetchActive().then((menu) {
      if (menu != null && mounted) _activeMenu.set(menu);
    });
  }

  @override
  void dispose() {
    _role.dispose();
    _catalog.dispose();
    _activeMenu.dispose();
    _todayPlan.dispose();
    _preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RoleProvider>.value(value: _role),
        ChangeNotifierProvider<CatalogService>.value(value: _catalog),
        ChangeNotifierProvider<ActiveMenu>.value(value: _activeMenu),
        ChangeNotifierProvider<TodayPlan>.value(value: _todayPlan),
        ChangeNotifierProvider<Preferences>.value(value: _preferences),
        Provider<MenuGenerator>.value(value: _generator),
        Provider<MenuRepository>.value(value: _menuRepo),
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
