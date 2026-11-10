import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_control_room/main.dart';

void main() {
  testWidgets('Control Room app initializes and displays command center',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ControlRoomApp());
    await tester.pumpAndSettle();

    expect(find.text('PNG AIRPORT GROUND OPS COMMAND'), findsOneWidget);
    expect(find.text('Tactical Operations Center • Port Moresby HQ'), findsOneWidget);
    expect(find.text('Airspace Radar'), findsOneWidget);
    expect(find.text('Convoy Fleet'), findsOneWidget);
    expect(find.text('Dispatch Desk'), findsOneWidget);
    expect(find.text('Emergency Desk'), findsOneWidget);
  });
}
