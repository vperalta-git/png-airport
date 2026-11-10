import 'package:equatable/equatable.dart';

abstract class FlightRadarEvent extends Equatable {
  const FlightRadarEvent();
  @override
  List<Object?> get props => [];
}

class LoadFlightRadar extends FlightRadarEvent {
  final bool forceRefresh;
  const LoadFlightRadar({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class FilterDirectionChanged extends FlightRadarEvent {
  final String direction; // 'all' | 'arrival' | 'departure'
  const FilterDirectionChanged(this.direction);
  @override
  List<Object?> get props => [direction];
}

class SearchQueryChanged extends FlightRadarEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class CarrierFilterChanged extends FlightRadarEvent {
  final String carrier; // 'all' | 'Air Niugini' | 'PNG Air'
  const CarrierFilterChanged(this.carrier);
  @override
  List<Object?> get props => [carrier];
}
