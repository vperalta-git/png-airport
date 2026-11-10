import 'package:equatable/equatable.dart';

class RegionalMetric extends Equatable {
  final String hubName; // e.g. "Port Moresby (POM)"
  final int activeMissions;
  final double revenuePgk;
  final double onTimeRate;

  const RegionalMetric({
    required this.hubName,
    required this.activeMissions,
    required this.revenuePgk,
    required this.onTimeRate,
  });

  @override
  List<Object?> get props => [hubName, activeMissions, revenuePgk, onTimeRate];
}

class SupervisorMetrics extends Equatable {
  final double dailyRevenuePgk;
  final double mtdRevenuePgk;
  final int totalMissionsToday;
  final int completedMissionsToday;
  final double onTimePerformanceRate;
  final int activeVehicles;
  final int totalFleet;
  final int armoredVehiclesInField;
  final int activeIncidentsCount;
  final List<RegionalMetric> regionalMetrics;

  const SupervisorMetrics({
    required this.dailyRevenuePgk,
    required this.mtdRevenuePgk,
    required this.totalMissionsToday,
    required this.completedMissionsToday,
    required this.onTimePerformanceRate,
    required this.activeVehicles,
    required this.totalFleet,
    required this.armoredVehiclesInField,
    required this.activeIncidentsCount,
    required this.regionalMetrics,
  });

  @override
  List<Object?> get props => [
        dailyRevenuePgk,
        mtdRevenuePgk,
        totalMissionsToday,
        completedMissionsToday,
        onTimePerformanceRate,
        activeVehicles,
        totalFleet,
        armoredVehiclesInField,
        activeIncidentsCount,
        regionalMetrics,
      ];
}
