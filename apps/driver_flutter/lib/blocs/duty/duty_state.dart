import 'package:equatable/equatable.dart';

class DutyState extends Equatable {
  final bool isOnDuty;
  final String callsign;
  final String driverName;
  final String assignedVehicle;
  final String weaponAuthorization;
  final DateTime shiftStartTime;

  const DutyState({
    this.isOnDuty = true,
    this.callsign = 'ECHO-04 (VIP ESCORT)',
    this.driverName = 'Officer John K. & Armed Escort Team',
    this.assignedVehicle = 'Land Cruiser #04 (Armored 4WD)',
    this.weaponAuthorization = 'PNG RPNGC Level-2 Armed Clearance',
    required this.shiftStartTime,
  });

  DutyState copyWith({
    bool? isOnDuty,
    String? callsign,
    String? driverName,
    String? assignedVehicle,
    String? weaponAuthorization,
  }) {
    return DutyState(
      isOnDuty: isOnDuty ?? this.isOnDuty,
      callsign: callsign ?? this.callsign,
      driverName: driverName ?? this.driverName,
      assignedVehicle: assignedVehicle ?? this.assignedVehicle,
      weaponAuthorization: weaponAuthorization ?? this.weaponAuthorization,
      shiftStartTime: shiftStartTime,
    );
  }

  @override
  List<Object?> get props => [isOnDuty, callsign, assignedVehicle];
}
