import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/shell/chef_shell.dart';

Widget _harness(Widget child) => MaterialApp(home: child);

void main() {
  group('ChefShell', () {
    testWidgets('renders NavigationBar with 5 destinations', (tester) async {
      await tester.pumpWidget(_harness(
        ChefShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('labels match chef tab plan', (tester) async {
      await tester.pumpWidget(_harness(
        ChefShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      for (final label in const ['Меню', 'Покупки', 'Подготовка', 'Хранение', 'Профиль']) {
        expect(find.text(label), findsOneWidget, reason: 'missing tab "$label"');
      }
    });

    testWidgets('tapping destination calls onDestinationSelected with index',
        (tester) async {
      int? tapped;
      await tester.pumpWidget(_harness(
        ChefShell(
          currentIndex: 0,
          onDestinationSelected: (i) => tapped = i,
          child: const Placeholder(),
        ),
      ));

      await tester.tap(find.text('Покупки'));
      expect(tapped, 1);
    });
  });
}
