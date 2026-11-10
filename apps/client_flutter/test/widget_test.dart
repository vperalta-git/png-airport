import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'package:png_transfer_client/blocs/auth/auth_bloc.dart';
import 'package:png_transfer_client/blocs/auth/auth_event.dart';
import 'package:png_transfer_client/blocs/airports/airports_bloc.dart';
import 'package:png_transfer_client/blocs/airports/airports_event.dart';
import 'package:png_transfer_client/blocs/flight_radar/flight_radar_bloc.dart';
import 'package:png_transfer_client/blocs/flight_radar/flight_radar_event.dart';
import 'package:png_transfer_client/blocs/booking_wizard/booking_wizard_bloc.dart';
import 'package:png_transfer_client/blocs/my_bookings/my_bookings_bloc.dart';
import 'package:png_transfer_client/blocs/my_bookings/my_bookings_event.dart';
import 'package:png_transfer_client/main.dart';

void main() {
  testWidgets('Passenger client app smoke test', (WidgetTester tester) async {
    final apiClient = PngApiClient();
    final flightRadarService = FlightRadarService();
    final airportRepository = AirportRepository(apiClient: apiClient);
    final bookingRepository = BookingRepository(apiClient: apiClient);
    final flightRadarRepository = FlightRadarRepository(service: flightRadarService);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: airportRepository),
          RepositoryProvider.value(value: bookingRepository),
          RepositoryProvider.value(value: flightRadarRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AuthBloc(apiClient: apiClient)..add(AppStarted()),
            ),
            BlocProvider(
              create: (_) => AirportsBloc(repository: airportRepository)..add(const LoadAirports()),
            ),
            BlocProvider(
              create: (_) => FlightRadarBloc(repository: flightRadarRepository)..add(const LoadFlightRadar()),
            ),
            BlocProvider(
              create: (_) => BookingWizardBloc(repository: bookingRepository),
            ),
            BlocProvider(
              create: (_) => MyBookingsBloc(repository: bookingRepository)..add(const LoadMyBookings()),
            ),
          ],
          child: const PngTransferClientApp(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('NADZAB AIRSPACE RADAR'), findsOneWidget);
  });
}
