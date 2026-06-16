import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/models/weekly_menu.dart';

void main() {
  group('WeeklyMenu', () {
    test('round-trip fromJson → toJson preserves component structure', () {
      final json = <String, dynamic>{
        'weeks': [
          {
            'index': 0,
            'name': 'Неделя 1',
            'days': [
              for (int i = 0; i < 7; i++)
                {
                  'weekday': 'monday',
                  'shortName': 'Пн',
                  'breakfast': {
                    'title': 'Овсянка',
                    'kind': 'breakfast',
                    'components': [
                      {'moduleId': 'oatmeal_jar', 'role': 'standalone', 'name': 'Овсянка', 'emoji': '🥣'}
                    ],
                    'reheatMinutes': 0,
                    'fromContainer': 'холодильник',
                  },
                  'lunch': {
                    'title': 'Курица + рис + брокколи + йогурт',
                    'kind': 'main',
                    'components': [
                      {'moduleId': 'chicken_breast', 'role': 'protein', 'name': 'Курица'},
                      {'moduleId': 'rice', 'role': 'side', 'name': 'Рис'},
                      {'moduleId': 'broccoli', 'role': 'vegetable', 'name': 'Брокколи'},
                      {'moduleId': 'yogurt_sauce', 'role': 'sauce', 'name': 'Йогуртовый соус'},
                    ],
                    'reheatMinutes': 2,
                  },
                  'dinner': {
                    'title': 'Лосось + булгур',
                    'kind': 'main',
                    'components': [
                      {'moduleId': 'salmon', 'role': 'protein', 'name': 'Лосось'},
                      {'moduleId': 'bulgur', 'role': 'side', 'name': 'Булгур'},
                    ],
                    'reheatMinutes': 3,
                  },
                },
            ],
          },
        ],
        'summary': {
          'uniqueDishes': 3,
          'totalMeals': 21,
          'modulesUsed': 5,
          'flavourProfiles': ['mediterranean'],
        },
      };

      final menu = WeeklyMenu.fromJson(json);

      expect(menu.weeks, hasLength(1));
      expect(menu.weeks.first.days, hasLength(7));
      final lunch = menu.weeks.first.days.first.lunch;
      expect(lunch.kind, MealKind.main);
      expect(lunch.components, hasLength(4));
      expect(lunch.componentOf(MealRole.protein)!.name, 'Курица');
      expect(lunch.componentOf(MealRole.sauce)!.moduleId, 'yogurt_sauce');
      expect(lunch.moduleIds, ['chicken_breast', 'rice', 'broccoli', 'yogurt_sauce']);
      expect(menu.summary.uniqueDishes, 3);

      final round = menu.toJson();
      expect((round['weeks'] as List).length, 1);
      expect((round['summary'] as Map)['totalMeals'], 21);
      final roundLunch =
          (((round['weeks'] as List)[0]['days'] as List)[0]['lunch']) as Map;
      expect((roundLunch['components'] as List).length, 4);
      expect(roundLunch['kind'], 'main');
    });

    test('DayPlan.mealAt returns the right slot; snack nullable', () {
      const b = PlannedMeal(title: 'B', kind: MealKind.breakfast);
      const l = PlannedMeal(title: 'L');
      const d = PlannedMeal(title: 'D');
      const day = DayPlan(
        weekday: 'monday',
        shortName: 'Пн',
        breakfast: b,
        lunch: l,
        dinner: d,
      );

      expect(day.mealAt(MealSlot.breakfast)!.title, 'B');
      expect(day.mealAt(MealSlot.lunch)!.title, 'L');
      expect(day.mealAt(MealSlot.dinner)!.title, 'D');
      expect(day.mealAt(MealSlot.snack), isNull);
    });

    test('PlannedMeal.fromJson legacy moduleIds → standalone components', () {
      final m = PlannedMeal.fromJson(<String, dynamic>{
        'title': 'X',
        'moduleIds': ['a', 'b'],
      });
      expect(m.reheatMinutes, 0);
      expect(m.fromContainer, '');
      expect(m.components, hasLength(2));
      expect(m.components.first.role, MealRole.standalone);
      expect(m.moduleIds, ['a', 'b']);
    });

    test('PlannedMeal.toJson omits empty fromContainer', () {
      const m = PlannedMeal(title: 'X');
      expect(m.toJson().containsKey('fromContainer'), isFalse);
    });

    test('copyWith changes title, keeps components', () {
      const m = PlannedMeal(
        title: 'Курица + рис',
        components: [
          MealComponent(moduleId: 'chicken_breast', role: MealRole.protein, name: 'Курица'),
        ],
      );
      final c = m.copyWith(title: 'Курица + гречка');
      expect(c.title, 'Курица + гречка');
      expect(c.components, hasLength(1));
      expect(c.components.first.moduleId, 'chicken_breast');
    });
  });
}
