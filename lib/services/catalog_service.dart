import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/pairing.dart';
import 'package:modular_chef/models/storage_rule.dart';
import 'package:modular_chef/models/week_template.dart';

/// Загружает 4 JSON-каталога из `assets/data/` и предоставляет
/// типизированный доступ к модулям, парам, шаблонам и правилам хранения.
class CatalogService extends ChangeNotifier {
  List<Module> _modules = const [];
  List<Pairing> _pairings = const [];
  List<WeekTemplate> _templates = const [];
  List<StorageRule> _rules = const [];

  bool _isLoaded = false;
  Object? _loadError;

  bool get isLoaded => _isLoaded;
  Object? get loadError => _loadError;

  /// Параллельно загружает все 4 каталога. Идемпотентно — повторный вызов
  /// после успешной загрузки сразу возвращается без обращений к bundle.
  Future<void> load({AssetBundle? bundle}) async {
    if (_isLoaded) return;
    final b = bundle ?? rootBundle;
    try {
      final results = await Future.wait([
        b.loadString('assets/data/modules.json'),
        b.loadString('assets/data/pairings.json'),
        b.loadString('assets/data/week_templates.json'),
        b.loadString('assets/data/storage_rules.json'),
      ]);
      _modules = (jsonDecode(results[0]) as List)
          .cast<Map<String, dynamic>>()
          .map(Module.fromJson)
          .toList(growable: false);
      _pairings = (jsonDecode(results[1]) as List)
          .cast<Map<String, dynamic>>()
          .map(Pairing.fromJson)
          .toList(growable: false);
      _templates = (jsonDecode(results[2]) as List)
          .cast<Map<String, dynamic>>()
          .map(WeekTemplate.fromJson)
          .toList(growable: false);
      _rules = (jsonDecode(results[3]) as List)
          .cast<Map<String, dynamic>>()
          .map(StorageRule.fromJson)
          .toList(growable: false);
      _isLoaded = true;
      _loadError = null;
    } catch (e) {
      _loadError = e;
    } finally {
      notifyListeners();
    }
  }

  // Lookups ------------------------------------------------------------------

  List<Module> get allModules => _modules;
  List<Pairing> get allPairings => _pairings;
  List<WeekTemplate> get allTemplates => _templates;
  List<StorageRule> get allStorageRules => _rules;

  List<Module> modulesByCategory(ModuleCategory category) =>
      _modules.where((m) => m.category == category).toList(growable: false);

  Module? moduleById(String id) {
    for (final m in _modules) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<StorageRule> storageRulesForModule(String moduleId) =>
      _rules.where((r) => r.moduleId == moduleId).toList(growable: false);

  List<Pairing> pairingsForProtein(String proteinId) => _pairings
      .where((p) => p.proteinId == proteinId)
      .toList(growable: false);
}
