import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/menu_generator.dart';
import 'package:modular_chef/services/prompt_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CatalogService catalog;
  setUpAll(() async {
    catalog = CatalogService();
    await catalog.load();
  });

  group('StubMenuGenerator', () {
    Future<WeeklyMenu> generate({
      List<String> proteins = const ['chicken_breast', 'salmon'],
      List<String> sides = const ['rice', 'bulgur'],
      List<String> breakfasts = const ['oatmeal_jar', 'syrniki'],
    }) {
      const gen = StubMenuGenerator();
      return gen.generate(
        GenerationRequest(
          proteinIds: proteins,
          sideIds: sides,
          soupIds: const [],
          breakfastIds: breakfasts,
        ),
        modules: catalog.allModules,
        pairings: catalog.allPairings,
      );
    }

    test('produces 2 weeks × 7 days × 3 meals = 42 slots', () async {
      final menu = await generate();

      expect(menu.weeks, hasLength(2));
      for (final w in menu.weeks) {
        expect(w.days, hasLength(7));
      }
      expect(menu.summary.totalMeals, 42);
    });

    test('protein/side components come only from picks; veg/sauce auto', () async {
      final menu = await generate(
        proteins: ['chicken_breast'],
        sides: ['rice'],
        breakfasts: ['oatmeal_jar'],
      );

      final mains = menu.weeks
          .expand((w) => w.days)
          .expand((d) => [d.lunch, d.dinner])
          .where((m) => m.kind == MealKind.main);

      for (final meal in mains) {
        final protein = meal.componentOf(MealRole.protein);
        final side = meal.componentOf(MealRole.side);
        // белок и гарнир — строго из пиков
        if (protein != null) {
          expect(protein.moduleId, 'chicken_breast');
        }
        if (side != null) {
          expect(side.moduleId, 'rice');
        }
        // полная тарелка должна иметь овощ и соус (автоподбор)
        expect(meal.componentOf(MealRole.vegetable), isNotNull);
        expect(meal.componentOf(MealRole.sauce), isNotNull);
      }
    });

    test('no protein repeats in the same lunch slot on consecutive days',
        () async {
      final menu = await generate();

      for (final week in menu.weeks) {
        for (int d = 0; d + 1 < week.days.length; d++) {
          final today = week.days[d].lunch.moduleIds;
          final tomorrow = week.days[d + 1].lunch.moduleIds;
          if (today.isNotEmpty && tomorrow.isNotEmpty) {
            // первый id в lunch — белок
            expect(today.first, isNot(tomorrow.first),
                reason: 'lunch protein repeats day $d → ${d + 1}');
          }
        }
      }
    });

    test('summary counts match actual content', () async {
      final menu = await generate();
      final actualTotal = menu.weeks
          .expand((w) => w.days)
          .expand((d) => [d.breakfast, d.lunch, d.dinner])
          .length;
      final actualUnique = menu.weeks
          .expand((w) => w.days)
          .expand((d) => [d.breakfast, d.lunch, d.dinner])
          .map((m) => m.title)
          .toSet()
          .length;
      final actualModules = menu.weeks
          .expand((w) => w.days)
          .expand((d) => [d.breakfast, d.lunch, d.dinner])
          .expand((m) => m.moduleIds)
          .toSet()
          .length;

      expect(menu.summary.totalMeals, actualTotal);
      expect(menu.summary.uniqueDishes, actualUnique);
      expect(menu.summary.modulesUsed, actualModules);
    });

    test('empty proteins yields fallback meals, not crash', () async {
      final menu = await generate(proteins: const []);
      expect(menu.weeks, hasLength(2));
      // главное — не падает, generate возвращает что-то структурно валидное
      expect(menu.weeks.first.days.first.lunch.title, isNotEmpty);
    });
  });
}
