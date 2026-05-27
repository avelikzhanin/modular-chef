import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/models/weekly_menu.dart';

void main() {
  group('WeeklyMenu', () {
    test('round-trip fromJson → toJson preserves structure', () {
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
                    'moduleIds': ['oatmeal_jar'],
                    'reheatMinutes': 0,
                    'fromContainer': 'холодильник',
                  },
                  'lunch': {
                    'title': 'Курица + рис',
                    'moduleIds': ['chicken_breast', 'rice'],
                    'reheatMinutes': 2,
                  },
                  'dinner': {
                    'title': 'Лосось + булгур',
                    'moduleIds': ['salmon', 'bulgur'],
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
      expect(menu.weeks.first.days.first.breakfast.title, 'Овсянка');
      expect(menu.weeks.first.days.first.lunch.moduleIds, ['chicken_breast', 'rice']);
      expect(menu.summary.uniqueDishes, 3);
      expect(menu.summary.flavourProfiles, ['mediterranean']);

      final round = menu.toJson();
      expect((round['weeks'] as List).length, 1);
      expect((round['summary'] as Map)['totalMeals'], 21);
    });

    test('DayPlan.mealAt returns the right slot', () {
      const breakfast = PlannedMeal(title: 'B', moduleIds: [], reheatMinutes: 0);
      const lunch = PlannedMeal(title: 'L', moduleIds: [], reheatMinutes: 2);
      const dinner = PlannedMeal(title: 'D', moduleIds: [], reheatMinutes: 5);
      const day = DayPlan(
        weekday: 'monday',
        shortName: 'Пн',
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
      );

      expect(day.mealAt(MealSlot.breakfast).title, 'B');
      expect(day.mealAt(MealSlot.lunch).title, 'L');
      expect(day.mealAt(MealSlot.dinner).title, 'D');
    });

    test('PlannedMeal.fromJson handles missing optional fields', () {
      final m = PlannedMeal.fromJson(<String, dynamic>{
        'title': 'X',
        'moduleIds': ['a'],
      });
      expect(m.reheatMinutes, 0);
      expect(m.fromContainer, '');
    });

    test('PlannedMeal.toJson omits empty fromContainer', () {
      const m = PlannedMeal(title: 'X', moduleIds: ['a'], reheatMinutes: 0);
      expect(m.toJson().containsKey('fromContainer'), isFalse);
    });
  });
}
