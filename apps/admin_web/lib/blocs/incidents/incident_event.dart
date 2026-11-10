import 'package:equatable/equatable.dart';

abstract class SupervisorIncidentEvent extends Equatable {
  const SupervisorIncidentEvent();

  @override
  List<Object?> get props => [];
}

class LoadSupervisorIncidents extends SupervisorIncidentEvent {
  const LoadSupervisorIncidents();
}

class UpdateIncidentInvestigation extends SupervisorIncidentEvent {
  final String caseId;
  final String policeReportNumber;
  final String supervisorFindings;
  final String correctiveAction;

  const UpdateIncidentInvestigation({
    required this.caseId,
    required this.policeReportNumber,
    required this.supervisorFindings,
    required this.correctiveAction,
  });

  @override
  List<Object?> get props => [
        caseId,
        policeReportNumber,
        supervisorFindings,
        correctiveAction,
      ];
}

class CloseIncidentCaseEvent extends SupervisorIncidentEvent {
  final String caseId;

  const CloseIncidentCaseEvent(this.caseId);

  @override
  List<Object?> get props => [caseId];
}
