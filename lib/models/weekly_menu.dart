/// Слот приёма пищи в дне.
enum MealSlot {
  breakfast('breakfast', '🌅', 'Завтрак'),
  lunch('lunch', '🌞', 'Обед'),
  dinner('dinner', '🌙', 'Ужин');

  const MealSlot(this.jsonValue, this.emoji, this.label);
  final String jsonValue;
  final String emoji;
  final String label;
}

/// Запланированное блюдо в одном слоте.
class PlannedMeal {
  const PlannedMeal({
    required this.title,
    required this.moduleIds,
    required this.reheatMinutes,
    this.fromContainer = '',
  });

  final String title;
  final List<String> moduleIds;
  final int reheatMinutes;
  final String fromContainer;

  factory PlannedMeal.fromJson(Map<String, dynamic> json) => PlannedMeal(
        title: json['title'] as String,
        moduleIds: ((json['moduleIds'] as List?) ?? const []).cast<String>(),
        reheatMinutes: json['reheatMinutes'] as int? ?? 0,
        fromContainer: (json['fromContainer'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'moduleIds': moduleIds,
        'reheatMinutes': reheatMinutes,
        if (fromContainer.isNotEmpty) 'fromContainer': fromContainer,
      };
}

/// План одного дня: завтрак / обед / ужин.
class DayPlan {
  const DayPlan({
    required this.weekday,
    required this.shortName,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  final String weekday;
  final String shortName;
  final PlannedMeal breakfast;
  final PlannedMeal lunch;
  final PlannedMeal dinner;

  PlannedMeal mealAt(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => breakfast,
        MealSlot.lunch => lunch,
        MealSlot.dinner => dinner,
      };

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        weekday: json['weekday'] as String,
        shortName: json['shortName'] as String,
        breakfast: PlannedMeal.fromJson(json['breakfast'] as Map<String, dynamic>),
        lunch: PlannedMeal.fromJson(json['lunch'] as Map<String, dynamic>),
        dinner: PlannedMeal.fromJson(json['dinner'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'shortName': shortName,
        'breakfast': breakfast.toJson(),
        'lunch': lunch.toJson(),
        'dinner': dinner.toJson(),
      };
}

/// Одна неделя из меню — 7 дней.
class MenuWeek {
  const MenuWeek({required this.index, required this.name, required this.days});

  final int index;
  final String name;
  final List<DayPlan> days;

  factory MenuWeek.fromJson(Map<String, dynamic> json) => MenuWeek(
        index: json['index'] as int,
        name: json['name'] as String,
        days: ((json['days'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(DayPlan.fromJson)
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'name': name,
        'days': days.map((d) => d.toJson()).toList(),
      };
}

/// Сводная статистика по меню — то, что показывается в баннере UI.
class MenuSummary {
  const MenuSummary({
    required this.uniqueDishes,
    required this.totalMeals,
    required this.modulesUsed,
    this.flavourProfiles = const [],
  });

  final int uniqueDishes;
  final int totalMeals;
  final int modulesUsed;
  final List<String> flavourProfiles;

  factory MenuSummary.fromJson(Map<String, dynamic> json) => MenuSummary(
        uniqueDishes: json['uniqueDishes'] as int? ?? 0,
        totalMeals: json['totalMeals'] as int? ?? 0,
        modulesUsed: json['modulesUsed'] as int? ?? 0,
        flavourProfiles:
            ((json['flavourProfiles'] as List?) ?? const []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'uniqueDishes': uniqueDishes,
        'totalMeals': totalMeals,
        'modulesUsed': modulesUsed,
        'flavourProfiles': flavourProfiles,
      };
}

/// Целиком меню на 2 недели — результат генератора.
class WeeklyMenu {
  const WeeklyMenu({required this.weeks, required this.summary});

  final List<MenuWeek> weeks;
  final MenuSummary summary;

  factory WeeklyMenu.fromJson(Map<String, dynamic> json) => WeeklyMenu(
        weeks: ((json['weeks'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(MenuWeek.fromJson)
            .toList(growable: false),
        summary: MenuSummary.fromJson(
            (json['summary'] as Map<String, dynamic>?) ?? const {}),
      );

  Map<String, dynamic> toJson() => {
        'weeks': weeks.map((w) => w.toJson()).toList(),
        'summary': summary.toJson(),
      };
}
