import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/control_room_firestore_service.dart';
import 'blocs/airspace/airspace_bloc.dart';
import 'blocs/convoy/convoy_bloc.dart';
import 'blocs/dispatch/dispatch_bloc.dart';
import 'blocs/dispatch/dispatch_event.dart';
import 'blocs/emergency/emergency_bloc.dart';
import 'ui/screens/control_room_dashboard_screen.dart';

Future<void> main() => runLocalFoundation('Control Room');

// Preserved implementation for Batch B. Not a launch entrypoint.
Future<void> legacyMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  ControlRoomFirestoreService? firestoreService;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firestoreService = ControlRoomFirestoreService();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(ControlRoomApp(firestoreService: firestoreService));
}

class ControlRoomApp extends StatelessWidget {
  final ControlRoomFirestoreService? firestoreService;

  const ControlRoomApp({super.key, this.firestoreService});

  @override
  Widget build(BuildContext context) {
    final apiClient = PngApiClient();
    final flightRadarRepo = FlightRadarRepository(
      service: FlightRadarService(),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AirspaceBloc>(
          create: (_) => AirspaceBloc(flightRadarRepository: flightRadarRepo),
        ),
        BlocProvider<ConvoyBloc>(
          create: (_) => ConvoyBloc(),
        ),
        BlocProvider<DispatchBloc>(
          create: (_) => DispatchBloc(
            apiClient: apiClient,
            firestoreService: firestoreService,
          )..add(const LoadDispatchQueue()),
        ),
        BlocProvider<EmergencyBloc>(
          create: (_) => EmergencyBloc(firestoreService: firestoreService),
        ),
      ],
      child: MaterialApp(
        title: 'PNG Ground Ops Command Desk',
        debugShowCheckedModeBanner: false,
        theme: AviationTheme.lightTheme,
        home: const ControlRoomDashboardScreen(),
      ),
    );
  }
}
