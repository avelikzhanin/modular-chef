import 'dart:async';

import 'package:dio/dio.dart';
import 'package:modular_chef/services/local_store.dart';

/// LocalStore с синхронизацией через бэкенд (`/state/{key}`):
/// каждая локальная запись уезжает на сервер (с задержкой-дебаунсом),
/// [pullAll] стягивает свежие значения — так телефоны Шефа и Гостя
/// видят одни запасы, один план дня и один список покупок.
///
/// Конфликты решает время: локальная запись помнит свой момент, и pull
/// НЕ перетирает её более старым серверным значением — утверждённое меню
/// не пропадает, даже если push не успел уйти перед закрытием приложения.
/// Всё best-effort: нет сети — работает как обычный LocalStore.
class SyncedStore extends LocalStore {
  SyncedStore({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 8),
          headers: const {'Content-Type': 'application/json'},
          validateStatus: (s) => s != null && s < 500,
        ));

  final Dio _dio;
  final Map<String, Timer> _pushTimers = {};

  String _tsKey(String key) => 'ts:$key';

  Future<int> _localTs(String key) async {
    final j = await super.readJson(_tsKey(key));
    return (j?['t'] as int?) ?? 0;
  }

  @override
  Future<void> writeJson(String key, Map<String, dynamic> data) async {
    await super.writeJson(key, data);
    await super
        .writeJson(_tsKey(key), {'t': DateTime.now().millisecondsSinceEpoch});
    // Дебаунс: частые правки (чекбоксы списка) уезжают одним запросом.
    _pushTimers[key]?.cancel();
    _pushTimers[key] = Timer(const Duration(milliseconds: 1500), () {
      _push(key, data);
    });
  }

  Future<void> _push(String key, Map<String, dynamic> data) async {
    try {
      await _dio.put<Map<String, dynamic>>('/state/$key', data: {'value': data});
    } catch (_) {/* нет сети — доедет при следующей записи */}
  }

  /// Стягивает значения ключей с сервера в локальный кэш.
  /// Применяет только то, что НОВЕЕ локального. true — что-то обновилось.
  Future<bool> pullAll(Iterable<String> keys) async {
    var changed = false;
    for (final key in keys) {
      try {
        final r = await _dio.get<Map<String, dynamic>>('/state/$key');
        if (r.statusCode != 200) continue;
        final value = (r.data ?? const {})['value'];
        final serverAtRaw = (r.data ?? const {})['updatedAt'];
        if (value is! Map<String, dynamic>) continue;
        final serverAt =
            DateTime.tryParse(serverAtRaw as String? ?? '')
                    ?.millisecondsSinceEpoch ??
                0;
        final localAt = await _localTs(key);
        if (serverAt <= localAt) continue; // локальное свежее — не трогаем
        // Мимо writeJson — иначе запушим обратно то, что только что стянули.
        await super.writeJson(key, value);
        await super.writeJson(_tsKey(key), {'t': serverAt});
        changed = true;
      } catch (_) {/* best-effort */}
    }
    return changed;
  }

  void dispose() {
    for (final t in _pushTimers.values) {
      t.cancel();
    }
    _pushTimers.clear();
  }
}
