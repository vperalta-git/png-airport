import 'package:equatable/equatable.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

abstract class FlightRadarState extends Equatable {
  const FlightRadarState();
  @override
  List<Object?> get props => [];
}

class FlightRadarInitial extends FlightRadarState {}

class FlightRadarLoading extends FlightRadarState {}

class FlightRadarLoaded extends FlightRadarState {
  final List<FlightRadarFlight> allFlights;
  final List<FlightRadarFlight> filteredFlights;
  final MetarWeather weather;
  final String activeDirection;
  final String activeCarrier;
  final String searchQuery;
  final DateTime lastUpdated;

  const FlightRadarLoaded({
    required this.allFlights,
    required this.filteredFlights,
    required this.weather,
    this.activeDirection = 'arrival',
    this.activeCarrier = 'all',
    this.searchQuery = '',
    required this.lastUpdated,
  });

  FlightRadarLoaded copyWith({
    List<FlightRadarFlight>? allFlights,
    List<FlightRadarFlight>? filteredFlights,
    MetarWeather? weather,
    String? activeDirection,
    String? activeCarrier,
    String? searchQuery,
    DateTime? lastUpdated,
  }) {
    return FlightRadarLoaded(
      allFlights: allFlights ?? this.allFlights,
      filteredFlights: filteredFlights ?? this.filteredFlights,
      weather: weather ?? this.weather,
      activeDirection: activeDirection ?? this.activeDirection,
      activeCarrier: activeCarrier ?? this.activeCarrier,
      searchQuery: searchQuery ?? this.searchQuery,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        allFlights,
        filteredFlights,
        weather,
        activeDirection,
        activeCarrier,
        searchQuery,
        lastUpdated,
      ];
}

class FlightRadarError extends FlightRadarState {
  final String message;
  const FlightRadarError(this.message);
  @override
  List<Object?> get props => [message];
}
