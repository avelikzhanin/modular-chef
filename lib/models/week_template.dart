/// Шаблон вкусового профиля недели — задаёт направление для Claude-генератора.
class WeekTemplate {
  const WeekTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tags,
    required this.description,
  });

  final String id;
  final String name;
  final String emoji;
  final List<String> tags;
  final String description;

  factory WeekTemplate.fromJson(Map<String, dynamic> json) => WeekTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        tags: ((json['tags'] as List?) ?? const []).cast<String>(),
        description: json['description'] as String,
      );
}
