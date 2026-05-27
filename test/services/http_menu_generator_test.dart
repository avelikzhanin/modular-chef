import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/services/http_menu_generator.dart';
import 'package:modular_chef/services/prompt_builder.dart';

/// Перехватывает запросы и возвращает заранее заданный JSON — без реальной сети.
class _StubInterceptor extends Interceptor {
  _StubInterceptor(this.response);
  final Map<String, dynamic> response;
  RequestOptions? captured;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured = options;
    handler.resolve(Response<Map<String, dynamic>>(
      requestOptions: options,
      data: response,
      statusCode: 200,
    ));
  }
}

void main() {
  group('HttpMenuGenerator', () {
    test('POSTs the request and parses WeeklyMenu from response', () async {
      final fakeResponse = <String, dynamic>{
        'weeks': [
          {
            'index': 0,
            'name': 'Неделя 1',
            'days': [
              {
                'weekday': 'monday',
                'shortName': 'Пн',
                'breakfast': {
                  'title': 'Овсянка',
                  'moduleIds': ['oatmeal_jar'],
                  'reheatMinutes': 0,
                },
                'lunch': {
                  'title': 'Курица + рис',
                  'moduleIds': ['chicken_breast', 'rice'],
                  'reheatMinutes': 2,
                },
                'dinner': {
                  'title': 'Лосось',
                  'moduleIds': ['salmon'],
                  'reheatMinutes': 3,
                },
              },
            ],
          },
        ],
        'summary': {
          'uniqueDishes': 3,
          'totalMeals': 3,
          'modulesUsed': 4,
          'flavourProfiles': ['mediterranean'],
        },
      };

      final interceptor = _StubInterceptor(fakeResponse);
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(interceptor);
      final gen = HttpMenuGenerator(baseUrl: 'https://example.test', dio: dio);

      final menu = await gen.generate(
        const GenerationRequest(
          proteinIds: ['chicken_breast'],
          sideIds: ['rice'],
          soupIds: [],
          breakfastIds: ['oatmeal_jar'],
        ),
        modules: const [],
        pairings: const [],
      );

      expect(interceptor.captured, isNotNull);
      expect(interceptor.captured!.path, '/menus/generate');
      expect(interceptor.captured!.method, 'POST');
      final sentPayload = interceptor.captured!.data as Map<String, dynamic>;
      expect(sentPayload['picks']['proteins'], ['chicken_breast']);

      expect(menu.weeks, hasLength(1));
      expect(menu.weeks.first.days.first.lunch.title, 'Курица + рис');
      expect(menu.summary.modulesUsed, 4);
    });
  });
}
