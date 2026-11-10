import 'package:equatable/equatable.dart';

enum AlertSeverity {
  p1AmbushHijack,
  p2RoadblockCivil,
  p3BreakdownAccident,
  p4WeatherClosure,
}

enum AlertStatus { activeUnacknowledged, underResponse, resolved }

class SosAlert extends Equatable {
  final String id;
  final String unitCallsign;
  final String driverName;
  final String locationDesc;
  final String latitude;
  final String longitude;
  final AlertSeverity severity;
  final AlertStatus status;
  final String message;
  final DateTime timestamp;
  final String? responseNotes;

  const SosAlert({
    required this.id,
    required this.unitCallsign,
    required this.driverName,
    required this.locationDesc,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.status,
    required this.message,
    required this.timestamp,
    this.responseNotes,
  });

  SosAlert copyWith({
    String? id,
    String? unitCallsign,
    String? driverName,
    String? locationDesc,
    String? latitude,
    String? longitude,
    AlertSeverity? severity,
    AlertStatus? status,
    String? message,
    DateTime? timestamp,
    String? responseNotes,
  }) {
    return SosAlert(
      id: id ?? this.id,
      unitCallsign: unitCallsign ?? this.unitCallsign,
      driverName: driverName ?? this.driverName,
      locationDesc: locationDesc ?? this.locationDesc,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      responseNotes: responseNotes ?? this.responseNotes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        unitCallsign,
        driverName,
        locationDesc,
        latitude,
        longitude,
        severity,
        status,
        message,
        timestamp,
        responseNotes,
      ];
}
