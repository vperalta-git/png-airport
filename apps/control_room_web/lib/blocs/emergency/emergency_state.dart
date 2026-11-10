import 'package:equatable/equatable.dart';
import '../../models/sos_alert.dart';

enum EmergencyStatus { normal, hasActiveAlerts, failure }

class EmergencyState extends Equatable {
  final EmergencyStatus status;
  final List<SosAlert> alerts;
  final String? activeBroadcastMessage;

  const EmergencyState({
    this.status = EmergencyStatus.normal,
    this.alerts = const [],
    this.activeBroadcastMessage,
  });

  int get unacknowledgedCount =>
      alerts.where((a) => a.status == AlertStatus.activeUnacknowledged).length;

  int get underResponseCount =>
      alerts.where((a) => a.status == AlertStatus.underResponse).length;

  EmergencyState copyWith({
    EmergencyStatus? status,
    List<SosAlert>? alerts,
    String? activeBroadcastMessage,
  }) {
    return EmergencyState(
      status: status ?? this.status,
      alerts: alerts ?? this.alerts,
      activeBroadcastMessage:
          activeBroadcastMessage ?? this.activeBroadcastMessage,
    );
  }

  @override
  List<Object?> get props => [status, alerts, activeBroadcastMessage];
}
