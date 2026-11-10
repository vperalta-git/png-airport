import 'package:equatable/equatable.dart';

abstract class IncidentState extends Equatable {
  const IncidentState();
  @override
  List<Object?> get props => [];
}

class IncidentInitial extends IncidentState {}

class IncidentAlertActive extends IncidentState {
  final String alertId;
  final String missionId;
  final String severity;
  final String summary;
  final DateTime timestamp;

  const IncidentAlertActive({
    required this.alertId,
    required this.missionId,
    required this.severity,
    required this.summary,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [alertId, missionId, severity, summary];
}
