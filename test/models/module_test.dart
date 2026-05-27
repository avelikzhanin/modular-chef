import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/storage.dart';

void main() {
  group('Module', () {
    test('fromJson parses a protein with methods and storage', () {
      final json = <String, dynamic>{
        'id': 'chicken_breast',
        'name': 'Курица',
        'emoji': '🍗',
        'category': 'protein',
        'tags': ['lean', 'fast'],
        'caloriesPer100g': 165,
        'prepMinutes': 25,
        'methods': ['Запечь 40мин', 'Гриль 25мин'],
        'storage': {'zone': 'fridge', 'days': 3, 'tip': 'Контейнеры подписаны'},
      };

      final m = Module.fromJson(json);

      expect(m.id, 'chicken_breast');
      expect(m.name, 'Курица');
      expect(m.category, ModuleCategory.protein);
      expect(m.tags, ['lean', 'fast']);
      expect(m.methods.length, 2);
      expect(m.storage.zone, StorageZone.fridge);
      expect(m.storage.days, 3);
      expect(m.caloriesPer100g, 165);
    });

    test('fromJson handles optional fields missing', () {
      final json = <String, dynamic>{
        'id': 'lemon_dressing',
        'name': 'Лимонная заправка',
        'emoji': '🍋',
        'category': 'sauce',
        'methods': ['Сборка 2мин'],
        'storage': {'zone': 'fridge', 'days': 7},
      };

      final m = Module.fromJson(json);

      expect(m.tags, isEmpty);
      expect(m.caloriesPer100g, isNull);
      expect(m.storage.tip, '');
    });

    test('round-trip fromJson → toJson preserves all set fields', () {
      final json = <String, dynamic>{
        'id': 'salmon',
        'name': 'Лосось',
        'emoji': '🐟',
        'category': 'protein',
        'tags': ['omega3'],
        'caloriesPer100g': 208,
        'prepMinutes': 18,
        'methods': ['В фольге 20мин'],
        'storage': {'zone': 'vacuum', 'days': 5, 'tip': 'Без вакуума пропадёт'},
      };

      final m = Module.fromJson(json);
      final round = m.toJson();

      expect(round['id'], json['id']);
      expect(round['category'], 'protein');
      expect((round['storage'] as Map)['zone'], 'vacuum');
      expect(round['methods'], json['methods']);
    });

    test('ModuleCategory.fromJson throws on unknown', () {
      expect(() => ModuleCategory.fromJson('nope'), throwsStateError);
    });

    test('StorageZone exposes label and emoji', () {
      expect(StorageZone.fridge.label, 'Холодильник');
      expect(StorageZone.freezer.emoji, '🟦');
      expect(StorageZone.vacuum.jsonValue, 'vacuum');
    });
  });
}
