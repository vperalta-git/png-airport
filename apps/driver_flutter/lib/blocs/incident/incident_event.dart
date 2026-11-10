import 'package:equatable/equatable.dart';

abstract class IncidentEvent extends Equatable {
  const IncidentEvent();
  @override
  List<Object?> get props => [];
}

class TriggerSosAlert extends IncidentEvent {
  final String missionId;
  final String locationDescription;
  const TriggerSosAlert({required this.missionId, required this.locationDescription});
  @override
  List<Object?> get props => [missionId, locationDescription];
}

class ReportFieldIncident extends IncidentEvent {
  final String missionId;
  final String severity; // 'LOW', 'MODERATE', 'CRITICAL'
  final String issueType; // 'Road Block', 'Gravel Slide', 'Mechanical', 'Security Threat'
  final String notes;
  const ReportFieldIncident({
    required this.missionId,
    required this.severity,
    required this.issueType,
    required this.notes,
  });
  @override
  List<Object?> get props => [missionId, severity, issueType, notes];
}
