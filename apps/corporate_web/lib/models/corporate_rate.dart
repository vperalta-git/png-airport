import 'package:equatable/equatable.dart';

class CorporateRateItem extends Equatable {
  final String routeName;
  final String airport;
  final String destinationZone;
  final String vehicleType;
  final String securityLevel;
  final double contractedRatePgk;
  final String billingUnit;
  final String notes;

  const CorporateRateItem({
    required this.routeName,
    required this.airport,
    required this.destinationZone,
    required this.vehicleType,
    required this.securityLevel,
    required this.contractedRatePgk,
    this.billingUnit = 'Per Mission',
    this.notes = 'Includes 60 mins tarmac arrival wait time.',
  });

  @override
  List<Object?> get props => [routeName, vehicleType, securityLevel, contractedRatePgk];
}

