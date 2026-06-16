/// Слот приёма пищи в дне.
enum MealSlot {
  breakfast('breakfast', '🌅', 'Завтрак'),
  lunch('lunch', '🌞', 'Обед'),
  dinner('dinner', '🌙', 'Ужин'),
  snack('snack', '🥨', 'Перекус');

  const MealSlot(this.jsonValue, this.emoji, this.label);
  final String jsonValue;
  final String emoji;
  final String label;
}

/// Тип блюда — определяет структуру тарелки.
enum MealKind {
  main('main'), // белок + гарнир + овощ + соус
  breakfast('breakfast'), // самостоятельное [+ топпинг]
  soup('soup'), // самостоятельное [+ хлеб]
  snack('snack'); // самостоятельное

  const MealKind(this.jsonValue);
  final String jsonValue;

  static MealKind fromJson(String? v) =>
      MealKind.values.firstWhere((k) => k.jsonValue == v,
          orElse: () => MealKind.main);
}

/// Роль компонента в тарелке.
enum MealRole {
  protein('protein', 'Белок'),
  side('side', 'Гарнир'),
  vegetable('vegetable', 'Овощ'),
  sauce('sauce', 'Соус'),
  base('base', 'База'),
  standalone('standalone', 'Блюдо');

  const MealRole(this.jsonValue, this.label);
  final String jsonValue;
  final String label;

  static MealRole fromJson(String? v) =>
      MealRole.values.firstWhere((r) => r.jsonValue == v,
          orElse: () => MealRole.standalone);
}

/// Один компонент тарелки: модуль + его роль.
class MealComponent {
  const MealComponent({
    required this.moduleId,
    required this.role,
    required this.name,
    this.emoji = '',
  });

  final String moduleId;
  final MealRole role;
  final String name;
  final String emoji;

  factory MealComponent.fromJson(Map<String, dynamic> json) => MealComponent(
        moduleId: json['moduleId'] as String? ?? '',
        role: MealRole.fromJson(json['role'] as String?),
        name: json['name'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'moduleId': moduleId,
        'role': role.jsonValue,
        'name': name,
        if (emoji.isNotEmpty) 'emoji': emoji,
      };

  MealComponent copyWith({String? moduleId, MealRole? role, String? name, String? emoji}) =>
      MealComponent(
        moduleId: moduleId ?? this.moduleId,
        role: role ?? this.role,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
      );
}

/// Запланированная тарелка в одном слоте.
class PlannedMeal {
  const PlannedMeal({
    required this.title,
    this.kind = MealKind.main,
    this.components = const [],
    this.reheatMinutes = 0,
    this.fromContainer = '',
  });

  final String title;
  final MealKind kind;
  final List<MealComponent> components;
  final int reheatMinutes;
  final String fromContainer;

  /// Совместимость со старым кодом: плоский список id модулей.
  List<String> get moduleIds =>
      components.map((c) => c.moduleId).where((id) => id.isNotEmpty).toList();

  /// Компонент конкретной роли (первый), если есть.
  MealComponent? componentOf(MealRole role) {
    for (final c in components) {
      if (c.role == role) return c;
    }
    return null;
  }

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    // Новый формат: components[]. Легаси: moduleIds[] → standalone-компоненты.
    final raw = json['components'] as List?;
    final components = raw != null
        ? raw.cast<Map<String, dynamic>>().map(MealComponent.fromJson).toList()
        : ((json['moduleIds'] as List?) ?? const [])
            .cast<String>()
            .map((id) => MealComponent(
                moduleId: id, role: MealRole.standalone, name: id))
            .toList();
    return PlannedMeal(
      title: json['title'] as String,
      kind: MealKind.fromJson(json['kind'] as String?),
      components: components,
      reheatMinutes: json['reheatMinutes'] as int? ?? 0,
      fromContainer: (json['fromContainer'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'kind': kind.jsonValue,
        'components': components.map((c) => c.toJson()).toList(),
        'reheatMinutes': reheatMinutes,
        if (fromContainer.isNotEmpty) 'fromContainer': fromContainer,
      };

  PlannedMeal copyWith({
    String? title,
    MealKind? kind,
    List<MealComponent>? components,
    int? reheatMinutes,
    String? fromContainer,
  }) =>
      PlannedMeal(
        title: title ?? this.title,
        kind: kind ?? this.kind,
        components: components ?? this.components,
        reheatMinutes: reheatMinutes ?? this.reheatMinutes,
        fromContainer: fromContainer ?? this.fromContainer,
      );
}

/// План одного дня: завтрак / обед / ужин (+ опциональный перекус).
class DayPlan {
  const DayPlan({
    required this.weekday,
    required this.shortName,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    this.snack,
  });

  final String weekday;
  final String shortName;
  final PlannedMeal breakfast;
  final PlannedMeal lunch;
  final PlannedMeal dinner;
  final PlannedMeal? snack;

  PlannedMeal? mealAt(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => breakfast,
        MealSlot.lunch => lunch,
        MealSlot.dinner => dinner,
        MealSlot.snack => snack,
      };

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        weekday: json['weekday'] as String,
        shortName: json['shortName'] as String,
        breakfast: PlannedMeal.fromJson(json['breakfast'] as Map<String, dynamic>),
        lunch: PlannedMeal.fromJson(json['lunch'] as Map<String, dynamic>),
        dinner: PlannedMeal.fromJson(json['dinner'] as Map<String, dynamic>),
        snack: json['snack'] != null
            ? PlannedMeal.fromJson(json['snack'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'shortName': shortName,
        'breakfast': breakfast.toJson(),
        'lunch': lunch.toJson(),
        'dinner': dinner.toJson(),
        if (snack != null) 'snack': snack!.toJson(),
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
