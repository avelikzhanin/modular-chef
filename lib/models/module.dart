import 'storage.dart';

/// Категория модуля — определяет в какой секции UI его показывать.
enum ModuleCategory {
  protein('protein', 'Белки'),
  side('side', 'Гарниры'),
  soup('soup', 'Супы'),
  breakfast('breakfast', 'Завтраки'),
  vegetable('vegetable', 'Овощи'),
  sauce('sauce', 'Соусы');

  const ModuleCategory(this.jsonValue, this.label);
  final String jsonValue;
  final String label;

  static ModuleCategory fromJson(String value) =>
      ModuleCategory.values.firstWhere((c) => c.jsonValue == value);
}

/// Базовая подсказка по хранению, встроенная в каждый модуль.
/// Полные правила (с днями недели, when) живут в [StorageRule].
class StorageHint {
  const StorageHint({required this.zone, required this.days, required this.tip});

  final StorageZone zone;
  final int days;
  final String tip;

  factory StorageHint.fromJson(Map<String, dynamic> json) => StorageHint(
        zone: StorageZone.fromJson(json['zone'] as String),
        days: json['days'] as int,
        tip: (json['tip'] as String?) ?? '',
      );
}

/// Базовый кулинарный модуль — белок, гарнир, суп, завтрак, овощ или соус.
class Module {
  const Module({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.tags,
    required this.methods,
    required this.storage,
    this.caloriesPer100g,
    this.prepMinutes,
  });

  final String id;
  final String name;
  final String emoji;
  final ModuleCategory category;
  final List<String> tags;
  final List<String> methods;
  final StorageHint storage;
  final int? caloriesPer100g;
  final int? prepMinutes;

  factory Module.fromJson(Map<String, dynamic> json) => Module(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        category: ModuleCategory.fromJson(json['category'] as String),
        tags: ((json['tags'] as List?) ?? const []).cast<String>(),
        methods: ((json['methods'] as List?) ?? const []).cast<String>(),
        storage:
            StorageHint.fromJson(json['storage'] as Map<String, dynamic>),
        caloriesPer100g: json['caloriesPer100g'] as int?,
        prepMinutes: json['prepMinutes'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'category': category.jsonValue,
        'tags': tags,
        'methods': methods,
        'storage': {
          'zone': storage.zone.jsonValue,
          'days': storage.days,
          'tip': storage.tip,
        },
        if (caloriesPer100g != null) 'caloriesPer100g': caloriesPer100g,
        if (prepMinutes != null) 'prepMinutes': prepMinutes,
      };
}
