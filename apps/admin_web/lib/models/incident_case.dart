import 'package:equatable/equatable.dart';

enum IncidentStatus { underReview, rpngcReportFiled, insuranceSubmitted, closed }

class IncidentCase extends Equatable {
  final String id;
  final String missionRef;
  final String unitCallsign;
  final String driverName;
  final String incidentType; // e.g. "Civil Unrest Roadblock", "Gravel Slide", "Attempted Hijack"
  final String location;
  final DateTime occurrenceTime;
  final IncidentStatus status;
  final String initialSummary;
  final String? policeReportNumber;
  final String? supervisorFindings;
  final String? correctiveAction;

  const IncidentCase({
    required this.id,
    required this.missionRef,
    required this.unitCallsign,
    required this.driverName,
    required this.incidentType,
    required this.location,
    required this.occurrenceTime,
    required this.status,
    required this.initialSummary,
    this.policeReportNumber,
    this.supervisorFindings,
    this.correctiveAction,
  });

  IncidentCase copyWith({
    String? id,
    String? missionRef,
    String? unitCallsign,
    String? driverName,
    String? incidentType,
    String? location,
    DateTime? occurrenceTime,
    IncidentStatus? status,
    String? initialSummary,
    String? policeReportNumber,
    String? supervisorFindings,
    String? correctiveAction,
  }) {
    return IncidentCase(
      id: id ?? this.id,
      missionRef: missionRef ?? this.missionRef,
      unitCallsign: unitCallsign ?? this.unitCallsign,
      driverName: driverName ?? this.driverName,
      incidentType: incidentType ?? this.incidentType,
      location: location ?? this.location,
      occurrenceTime: occurrenceTime ?? this.occurrenceTime,
      status: status ?? this.status,
      initialSummary: initialSummary ?? this.initialSummary,
      policeReportNumber: policeReportNumber ?? this.policeReportNumber,
      supervisorFindings: supervisorFindings ?? this.supervisorFindings,
      correctiveAction: correctiveAction ?? this.correctiveAction,
    );
  }

  @override
  List<Object?> get props => [
        id,
        missionRef,
        unitCallsign,
        driverName,
        incidentType,
        location,
        occurrenceTime,
        status,
        initialSummary,
        policeReportNumber,
        supervisorFindings,
        correctiveAction,
      ];
}
