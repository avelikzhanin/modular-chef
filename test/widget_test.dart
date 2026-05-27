import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modular_chef/app.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App boots and shows the chef menu tab', (tester) async {
    await tester.pumpWidget(const ModularChefApp());
    await tester.pumpAndSettle();
    expect(find.text('Меню'), findsWidgets);
  });
}
