import 'package:dio/dio.dart';

import 'package:modular_chef/models/module.dart';
import 'package:modular_chef/models/pairing.dart';
import 'package:modular_chef/models/weekly_menu.dart';
import 'package:modular_chef/services/menu_generator.dart';
import 'package:modular_chef/services/prompt_builder.dart';

/// Сетевая реализация генератора — POST'ит на FastAPI backend.
/// Backend сам вызывает Claude API; ключ живёт только на сервере.
class HttpMenuGenerator implements MenuGenerator {
  HttpMenuGenerator({required this.baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              // Claude иногда отвечает 10-15 секунд, особенно opus
              receiveTimeout: const Duration(seconds: 60),
              headers: const {'Content-Type': 'application/json'},
            ));

  final String baseUrl;
  final Dio _dio;

  @override
  Future<WeeklyMenu> generate(
    GenerationRequest request, {
    required List<Module> modules,
    required List<Pairing> pairings,
  }) async {
    // На сервере свой каталог из БД — клиентский передаём только как hint
    // в pickIds. Если бэк хочет видеть наш каталог явно — раскомментируем catalog.
    final payload = request.toJson();
    final response = await _dio.post<Map<String, dynamic>>(
      '/menus/generate',
      data: payload,
    );

    final data = response.data;
    if (data == null) {
      throw const HttpMenuGeneratorException(
        'Сервер вернул пустой ответ',
      );
    }
    return WeeklyMenu.fromJson(data);
  }
}

class HttpMenuGeneratorException implements Exception {
  const HttpMenuGeneratorException(this.message);
  final String message;

  @override
  String toString() => 'HttpMenuGeneratorException: $message';
}
