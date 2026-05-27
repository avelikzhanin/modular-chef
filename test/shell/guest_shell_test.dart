import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/shell/guest_shell.dart';

Widget _harness(Widget child) => MaterialApp(home: child);

void main() {
  group('GuestShell', () {
    testWidgets('renders NavigationBar with 3 destinations', (tester) async {
      await tester.pumpWidget(_harness(
        GuestShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
    });

    testWidgets('labels match guest tab plan', (tester) async {
      await tester.pumpWidget(_harness(
        GuestShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      for (final label in const ['Сегодня', 'Неделя', 'Запасы']) {
        expect(find.text(label), findsOneWidget, reason: 'missing tab "$label"');
      }
    });

    testWidgets('tapping destination calls onDestinationSelected with index',
        (tester) async {
      int? tapped;
      await tester.pumpWidget(_harness(
        GuestShell(
          currentIndex: 0,
          onDestinationSelected: (i) => tapped = i,
          child: const Placeholder(),
        ),
      ));

      await tester.tap(find.text('Запасы'));
      expect(tapped, 2);
    });
  });
}
