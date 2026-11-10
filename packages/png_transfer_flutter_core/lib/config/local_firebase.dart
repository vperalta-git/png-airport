import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;
import 'app_config.dart';
import '../theme/aviation_theme.dart';

Future<void> runLocalFoundation(String role) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LocalFirebase.initialize().timeout(const Duration(seconds: 20),
        onTimeout: () {
      throw StateError(
          'Firebase startup timed out. Check local services and static SDK assets.');
    });
    runApp(LocalFoundationApp(role: role));
  } catch (error) {
    runApp(LocalFoundationApp(role: role, error: error.toString()));
  }
}

class LocalFirebase {
  static FirebaseOptions get options => FirebaseOptions(
        apiKey: 'local-emulator-key',
        appId:
            '1:000000000000:${kIsWeb ? 'web' : defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'}:0000000000000000000000',
        messagingSenderId: '000000000000',
        projectId: AppConfig.projectId,
        storageBucket: '${AppConfig.projectId}.appspot.com',
        databaseURL:
            'https://${AppConfig.projectId}-default-rtdb.firebaseio.com',
      );

  /// Check the local backend and all emulator HTTP services before any SDK/app use.
  /// SDK initialization failure never falls back to a cloud project or demo session.
  static Future<void> initialize() async {
    AppConfig.validate();
    final client = http.Client();
    try {
      final origin = AppConfig.normalizeUrl(AppConfig.apiBaseUrl);
      final request = http.Request('GET', Uri.parse('$origin/api/v1/health'))
        ..followRedirects = false;
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 4));
      final envelope = jsonDecode(response.body) as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>;
      if (response.statusCode != 200 ||
          envelope['schemaVersion'] != '1' ||
          envelope['success'] != true ||
          data['environment'] != 'local' ||
          data['projectId'] != AppConfig.projectId) {
        throw StateError(
            'The backend is not the isolated AeroTrans local runtime.');
      }
      // Four independent readiness probes. Responses may be 404, but redirects
      // and unavailable services are rejected before creating any Firebase client.
      for (final port in [
        AppConfig.authPort,
        AppConfig.firestorePort,
        AppConfig.databasePort,
        AppConfig.storagePort
      ]) {
        final path = port == AppConfig.databasePort
            ? '/.json?ns=${AppConfig.projectId}-default-rtdb'
            : '/';
        final probe = http.Request(
            'GET', Uri.parse('http://${AppConfig.emulatorHost}:$port$path'))
          ..followRedirects = false;
        final result = await client
            .send(probe)
            .then(http.Response.fromStream)
            .timeout(const Duration(seconds: 3));
        if (result.statusCode >= 300 && result.statusCode < 400) {
          throw StateError(
              'Emulator returned an unexpected redirect on port $port.');
        }
      }
    } catch (error) {
      throw StateError(
          'Local services unavailable. Start npm run emulators and npm run backend. $error');
    } finally {
      client.close();
    }
    if (Firebase.apps.isNotEmpty &&
        Firebase.app().options.projectId != AppConfig.projectId) {
      throw StateError(
          'An existing Firebase app points outside the local demo project.');
    }
    await Firebase.initializeApp(options: options);
    await FirebaseAuth.instance.useAuthEmulator(
        AppConfig.emulatorHost, AppConfig.authPort,
        automaticHostMapping: false);
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: false);
    FirebaseFirestore.instance.useFirestoreEmulator(
        AppConfig.emulatorHost, AppConfig.firestorePort,
        automaticHostMapping: false);
    FirebaseDatabase.instance.useDatabaseEmulator(
        AppConfig.emulatorHost, AppConfig.databasePort,
        automaticHostMapping: false);
    await FirebaseStorage.instance.useStorageEmulator(
        AppConfig.emulatorHost, AppConfig.storagePort,
        automaticHostMapping: false);
  }
}

/// Existing role UIs remain in source. They are not activated against unsafe legacy
/// mutation paths while Batch B authentication/contract integration is unfinished.
class LocalFoundationApp extends StatelessWidget {
  final String role;
  final String? error;
  const LocalFoundationApp({super.key, required this.role, this.error});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AeroTrans PNG2 - Local Foundation',
        theme: AviationTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('AeroTrans Papua New Guinea')),
          body: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$role - local development',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Text(error == null
                        ? 'Local Firebase foundation is ready.'
                        : 'Local setup needs attention.'),
                    const SizedBox(height: 12),
                    Text(error ??
                        'Auth, Firestore, Realtime Database and Storage use demo-aerotrans-png2. '
                            'Operational screens are preserved in source. Activation awaits Batch B identity, authorization and contract integration.'),
                    const SizedBox(height: 16),
                    const Text(
                        'Local setup: npm run emulators, then npm run backend. Restart this app after correcting setup.'),
                  ],
                )),
          )),
        ),
      );
}
