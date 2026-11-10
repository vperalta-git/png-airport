import 'package:equatable/equatable.dart';

abstract class DispatchEvent extends Equatable {
  const DispatchEvent();

  @override
  List<Object?> get props => [];
}

class LoadDispatchQueue extends DispatchEvent {
  const LoadDispatchQueue();
}

class AssignAndDispatchJob extends DispatchEvent {
  final String jobId;
  final String driverId;
  final String driverName;
  final String vehicleCallsign;

  const AssignAndDispatchJob({
    required this.jobId,
    required this.driverId,
    required this.driverName,
    required this.vehicleCallsign,
  });

  @override
  List<Object?> get props => [jobId, driverId, driverName, vehicleCallsign];
}
