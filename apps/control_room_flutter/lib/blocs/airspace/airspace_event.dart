import 'package:equatable/equatable.dart';

abstract class AirspaceEvent extends Equatable {
  const AirspaceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAirspaceData extends AirspaceEvent {
  final String airportIata;

  const LoadAirspaceData({this.airportIata = 'POM'});

  @override
  List<Object?> get props => [airportIata];
}

class FilterAirportChanged extends AirspaceEvent {
  final String airportIata;

  const FilterAirportChanged(this.airportIata);

  @override
  List<Object?> get props => [airportIata];
}

class RefreshAirspaceStream extends AirspaceEvent {
  const RefreshAirspaceStream();
}
