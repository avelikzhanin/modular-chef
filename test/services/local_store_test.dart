import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modular_chef/services/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'flutter.active_menu': '{"a":1}',
      'flutter.pantry_stock': '{"b":2}',
      'flutter.app_settings': '{"c":3}',
    });
  });

  test('параллельные чтения возвращают данные, а не пустоту', () async {
    // Регрессия: сервисы грузятся через Future.wait, и раньше все, кроме
    // первого, получали null — состояние сбрасывалось при каждом запуске.
    final store = LocalStore();
    final results = await Future.wait([
      store.readJson('active_menu'),
      store.readJson('pantry_stock'),
      store.readJson('app_settings'),
      store.readJson('active_menu'),
      store.readJson('pantry_stock'),
      store.readJson('app_settings'),
    ]);

    expect(results.where((r) => r != null).length, results.length,
        reason: 'каждое параллельное чтение обязано вернуть данные');
    expect(results[0]!['a'], 1);
    expect(results[1]!['b'], 2);
    expect(results[2]!['c'], 3);
  });

  test('запись и чтение переживают новый экземпляр хранилища', () async {
    await LocalStore().writeJson('today_plan', {'slots': 4});
    final restored = await LocalStore().readJson('today_plan');
    expect(restored?['slots'], 4);
  });
}
