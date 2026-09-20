import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Локальное JSON-хранилище поверх SharedPreferences.
/// Best-effort: любая ошибка (нет плагина в тестах, битые данные) — просто
/// null / no-op, приложение продолжает работать как без сохранения.
class LocalStore {
  SharedPreferences? _prefs;

  /// Кэшируем сам Future, а не «уже пробовали»: сервисы грузятся параллельно,
  /// и с флагом-заглушкой все, кроме первого, получали null и читали пустоту —
  /// состояние сбрасывалось при каждом запуске.
  Future<SharedPreferences?>? _pending;

  Future<SharedPreferences?> _instance() async {
    if (_prefs != null) return _prefs;
    _pending ??= SharedPreferences.getInstance()
        .then<SharedPreferences?>((p) => p)
        .catchError((_) => null);
    _prefs = await _pending;
    return _prefs;
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    try {
      final p = await _instance();
      final raw = p?.getString(key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> data) async {
    try {
      final p = await _instance();
      await p?.setString(key, jsonEncode(data));
    } catch (_) {/* best-effort */}
  }

  Future<void> remove(String key) async {
    try {
      final p = await _instance();
      await p?.remove(key);
    } catch (_) {/* best-effort */}
  }
}
