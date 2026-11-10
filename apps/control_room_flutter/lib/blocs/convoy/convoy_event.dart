import 'package:equatable/equatable.dart';
import '../../models/convoy_unit.dart';

abstract class ConvoyEvent extends Equatable {
  const ConvoyEvent();

  @override
  List<Object?> get props => [];
}

class LoadConvoyFleet extends ConvoyEvent {
  const LoadConvoyFleet();
}

class UpdateUnitStatus extends ConvoyEvent {
  final String unitId;
  final ConvoyStatus newStatus;

  const UpdateUnitStatus({required this.unitId, required this.newStatus});

  @override
  List<Object?> get props => [unitId, newStatus];
}

class PingUnitRadio extends ConvoyEvent {
  final String unitId;

  const PingUnitRadio(this.unitId);

  @override
  List<Object?> get props => [unitId];
}

class FilterConvoyByStatus extends ConvoyEvent {
  final ConvoyStatus? statusFilter;

  const FilterConvoyByStatus(this.statusFilter);

  @override
  List<Object?> get props => [statusFilter];
}
