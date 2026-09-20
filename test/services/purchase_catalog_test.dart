import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/services/purchase_catalog.dart';

void main() {
  group('Отделы магазина', () {
    // Список покупок рисуется перебором kShopSections: строка с отделом вне
    // этого списка не показывается вообще, хотя в счётчик «N поз.» попадает.
    // Так пропадали яйца, молоко, сыр и сливки — отдел назывался
    // «Молочное и яйца», а в kShopSections он «Молочное, сыры и яйца».
    test('ингредиенты супов лежат в существующих отделах', () {
      for (final entry in kSoupIngredients.entries) {
        for (final i in entry.value) {
          expect(kShopSections, contains(i.section),
              reason: '${entry.key} → «${i.name}»: отдела «${i.section}» нет');
        }
      }
    });

    test('ингредиенты домашних соусов лежат в существующих отделах', () {
      for (final entry in kHomemadeSauceIngredients.entries) {
        for (final i in entry.value) {
          expect(kShopSections, contains(i.section),
              reason: '${entry.key} → «${i.name}»: отдела «${i.section}» нет');
        }
      }
    });
  });
}
