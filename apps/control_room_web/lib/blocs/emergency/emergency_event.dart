import 'package:equatable/equatable.dart';
import '../../models/sos_alert.dart';

abstract class EmergencyEvent extends Equatable {
  const EmergencyEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmergencyAlerts extends EmergencyEvent {
  const LoadEmergencyAlerts();
}

class AcknowledgeAlert extends EmergencyEvent {
  final String alertId;
  final String officerName;

  const AcknowledgeAlert({required this.alertId, required this.officerName});

  @override
  List<Object?> get props => [alertId, officerName];
}

class DispatchQrfSupport extends EmergencyEvent {
  final String alertId;
  final String qrfUnitCallsign;
  final String instructions;

  const DispatchQrfSupport({
    required this.alertId,
    required this.qrfUnitCallsign,
    required this.instructions,
  });

  @override
  List<Object?> get props => [alertId, qrfUnitCallsign, instructions];
}

class ResolveAlert extends EmergencyEvent {
  final String alertId;
  final String resolutionReport;

  const ResolveAlert({
    required this.alertId,
    required this.resolutionReport,
  });

  @override
  List<Object?> get props => [alertId, resolutionReport];
}

class TriggerSimulatedDistress extends EmergencyEvent {
  final SosAlert alert;

  const TriggerSimulatedDistress(this.alert);

  @override
  List<Object?> get props => [alert];
}
