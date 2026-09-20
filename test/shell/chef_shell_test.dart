import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/shell/chef_shell.dart';
import 'package:modular_chef/shell/linen_nav_bar.dart';

Widget _harness(Widget child) => MaterialApp(home: child);

void main() {
  group('ChefShell', () {
    testWidgets('renders LinenNavBar with 5 destinations', (tester) async {
      await tester.pumpWidget(_harness(
        ChefShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      expect(find.byType(LinenNavBar), findsOneWidget);
    });

    testWidgets('labels match chef tab plan', (tester) async {
      await tester.pumpWidget(_harness(
        ChefShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      for (final label in const ['Меню', 'Покупки', 'Готовка', 'Запасы', 'Профиль']) {
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
