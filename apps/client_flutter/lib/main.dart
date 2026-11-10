import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firestore_booking_service.dart';
import 'services/firestore_auth_service.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/airports/airports_bloc.dart';
import 'blocs/airports/airports_event.dart';
import 'blocs/flight_radar/flight_radar_bloc.dart';
import 'blocs/flight_radar/flight_radar_event.dart';
import 'blocs/booking_wizard/booking_wizard_bloc.dart';
import 'blocs/my_bookings/my_bookings_bloc.dart';
import 'blocs/my_bookings/my_bookings_event.dart';
import 'ui/screens/home_navigation_screen.dart';
import 'ui/screens/auth/login_screen.dart';

Future<void> main() => runLocalFoundation('Customer');

// Preserved implementation for Batch B. Not a launch entrypoint.
Future<void> legacyMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Cloud Firestore & FCM)
  FirestoreBookingService? firestoreBookingService;
  FirestoreAuthService? firestoreAuthService;
  final apiClient = PngApiClient();
  final flightRadarService = FlightRadarService();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firestoreBookingService = FirestoreBookingService();
    firestoreAuthService = FirestoreAuthService(
      firestore: FirebaseFirestore.instance,
      apiClient: apiClient,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize Core Repositories
  final airportRepository = AirportRepository(apiClient: apiClient);
  final bookingRepository = BookingRepository(apiClient: apiClient);
  final flightRadarRepository = FlightRadarRepository(service: flightRadarService);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: airportRepository),
        RepositoryProvider.value(value: bookingRepository),
        RepositoryProvider.value(value: flightRadarRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(
              apiClient: apiClient,
              authService: firestoreAuthService,
            )..add(AppStarted()),
          ),
          BlocProvider(
            create: (_) => AirportsBloc(repository: airportRepository)..add(const LoadAirports()),
          ),
          BlocProvider(
            create: (_) => FlightRadarBloc(repository: flightRadarRepository)..add(const LoadFlightRadar()),
          ),
          BlocProvider(
            create: (_) => BookingWizardBloc(
              repository: bookingRepository,
              firestoreService: firestoreBookingService,
            ),
          ),
          BlocProvider(
            create: (_) => MyBookingsBloc(
              repository: bookingRepository,
              firestoreService: firestoreBookingService,
            )..add(const LoadMyBookings()),
          ),
        ],
        child: const PngTransferClientApp(),
      ),
    ),
  );
}

class PngTransferClientApp extends StatelessWidget {
  const PngTransferClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PNG Airport Transfer',
      debugShowCheckedModeBanner: false,
      theme: AviationTheme.lightTheme,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return const HomeNavigationScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
