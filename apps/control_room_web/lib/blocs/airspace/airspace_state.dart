import 'package:equatable/equatable.dart';
import 'package:png_transfer_flutter_core/models/flight_radar.dart';

enum AirspaceStatus { initial, loading, loaded, failure }

class AirspaceState extends Equatable {
  final AirspaceStatus status;
  final String activeAirportIata;
  final List<FlightRadarFlight> flights;
  final MetarWeather? weather;
  final String? errorMessage;
  final DateTime lastUpdated;

  const AirspaceState({
    this.status = AirspaceStatus.initial,
    this.activeAirportIata = 'POM',
    this.flights = const [],
    this.weather,
    this.errorMessage,
    required this.lastUpdated,
  });

  AirspaceState copyWith({
    AirspaceStatus? status,
    String? activeAirportIata,
    List<FlightRadarFlight>? flights,
    MetarWeather? weather,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return AirspaceState(
      status: status ?? this.status,
      activeAirportIata: activeAirportIata ?? this.activeAirportIata,
      flights: flights ?? this.flights,
      weather: weather ?? this.weather,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeAirportIata,
        flights,
        weather,
        errorMessage,
        lastUpdated,
      ];
}
