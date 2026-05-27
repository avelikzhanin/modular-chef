import 'storage.dart';

/// Конкретное правило хранения с днями недели и подсказкой.
/// Используется на экране «Карта хранения» — дополняет [StorageHint] модуля.
class StorageRule {
  const StorageRule({
    required this.moduleId,
    required this.zone,
    required this.days,
    required this.tip,
    this.when,
  });

  final String moduleId;
  final StorageZone zone;
  final int days;
  final String tip;
  final String? when;

  factory StorageRule.fromJson(Map<String, dynamic> json) => StorageRule(
        moduleId: json['moduleId'] as String,
        zone: StorageZone.fromJson(json['zone'] as String),
        days: json['days'] as int,
        when: json['when'] as String?,
        tip: (json['tip'] as String?) ?? '',
      );
}
