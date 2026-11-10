import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'blocs/analytics/analytics_bloc.dart';
import 'blocs/approvals/approvals_bloc.dart';
import 'blocs/approvals/approvals_event.dart';
import 'blocs/incidents/incident_bloc.dart';
import 'blocs/cloud_sync/cloud_sync_bloc.dart';
import 'ui/screens/supervisor_dashboard_screen.dart';

Future<void> main() => runMobileDemo('SUPERVISOR');

// Preserved implementation for Batch B. Not a launch entrypoint.
void legacyMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SupervisorApp());
}

class SupervisorApp extends StatelessWidget {
  const SupervisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = PngApiClient();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AnalyticsBloc>(
          create: (_) => AnalyticsBloc(),
        ),
        BlocProvider<ApprovalsBloc>(
          create: (_) => ApprovalsBloc(apiClient: apiClient)..add(const LoadEscortApprovals()),
        ),
        BlocProvider<SupervisorIncidentBloc>(
          create: (_) => SupervisorIncidentBloc(),
        ),
        BlocProvider<CloudSyncBloc>(
          create: (_) => CloudSyncBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'PNG Ground Ops - Executive Supervisor',
        debugShowCheckedModeBanner: false,
        theme: AviationTheme.lightTheme,
        home: const SupervisorDashboardScreen(),
      ),
    );
  }
}
