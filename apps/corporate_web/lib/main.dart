import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/corporate_firestore_service.dart';
import 'blocs/corporate_bloc.dart';
import 'blocs/corporate_event.dart';
import 'ui/screens/corporate_portal_screen.dart';

Future<void> main() => runLocalFoundation('Corporate');

// Preserved implementation for Batch B. Not a launch entrypoint.
Future<void> legacyMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  CorporateFirestoreService? corporateFirestoreService;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    corporateFirestoreService = CorporateFirestoreService();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(
      CorporateWebPortal(corporateFirestoreService: corporateFirestoreService));
}

class CorporateWebPortal extends StatelessWidget {
  final CorporateFirestoreService? corporateFirestoreService;

  const CorporateWebPortal({
    super.key,
    this.corporateFirestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CorporateBloc(
        firestoreService: corporateFirestoreService,
      )..add(const LoadCorporateData()),
      child: MaterialApp(
        title: 'PNG Secure Transfer — Corporate Client Portal',
        debugShowCheckedModeBanner: false,
        theme: AviationTheme.lightTheme,
        home: const CorporatePortalScreen(),
      ),
    );
  }
}
