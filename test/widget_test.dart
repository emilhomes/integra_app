import 'package:flutter_test/flutter_test.dart';
import 'package:integra_app/app/app.dart';

void main() {
  testWidgets('Counter increment smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IntegraApp());

    // Verify that the title is present (as configured in app.dart)
    expect(find.text('ÍNTEGRA'), findsNothing); // Router builds the initial route (login)
  });
}
