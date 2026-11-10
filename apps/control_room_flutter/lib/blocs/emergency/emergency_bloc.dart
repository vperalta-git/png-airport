import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/sos_alert.dart';
import '../../services/control_room_firestore_service.dart';
import 'emergency_event.dart';
import 'emergency_state.dart';

class EmergencyBloc extends Bloc<EmergencyEvent, EmergencyState> {
  final ControlRoomFirestoreService? firestoreService;

  EmergencyBloc({this.firestoreService}) : super(const EmergencyState()) {
    on<LoadEmergencyAlerts>(_onLoadEmergencyAlerts);
    on<AcknowledgeAlert>(_onAcknowledgeAlert);
    on<DispatchQrfSupport>(_onDispatchQrfSupport);
    on<ResolveAlert>(_onResolveAlert);
    on<TriggerSimulatedDistress>(_onTriggerSimulatedDistress);
  }

  void _onLoadEmergencyAlerts(
    LoadEmergencyAlerts event,
    Emitter<EmergencyState> emit,
  ) {
    final activeAlerts = [
      SosAlert(
        id: 'sos_01',
        unitCallsign: 'Bravo-2 (VIP Escort)',
        driverName: 'Lucas Kua',
        locationDesc: 'Erima Flyover approach, Port Moresby',
        latitude: '-9.4382',
        longitude: '147.1994',
        severity: AlertSeverity.p2RoadblockCivil,
        status: AlertStatus.activeUnacknowledged,
        message: 'Spike strips / burning debris reported by spotter. Rerouting via ATS corridor.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ];

    emit(state.copyWith(
      status: EmergencyStatus.hasActiveAlerts,
      alerts: activeAlerts,
      activeBroadcastMessage: 'ATTENTION: P2 Civil Roadblock reported near Erima Flyover.',
    ));
  }

  void _onAcknowledgeAlert(
    AcknowledgeAlert event,
    Emitter<EmergencyState> emit,
  ) {
    final notes = 'Acknowledged by Control Room Operator ${event.officerName}';
    firestoreService?.updateIncidentResponse(
      incidentId: event.alertId,
      status: 'under_response',
      responseNotes: notes,
    );

    final updated = state.alerts.map((alert) {
      if (alert.id == event.alertId) {
        return alert.copyWith(
          status: AlertStatus.underResponse,
          responseNotes: notes,
        );
      }
      return alert;
    }).toList();

    emit(state.copyWith(
      alerts: updated,
      activeBroadcastMessage: 'Alert ${event.alertId} acknowledged. Incident command established.',
    ));
  }

  void _onDispatchQrfSupport(
    DispatchQrfSupport event,
    Emitter<EmergencyState> emit,
  ) {
    final notes = 'QRF Unit [${event.qrfUnitCallsign}] scrambled with instructions: ${event.instructions}. ETA 6 mins.';
    firestoreService?.updateIncidentResponse(
      incidentId: event.alertId,
      status: 'qrf_dispatched',
      responseNotes: notes,
    );

    final updated = state.alerts.map((alert) {
      if (alert.id == event.alertId) {
        return alert.copyWith(
          status: AlertStatus.underResponse,
          responseNotes: notes,
        );
      }
      return alert;
    }).toList();

    emit(state.copyWith(
      alerts: updated,
      activeBroadcastMessage:
          'QRF Unit ${event.qrfUnitCallsign} deployed to assist ${event.alertId}. Local Police (RPNGC Sector 4) alerted.',
    ));
  }

  void _onResolveAlert(
    ResolveAlert event,
    Emitter<EmergencyState> emit,
  ) {
    final notes = 'RESOLVED: ${event.resolutionReport}';
    firestoreService?.updateIncidentResponse(
      incidentId: event.alertId,
      status: 'resolved',
      responseNotes: notes,
    );

    final updated = state.alerts.map((alert) {
      if (alert.id == event.alertId) {
        return alert.copyWith(
          status: AlertStatus.resolved,
          responseNotes: notes,
        );
      }
      return alert;
    }).toList();

    final remainingActive = updated.any(
      (a) => a.status != AlertStatus.resolved,
    );

    emit(state.copyWith(
      status: remainingActive ? EmergencyStatus.hasActiveAlerts : EmergencyStatus.normal,
      alerts: updated,
      activeBroadcastMessage: 'Alert ${event.alertId} resolved. All units standing down.',
    ));
  }

  void _onTriggerSimulatedDistress(
    TriggerSimulatedDistress event,
    Emitter<EmergencyState> emit,
  ) {
    final updated = [event.alert, ...state.alerts];
    emit(state.copyWith(
      status: EmergencyStatus.hasActiveAlerts,
      alerts: updated,
      activeBroadcastMessage:
          'HIGH ALERT: New distress signal received from ${event.alert.unitCallsign}!',
    ));
  }
}
