import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/shell/guest_shell.dart';

Widget _harness(Widget child) => MaterialApp(home: child);

void main() {
  group('GuestShell', () {
    testWidgets('renders NavigationBar with 2 destinations', (tester) async {
      await tester.pumpWidget(_harness(
        GuestShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(2));
    });

    testWidgets('labels match guest tab plan (Сегодня + Запасы)', (tester) async {
      await tester.pumpWidget(_harness(
        GuestShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      for (final label in const ['Сегодня', 'Запасы']) {
        expect(find.text(label), findsOneWidget, reason: 'missing tab "$label"');
      }
      expect(find.text('Неделя'), findsNothing);
    });

    testWidgets('tapping Запасы calls onDestinationSelected with index 1',
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
      expect(tapped, 1);
    });
  });
}
