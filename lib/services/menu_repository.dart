import 'package:dio/dio.dart';
import 'package:modular_chef/models/weekly_menu.dart';

/// Сохранение/загрузка активного меню. Best-effort: ошибки сети не валят UI.
abstract class MenuRepository {
  Future<void> saveActive(WeeklyMenu menu);
  Future<WeeklyMenu?> fetchActive();
}

/// Сетевой репозиторий — FastAPI `/menus/save` и `/menus/active`.
class HttpMenuRepository implements MenuRepository {
  HttpMenuRepository({required this.baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {'Content-Type': 'application/json'},
              // 404 (нет активного меню) — не исключение, обрабатываем сами
              validateStatus: (s) => s != null && s < 500,
            ));

  final String baseUrl;
  final Dio _dio;

  @override
  Future<void> saveActive(WeeklyMenu menu) async {
    try {
      await _dio.post<Map<String, dynamic>>('/menus/save', data: menu.toJson());
    } catch (_) {
      // best-effort: не удалось сохранить — не критично для UX
    }
  }

  @override
  Future<WeeklyMenu?> fetchActive() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/menus/active');
      if (r.statusCode == 200 && r.data != null) {
        return WeeklyMenu.fromJson(r.data!);
      }
      return null; // 404 — активного меню ещё нет
    } catch (_) {
      return null;
    }
  }
}

/// Оффлайн-заглушка (когда backend не настроен): ничего не хранит.
class NoopMenuRepository implements MenuRepository {
  const NoopMenuRepository();

  @override
  Future<void> saveActive(WeeklyMenu menu) async {}

  @override
  Future<WeeklyMenu?> fetchActive() async => null;
}
