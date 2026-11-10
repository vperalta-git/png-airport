import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_corporate_web/main.dart';

void main() {
  testWidgets('Corporate web portal smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CorporateWebPortal());
    await tester.pump();
    expect(find.text('PNG SECURE ESCORT • CORPORATE CLIENT PORTAL'), findsOneWidget);
  });
}
