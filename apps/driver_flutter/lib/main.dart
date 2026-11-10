import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/driver_firestore_service.dart';
import 'blocs/duty/duty_bloc.dart';
import 'blocs/missions/missions_bloc.dart';
import 'blocs/missions/missions_event.dart';
import 'blocs/incident/incident_bloc.dart';
import 'ui/screens/missions_list_screen.dart';

Future<void> main() => runLocalFoundation('Driver');

// Preserved implementation for Batch B. Not a launch entrypoint.
Future<void> legacyMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Cloud Firestore & Realtime presence)
  DriverFirestoreService? firestoreService;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firestoreService = DriverFirestoreService();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  final apiClient = PngApiClient();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DutyBloc(firestoreService: firestoreService),
        ),
        BlocProvider(
          create: (_) => MissionsBloc(
            apiClient: apiClient,
            firestoreService: firestoreService,
          )..add(const LoadDriverMissions()),
        ),
        BlocProvider(
          create: (_) => IncidentBloc(firestoreService: firestoreService),
        ),
      ],
      child: const PngTransferDriverApp(),
    ),
  );
}

class PngTransferDriverApp extends StatelessWidget {
  const PngTransferDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PNG Driver & Security Escort',
      debugShowCheckedModeBanner: false,
      theme: AviationTheme.lightTheme,
      home: const MissionsListScreen(),
    );
  }
}
