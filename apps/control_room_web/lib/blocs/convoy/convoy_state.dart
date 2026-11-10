import 'package:equatable/equatable.dart';
import '../../models/convoy_unit.dart';

enum ConvoyFleetStatus { initial, loading, loaded, failure }

class ConvoyState extends Equatable {
  final ConvoyFleetStatus status;
  final List<ConvoyUnit> allUnits;
  final ConvoyStatus? activeFilter;
  final String? lastPingedUnitCallsign;
  final String? message;

  const ConvoyState({
    this.status = ConvoyFleetStatus.initial,
    this.allUnits = const [],
    this.activeFilter,
    this.lastPingedUnitCallsign,
    this.message,
  });

  List<ConvoyUnit> get filteredUnits {
    if (activeFilter == null) return allUnits;
    return allUnits.where((u) => u.status == activeFilter).toList();
  }

  int get totalInTransit =>
      allUnits.where((u) => u.status == ConvoyStatus.inTransit).length;

  int get totalAtAirport =>
      allUnits.where((u) => u.status == ConvoyStatus.stagedAtAirport).length;

  int get totalDistress =>
      allUnits.where((u) => u.status == ConvoyStatus.distress).length;

  ConvoyState copyWith({
    ConvoyFleetStatus? status,
    List<ConvoyUnit>? allUnits,
    ConvoyStatus? activeFilter,
    bool clearFilter = false,
    String? lastPingedUnitCallsign,
    String? message,
  }) {
    return ConvoyState(
      status: status ?? this.status,
      allUnits: allUnits ?? this.allUnits,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      lastPingedUnitCallsign: lastPingedUnitCallsign ?? this.lastPingedUnitCallsign,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allUnits,
        activeFilter,
        lastPingedUnitCallsign,
        message,
      ];
}
