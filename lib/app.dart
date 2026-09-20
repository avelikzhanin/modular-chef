import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'routing/app_router.dart';
import 'services/active_menu.dart';
import 'services/app_settings.dart';
import 'services/breakfast_preps.dart';
import 'services/catalog_service.dart';
import 'services/favourite_combos.dart';
import 'services/http_menu_generator.dart';
import 'services/local_store.dart';
import 'services/menu_generator.dart';
import 'services/menu_repository.dart';
import 'services/my_dishes.dart';
import 'services/pantry_stock.dart';
import 'services/preferences.dart';
import 'services/shopping_list.dart';
import 'services/storage_choices.dart';
import 'services/synced_store.dart';
import 'services/today_plan.dart';
import 'shell/role_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/paper_grain.dart';

class ModularChefApp extends StatefulWidget {
  const ModularChefApp({super.key});

  @override
  State<ModularChefApp> createState() => _ModularChefAppState();
}

class _ModularChefAppState extends State<ModularChefApp> {
  /// С бэкендом — стор с синком между телефонами, без него — просто локальный.
  late final LocalStore _store = ApiConfig.isBackendConfigured
      ? SyncedStore(baseUrl: ApiConfig.baseUrl)
      : LocalStore();
  late final RoleProvider _role = RoleProvider(store: _store);
  late final CatalogService _catalog = CatalogService()..load();
  late final ActiveMenu _activeMenu = ActiveMenu(store: _store);
  late final TodayPlan _todayPlan = TodayPlan(store: _store);
  late final Preferences _preferences = Preferences();
  late final FavouriteCombos _favourites = FavouriteCombos(store: _store);
  late final BreakfastPreps _breakfastPreps = BreakfastPreps(store: _store);
  late final StorageChoices _storageChoices = StorageChoices(store: _store);
  late final PantryStock _pantryStock = PantryStock(store: _store);
  late final ShoppingList _shoppingList = ShoppingList(store: _store);
  late final AppSettings _settings = AppSettings(store: _store);
  late final MyDishes _myDishes = MyDishes(store: _store);

  /// Выбор генератора решается на старте по `--dart-define=API_BASE_URL`.
  /// Без флага — оффлайн stub; с флагом — сетевой через FastAPI на Railway.
  late final MenuGenerator _generator = ApiConfig.isBackendConfigured
      ? FallbackMenuGenerator(
          primary: HttpMenuGenerator(baseUrl: ApiConfig.baseUrl))
      : const StubMenuGenerator();

  late final MenuRepository _menuRepo = ApiConfig.isBackendConfigured
      ? HttpMenuRepository(baseUrl: ApiConfig.baseUrl)
      : const NoopMenuRepository();

  late final _router = buildRouter(_role);

  /// Ключи, которые синкаются между телефонами через /state/{key}.
  static const _syncKeys = [
    'active_menu',
    'today_plan',
    'storage_choices',
    'breakfast_preps',
    'favourite_combos',
    'pantry_stock',
    'shopping_list',
    'app_settings',
    'my_dishes',
  ];

  Timer? _syncTimer;

  Future<void> _reloadAll() => Future.wait([
        _role.loadFromStore(),
        _activeMenu.loadFromStore(),
        _todayPlan.loadFromStore(),
        _favourites.loadFromStore(),
        _breakfastPreps.loadFromStore(),
        _storageChoices.loadFromStore(),
        _pantryStock.loadFromStore(),
        _shoppingList.loadFromStore(),
        _settings.loadFromStore(),
        _myDishes.loadFromStore(),
      ]);

  /// Стянуть свежее состояние с сервера и перечитать сервисы.
  Future<void> _pullAndReload() async {
    final store = _store;
    if (store is! SyncedStore) return;
    if (await store.pullAll(_syncKeys) && mounted) await _reloadAll();
  }

  Future<void> _bootstrap() async {
    // Сначала пробуем стянуть общее состояние (второй телефон мог обновить),
    // затем читаем локальный кэш — работает и полностью офлайн.
    final store = _store;
    if (store is SyncedStore) await store.pullAll(_syncKeys);
    if (!mounted) return;
    await _reloadAll();
    // Легаси-путь: активное меню, сохранённое до появления /state.
    if (!_activeMenu.hasMenu) {
      final menu = await _menuRepo.fetchActive();
      if (menu != null && mounted && !_activeMenu.hasMenu) {
        _activeMenu.set(menu);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
    if (_store is SyncedStore) {
      // Смена роли = «передал телефон/эстафету» — момент подтянуть чужие правки.
      _role.addListener(_pullAndReload);
      _syncTimer = Timer.periodic(
          const Duration(minutes: 2), (_) => _pullAndReload());
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    final store = _store;
    if (store is SyncedStore) {
      _role.removeListener(_pullAndReload);
      store.dispose();
    }
    _role.dispose();
    _catalog.dispose();
    _activeMenu.dispose();
    _todayPlan.dispose();
    _preferences.dispose();
    _favourites.dispose();
    _breakfastPreps.dispose();
    _storageChoices.dispose();
    _pantryStock.dispose();
    _shoppingList.dispose();
    _settings.dispose();
    _myDishes.dispose();
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
        ChangeNotifierProvider<FavouriteCombos>.value(value: _favourites),
        ChangeNotifierProvider<BreakfastPreps>.value(value: _breakfastPreps),
        ChangeNotifierProvider<StorageChoices>.value(value: _storageChoices),
        ChangeNotifierProvider<PantryStock>.value(value: _pantryStock),
        ChangeNotifierProvider<ShoppingList>.value(value: _shoppingList),
        ChangeNotifierProvider<AppSettings>.value(value: _settings),
        ChangeNotifierProvider<MyDishes>.value(value: _myDishes),
        Provider<MenuGenerator>.value(value: _generator),
        Provider<MenuRepository>.value(value: _menuRepo),
        Provider<LocalStore>.value(value: _store),
      ],
      child: MaterialApp.router(
        title: 'Modular Chef',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
        builder: (context, child) => Stack(
          children: [
            if (child != null) child,
            const Positioned.fill(child: PaperGrain()),
          ],
        ),
      ),
    );
  }
}
