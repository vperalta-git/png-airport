import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/incident_case.dart';
import 'incident_event.dart';
import 'incident_state.dart';

class SupervisorIncidentBloc
    extends Bloc<SupervisorIncidentEvent, SupervisorIncidentState> {
  SupervisorIncidentBloc() : super(const SupervisorIncidentState()) {
    on<LoadSupervisorIncidents>(_onLoadSupervisorIncidents);
    on<UpdateIncidentInvestigation>(_onUpdateIncidentInvestigation);
    on<CloseIncidentCaseEvent>(_onCloseIncidentCaseEvent);
  }

  void _onLoadSupervisorIncidents(
    LoadSupervisorIncidents event,
    Emitter<SupervisorIncidentState> emit,
  ) {
    emit(state.copyWith(status: IncidentReviewStatus.loading));

    final initialCases = [
      IncidentCase(
        id: 'INC-2026-0041',
        missionRef: 'BK-POM-2026-0894',
        unitCallsign: 'Bravo-2 (VIP Escort)',
        driverName: 'Lucas Kua',
        incidentType: 'Civil Unrest & Roadblock',
        location: 'Erima Flyover roundabout, Port Moresby',
        occurrenceTime: DateTime.now().subtract(const Duration(hours: 4, minutes: 15)),
        status: IncidentStatus.rpngcReportFiled,
        initialSummary:
            'Hostile crowd burning tyres near flyover. Driver conducted evasive detour through ATS back-road to secure principal Dr. Sarah Jenkins.',
        policeReportNumber: 'RPNGC-NCD-2026-0881',
        supervisorFindings:
            'Tactical evasion executed in accordance with SOP. No damage to vehicle B7 plating.',
        correctiveAction:
            'Control Room designated Erima Flyover as Yellow Alert zone for night flights.',
      ),
      IncidentCase(
        id: 'INC-2026-0038',
        missionRef: 'BK-LAE-2026-0012',
        unitCallsign: 'Sierra-Lae-1',
        driverName: 'Mathew Gawi',
        incidentType: 'Gravel Slide & Puncture',
        location: 'Highlands Highway, Markham Valley (KM 42)',
        occurrenceTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        status: IncidentStatus.closed,
        initialSummary:
            'Heavy rain caused loose mud on highway. Right rear tire damaged by sharp rock.',
        policeReportNumber: 'N/A - Non-hostile mechanical',
        supervisorFindings: 'Secondary chase vehicle swapped tire within 7 minutes.',
        correctiveAction: 'Fitted heavy-duty Kevlar sidewall tires on Nadzab fleet.',
      ),
    ];

    emit(state.copyWith(
      status: IncidentReviewStatus.loaded,
      cases: initialCases,
    ));
  }

  void _onUpdateIncidentInvestigation(
    UpdateIncidentInvestigation event,
    Emitter<SupervisorIncidentState> emit,
  ) {
    final updated = state.cases.map((c) {
      if (c.id == event.caseId) {
        return c.copyWith(
          policeReportNumber: event.policeReportNumber,
          supervisorFindings: event.supervisorFindings,
          correctiveAction: event.correctiveAction,
          status: IncidentStatus.insuranceSubmitted,
        );
      }
      return c;
    }).toList();

    emit(state.copyWith(
      cases: updated,
      notificationMessage:
          'Case ${event.caseId} updated with RPNGC Report ${event.policeReportNumber} & submitted to Insurance.',
    ));
  }

  void _onCloseIncidentCaseEvent(
    CloseIncidentCaseEvent event,
    Emitter<SupervisorIncidentState> emit,
  ) {
    final updated = state.cases.map((c) {
      if (c.id == event.caseId) {
        return c.copyWith(status: IncidentStatus.closed);
      }
      return c;
    }).toList();

    emit(state.copyWith(
      cases: updated,
      notificationMessage: 'Case ${event.caseId} formally closed by Executive Supervisor.',
    ));
  }
}
