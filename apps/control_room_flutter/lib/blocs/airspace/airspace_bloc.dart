import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/repositories/flight_radar_repository.dart';
import 'airspace_event.dart';
import 'airspace_state.dart';

class AirspaceBloc extends Bloc<AirspaceEvent, AirspaceState> {
  final FlightRadarRepository flightRadarRepository;

  AirspaceBloc({required this.flightRadarRepository})
      : super(AirspaceState(lastUpdated: DateTime.now())) {
    on<LoadAirspaceData>(_onLoadAirspaceData);
    on<FilterAirportChanged>(_onFilterAirportChanged);
    on<RefreshAirspaceStream>(_onRefreshAirspaceStream);
  }

  Future<void> _onLoadAirspaceData(
    LoadAirspaceData event,
    Emitter<AirspaceState> emit,
  ) async {
    emit(state.copyWith(
      status: AirspaceStatus.loading,
      activeAirportIata: event.airportIata,
    ));

    try {
      final flights = await flightRadarRepository.getFlights();
      final weather = await flightRadarRepository.getWeather();

      emit(state.copyWith(
        status: AirspaceStatus.loaded,
        flights: flights,
        weather: weather,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AirspaceStatus.failure,
        errorMessage: 'Unable to stream live airspace: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFilterAirportChanged(
    FilterAirportChanged event,
    Emitter<AirspaceState> emit,
  ) async {
    add(LoadAirspaceData(airportIata: event.airportIata));
  }

  Future<void> _onRefreshAirspaceStream(
    RefreshAirspaceStream event,
    Emitter<AirspaceState> emit,
  ) async {
    add(LoadAirspaceData(airportIata: state.activeAirportIata));
  }
}
