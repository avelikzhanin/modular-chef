import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/screens/chef/breakfast_preps_screen.dart';
import 'package:modular_chef/services/breakfast_preps.dart';
import 'package:modular_chef/services/catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CatalogService catalog;
  setUpAll(() async {
    catalog = CatalogService();
    await catalog.load();
  });

  Future<void> pump(WidgetTester tester, {required bool showEggs}) {
    // Высокое окно нарочно: ListView строит только видимые элементы, и на
    // обычном экране проверка «яиц нет» проходила бы просто потому, что они
    // не влезли — а не потому, что их убрали.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CatalogService>.value(value: catalog),
          ChangeNotifierProvider(create: (_) => BreakfastPreps()),
        ],
        child: MaterialApp(home: BreakfastPrepsScreen(showEggs: showEggs)),
      ),
    );
  }

  testWidgets('в настройке баночки яиц нет', (tester) async {
    await pump(tester, showEggs: false);
    await tester.pump();

    expect(find.text('Баночки'), findsOneWidget);
    expect(find.text('Собрать банку'), findsOneWidget);
    // Главное: секция яиц не должна протекать в баночный тракт.
    expect(find.text('Яйца на завтрак'), findsNothing);
    expect(find.text('Виды яиц'), findsNothing);
    expect(find.text('Добавки к яйцам'), findsNothing);
  });

  testWidgets('вход из Профиля показывает и банки, и яйца', (tester) async {
    await pump(tester, showEggs: true);
    await tester.pump();

    expect(find.text('Заготовки завтраков'), findsOneWidget);
    expect(find.text('Собрать банку'), findsOneWidget);
    expect(find.text('Яйца на завтрак'), findsOneWidget);
    expect(find.text('Добавки к яйцам'), findsOneWidget);
  });

  testWidgets('слова «наготове» в интерфейсе заготовок нет', (tester) async {
    await pump(tester, showEggs: true);
    await tester.pump();

    expect(find.textContaining('наготове'), findsNothing);
  });
}
