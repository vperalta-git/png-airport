import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'package:png_transfer_driver/blocs/duty/duty_bloc.dart';
import 'package:png_transfer_driver/blocs/missions/missions_bloc.dart';
import 'package:png_transfer_driver/blocs/missions/missions_event.dart';
import 'package:png_transfer_driver/blocs/incident/incident_bloc.dart';
import 'package:png_transfer_driver/main.dart';

void main() {
  testWidgets('Driver & Security personnel app smoke test', (WidgetTester tester) async {
    final apiClient = PngApiClient();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => DutyBloc()),
          BlocProvider(
            create: (_) => MissionsBloc(apiClient: apiClient)..add(const LoadDriverMissions()),
          ),
          BlocProvider(create: (_) => IncidentBloc()),
        ],
        child: const PngTransferDriverApp(),
      ),
    );

    await tester.pump();
    expect(find.text('NO ACTIVE ASSIGNMENTS'), findsOneWidget);
  });
}
