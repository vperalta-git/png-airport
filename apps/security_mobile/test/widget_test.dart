import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_security_mobile/main.dart';

void main() {
  testWidgets('Security mobile tactical terminal smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SecurityMobileApp());
    await tester.pump();
    expect(find.text('TACTICAL ESCORT TERMINAL'), findsOneWidget);
  });
}
