import 'package:equatable/equatable.dart';

abstract class DutyEvent extends Equatable {
  const DutyEvent();
  @override
  List<Object?> get props => [];
}

class ToggleDutyStatus extends DutyEvent {}

class VehicleAssigned extends DutyEvent {
  final String vehicleName;
  const VehicleAssigned(this.vehicleName);
  @override
  List<Object?> get props => [vehicleName];
}
