import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_supervisor/main.dart';

void main() {
  testWidgets('Supervisor app initializes and displays executive consoles',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SupervisorApp());
    await tester.pumpAndSettle();

    expect(find.text('EXECUTIVE SUPERVISOR CONSOLE'), findsOneWidget);
    expect(find.text('KPIs & Revenue'), findsOneWidget);
    expect(find.text('Approvals'), findsOneWidget);
    expect(find.text('Incidents'), findsOneWidget);
    expect(find.text('Cloud Platform'), findsOneWidget);
  });
}
