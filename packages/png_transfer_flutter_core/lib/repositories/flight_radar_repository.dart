import '../models/flight_radar.dart';
import '../services/flight_radar_service.dart';

class FlightRadarRepository {
  final FlightRadarService service;

  FlightRadarRepository({required this.service});

  Future<Map<String, dynamic>> getRadarSnapshot() async {
    return await service.fetchLiveRadarData();
  }

  Future<List<FlightRadarFlight>> getFlights({String? direction}) async {
    final snapshot = await service.fetchLiveRadarData();
    final arrivals = (snapshot['arrivals'] as List<dynamic>? ?? [])
        .map((f) => FlightRadarFlight.fromJson(f as Map<String, dynamic>, defaultType: 'arrival'))
        .toList();
    final departures = (snapshot['departures'] as List<dynamic>? ?? [])
        .map((f) => FlightRadarFlight.fromJson(f as Map<String, dynamic>, defaultType: 'departure'))
        .toList();

    if (direction == 'arrival') return arrivals;
    if (direction == 'departure') return departures;
    return [...arrivals, ...departures];
  }

  Future<MetarWeather> getWeather() async {
    final snapshot = await service.fetchLiveRadarData();
    final airportRaw = snapshot['airport'] as Map<String, dynamic>? ?? {};
    final metarRaw = airportRaw['metar'] as Map<String, dynamic>? ?? {};
    return MetarWeather.fromJson(metarRaw);
  }
}
