import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_operator_web/main.dart';

void main() {
  testWidgets('Operator web portal smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OperatorWebPortal());
    await tester.pump();
    expect(find.text('PARTNER OPERATOR PORTAL'), findsOneWidget);
  });
}
