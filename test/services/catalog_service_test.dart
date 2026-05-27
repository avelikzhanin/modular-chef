import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/storage.dart';
import 'package:modular_chef/services/catalog_service.dart';

void main() {
  // CatalogService.load uses rootBundle → requires initialised binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatalogService.load', () {
    test('loads all 4 catalogs from assets', () async {
      final svc = CatalogService();
      await svc.load();

      expect(svc.isLoaded, isTrue);
      expect(svc.loadError, isNull);
      expect(svc.allModules.length, greaterThanOrEqualTo(30));
      expect(svc.allPairings.length, greaterThanOrEqualTo(20));
      expect(svc.allTemplates.length, greaterThanOrEqualTo(4));
      expect(svc.allStorageRules.length, greaterThanOrEqualTo(15));
    });

    test('is idempotent — second call does not re-parse', () async {
      final svc = CatalogService();
      await svc.load();
      final modulesAfterFirst = svc.allModules;

      await svc.load();
      expect(identical(svc.allModules, modulesAfterFirst), isTrue);
    });

    test('modulesByCategory(protein) returns at least 5 proteins', () async {
      final svc = CatalogService();
      await svc.load();

      final proteins = svc.modulesByCategory(ModuleCategory.protein);
      expect(proteins.length, greaterThanOrEqualTo(5));
      expect(proteins.every((m) => m.category == ModuleCategory.protein),
          isTrue);
    });

    test('every catalog category has at least one module', () async {
      final svc = CatalogService();
      await svc.load();

      for (final c in ModuleCategory.values) {
        expect(svc.modulesByCategory(c), isNotEmpty,
            reason: 'category $c is empty');
      }
    });

    test('moduleById returns matching module', () async {
      final svc = CatalogService();
      await svc.load();

      final chicken = svc.moduleById('chicken_breast');
      expect(chicken, isNotNull);
      expect(chicken!.name, 'Курица');
      expect(svc.moduleById('does_not_exist'), isNull);
    });

    test('storageRulesForModule returns rules for chicken with valid zones',
        () async {
      final svc = CatalogService();
      await svc.load();

      final rules = svc.storageRulesForModule('chicken_breast');
      expect(rules, isNotEmpty);
      expect(rules.every((r) => r.moduleId == 'chicken_breast'), isTrue);
      // Курица должна иметь правило для холодильника
      expect(rules.any((r) => r.zone == StorageZone.fridge), isTrue);
    });

    test('pairingsForProtein returns relevant pairings', () async {
      final svc = CatalogService();
      await svc.load();

      final chickenPairings = svc.pairingsForProtein('chicken_breast');
      expect(chickenPairings, isNotEmpty);
      expect(chickenPairings.every((p) => p.proteinId == 'chicken_breast'),
          isTrue);
    });

    test('every pairing references existing modules', () async {
      final svc = CatalogService();
      await svc.load();

      for (final p in svc.allPairings) {
        expect(svc.moduleById(p.proteinId), isNotNull,
            reason: 'unknown protein ${p.proteinId}');
        expect(svc.moduleById(p.sideId), isNotNull,
            reason: 'unknown side ${p.sideId}');
        if (p.sauceId != null) {
          expect(svc.moduleById(p.sauceId!), isNotNull,
              reason: 'unknown sauce ${p.sauceId}');
        }
      }
    });

    test('every storage rule references an existing module', () async {
      final svc = CatalogService();
      await svc.load();

      for (final r in svc.allStorageRules) {
        expect(svc.moduleById(r.moduleId), isNotNull,
            reason: 'unknown moduleId ${r.moduleId}');
      }
    });
  });
}
