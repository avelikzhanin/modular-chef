import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/routing/app_router.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/shell/role.dart';
import 'package:modular_chef/shell/role_provider.dart';
import 'package:modular_chef/theme/app_theme.dart';
import 'package:modular_chef/theme/app_typography.dart';

Future<void> _pumpApp(WidgetTester tester, RoleProvider provider) async {
  final router = buildRouter(provider);
  // Намеренно не вызываем catalog.load() — это держит pumpAndSettle pending.
  // MenuScreen в loading-режиме показывает CircularProgressIndicator, чья
  // бесконечная анимация всегда таймаутит pumpAndSettle. Текст «Меню» нужен
  // только в bottom nav (от каталога не зависит) — обычный pump его покажет.
  final catalog = CatalogService();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RoleProvider>.value(value: provider),
        ChangeNotifierProvider<CatalogService>.value(value: catalog),
      ],
      child: MaterialApp.router(
        // Инжектим текст-тему без google_fonts, чтобы не дёргать сеть.
        theme: AppTheme.light(
          textTheme: AppTypography.applyClinicalRules(AppTypography.baseScale),
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppRouter', () {
    testWidgets('default role chef opens Меню tab', (tester) async {
      await _pumpApp(tester, RoleProvider());
      expect(find.text('Меню'), findsWidgets);
      expect(find.text('Сегодня'), findsNothing);
    });

    testWidgets('starting as guest opens Сегодня tab', (tester) async {
      final provider = RoleProvider()..setRole(UserRole.guest);
      await _pumpApp(tester, provider);
      expect(find.text('Сегодня'), findsWidgets);
      expect(find.text('Меню'), findsNothing);
    });

    testWidgets('toggling role redirects to other branch root', (tester) async {
      final provider = RoleProvider();
      await _pumpApp(tester, provider);
      expect(find.text('Меню'), findsWidgets);

      provider.toggle();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Сегодня'), findsWidgets);
      expect(find.text('Меню'), findsNothing);
    });

    test('routes constants point to existing destinations', () {
      expect(Routes.chefMenu, isNotEmpty);
      expect(Routes.guestToday, isNotEmpty);
      expect(Routes.chefRoot, Routes.chefMenu);
      expect(Routes.guestRoot, Routes.guestToday);
    });
  });
}
