import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/driver_firestore_service.dart';
import 'incident_event.dart';
import 'incident_state.dart';

class IncidentBloc extends Bloc<IncidentEvent, IncidentState> {
  final DriverFirestoreService? firestoreService;

  IncidentBloc({this.firestoreService}) : super(IncidentInitial()) {
    on<TriggerSosAlert>((event, emit) {
      final alertId = 'SOS-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final summary = 'ONE-TOUCH DISTRESS ALARM: GPS ping broadcast to Control Room from ${event.locationDescription}';

      firestoreService?.broadcastIncident(
        alertId: alertId,
        missionId: event.missionId,
        severity: 'CRITICAL',
        summary: summary,
      );

      emit(IncidentAlertActive(
        alertId: alertId,
        missionId: event.missionId,
        severity: 'CRITICAL',
        summary: summary,
        timestamp: DateTime.now(),
      ));
    });

    on<ReportFieldIncident>((event, emit) {
      final alertId = 'INC-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final summary = '${event.issueType}: ${event.notes}';

      firestoreService?.broadcastIncident(
        alertId: alertId,
        missionId: event.missionId,
        severity: event.severity,
        summary: summary,
      );

      emit(IncidentAlertActive(
        alertId: alertId,
        missionId: event.missionId,
        severity: event.severity,
        summary: summary,
        timestamp: DateTime.now(),
      ));
    });
  }
}
