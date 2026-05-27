import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/pairing.dart';
import 'package:modular_chef/models/week_template.dart';

/// Что пользователь и контекст передают генератору меню.
class GenerationRequest {
  const GenerationRequest({
    required this.proteinIds,
    required this.sideIds,
    required this.soupIds,
    required this.breakfastIds,
    this.customDishes = const [],
    this.allergies = const [],
    this.prepTimeLimitMinutes = 120,
    this.weekStyle,
  });

  final List<String> proteinIds;
  final List<String> sideIds;
  final List<String> soupIds;
  final List<String> breakfastIds;
  final List<String> customDishes;
  final List<String> allergies;
  final int prepTimeLimitMinutes;
  final String? weekStyle;

  Map<String, dynamic> toJson() => {
        'picks': {
          'proteins': proteinIds,
          'sides': sideIds,
          'soups': soupIds,
          'breakfasts': breakfastIds,
          'custom': customDishes,
        },
        'preferences': {
          'allergies': allergies,
          'prepTimeLimitMinutes': prepTimeLimitMinutes,
          if (weekStyle != null) 'weekStyle': weekStyle,
        },
      };
}

/// Собирает полный промпт для Claude из template + каталога + запроса.
/// Используется как на клиенте (тесты, отладка), так и на бэке (Stage 5).
class PromptBuilder {
  PromptBuilder({this.bundle});

  final AssetBundle? bundle;

  static const _templatePath = 'assets/prompts/menu_generator.md';

  Future<String> build({
    required GenerationRequest request,
    required List<Module> modules,
    required List<Pairing> pairings,
    required List<WeekTemplate> templates,
  }) async {
    final tpl = await (bundle ?? rootBundle).loadString(_templatePath);
    final payload = <String, dynamic>{
      ...request.toJson(),
      'catalog': {
        'modules': modules.map((m) => m.toJson()).toList(),
        'pairings': pairings
            .map((p) => {
                  'protein': p.proteinId,
                  'side': p.sideId,
                  if (p.sauceId != null) 'sauce': p.sauceId,
                  'tags': p.tags,
                  if (p.name != null) 'name': p.name,
                })
            .toList(),
        'templates': templates
            .map((t) => {
                  'id': t.id,
                  'name': t.name,
                  'tags': t.tags,
                  'description': t.description,
                })
            .toList(),
      },
    };

    return '$tpl\n\n## Текущий запрос\n\n```json\n${const JsonEncoder.withIndent('  ').convert(payload)}\n```\n';
  }
}
