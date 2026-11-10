import 'package:equatable/equatable.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

abstract class AirportsEvent extends Equatable {
  const AirportsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAirports extends AirportsEvent {
  final bool forceRefresh;
  const LoadAirports({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class SelectAirport extends AirportsEvent {
  final Airport airport;
  const SelectAirport(this.airport);
  @override
  List<Object?> get props => [airport];
}
