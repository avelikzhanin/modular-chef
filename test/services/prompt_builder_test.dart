import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/services/catalog_service.dart';
import 'package:modular_chef/services/prompt_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CatalogService catalog;
  setUpAll(() async {
    catalog = CatalogService();
    await catalog.load();
  });

  group('PromptBuilder', () {
    test('embeds template header and JSON request', () async {
      final builder = PromptBuilder();
      final prompt = await builder.build(
        request: const GenerationRequest(
          proteinIds: ['chicken_breast', 'salmon'],
          sideIds: ['rice'],
          soupIds: [],
          breakfastIds: ['oatmeal_jar'],
        ),
        modules: catalog.allModules,
        pairings: catalog.allPairings,
        templates: catalog.allTemplates,
      );

      // Должен включать заголовок промпт-template
      expect(prompt, contains('Modular Chef — генератор меню'));
      // И блок с текущим запросом
      expect(prompt, contains('## Текущий запрос'));
      // И в JSON должны попасть выбранные id
      expect(prompt, contains('"chicken_breast"'));
      expect(prompt, contains('"oatmeal_jar"'));
      // И каталог
      expect(prompt, contains('"catalog"'));
      expect(prompt, contains('"pairings"'));
    });

    test('preferences propagate into JSON payload', () async {
      final builder = PromptBuilder();
      final prompt = await builder.build(
        request: const GenerationRequest(
          proteinIds: ['chicken_breast'],
          sideIds: ['rice'],
          soupIds: [],
          breakfastIds: [],
          allergies: ['dairy'],
          prepTimeLimitMinutes: 90,
          weekStyle: 'mediterranean',
        ),
        modules: catalog.allModules,
        pairings: catalog.allPairings,
        templates: catalog.allTemplates,
      );

      expect(prompt, contains('"allergies"'));
      expect(prompt, contains('"dairy"'));
      expect(prompt, contains('"prepTimeLimitMinutes": 90'));
      expect(prompt, contains('"weekStyle": "mediterranean"'));
    });
  });

  group('GenerationRequest.toJson', () {
    test('уточнения Шефа по завтракам уходят на бэкенд', () {
      const req = GenerationRequest(
        proteinIds: ['chicken_breast'],
        sideIds: [],
        soupIds: [],
        breakfastIds: ['eggs'],
        weeks: 3,
        eggStyleIds: ['egg_omelet'],
        eggAddinIds: ['addin_cheese', 'addin_tomatoes'],
        porridgeKindIds: ['porridge_oat'],
        sandwichFillingIds: ['addin_ham'],
      );

      final json = req.toJson();
      final picks = json['picks'] as Map<String, dynamic>;

      // Раньше эти поля терялись по дороге, и сервер добирал добавки сам —
      // в покупках оказывались бекон и фета, которых Шеф не выбирал.
      expect(picks['eggStyles'], ['egg_omelet']);
      expect(picks['eggAddins'], ['addin_cheese', 'addin_tomatoes']);
      expect(picks['porridgeKinds'], ['porridge_oat']);
      expect(picks['sandwichFillings'], ['addin_ham']);
      expect(json['weeks'], 3, reason: 'горизонт меню тоже игнорировался');
    });

    test('по умолчанию уточнений нет — сервер выбирает сам', () {
      const req = GenerationRequest(
        proteinIds: ['chicken_breast'],
        sideIds: [],
        soupIds: [],
        breakfastIds: ['eggs'],
      );

      final picks = req.toJson()['picks'] as Map<String, dynamic>;
      expect(picks['eggStyles'], isEmpty);
      expect(picks['eggAddins'], isEmpty);
    });
  });
}
