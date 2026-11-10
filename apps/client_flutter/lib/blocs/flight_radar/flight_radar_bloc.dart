import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'flight_radar_event.dart';
import 'flight_radar_state.dart';

class FlightRadarBloc extends Bloc<FlightRadarEvent, FlightRadarState> {
  final FlightRadarRepository repository;

  FlightRadarBloc({required this.repository}) : super(FlightRadarInitial()) {
    on<LoadFlightRadar>(_onLoadFlightRadar);
    on<FilterDirectionChanged>(_onFilterDirectionChanged);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<CarrierFilterChanged>(_onCarrierFilterChanged);
  }

  Future<void> _onLoadFlightRadar(
    LoadFlightRadar event,
    Emitter<FlightRadarState> emit,
  ) async {
    if (state is! FlightRadarLoaded) {
      emit(FlightRadarLoading());
    }

    try {
      final flights = await repository.getFlights();
      final weather = await repository.getWeather();

      final currentDirection = state is FlightRadarLoaded
          ? (state as FlightRadarLoaded).activeDirection
          : 'arrival';
      final currentCarrier = state is FlightRadarLoaded
          ? (state as FlightRadarLoaded).activeCarrier
          : 'all';
      final currentQuery = state is FlightRadarLoaded
          ? (state as FlightRadarLoaded).searchQuery
          : '';

      final filtered = _applyFilters(
        flights,
        direction: currentDirection,
        carrier: currentCarrier,
        query: currentQuery,
      );

      emit(FlightRadarLoaded(
        allFlights: flights,
        filteredFlights: filtered,
        weather: weather,
        activeDirection: currentDirection,
        activeCarrier: currentCarrier,
        searchQuery: currentQuery,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(FlightRadarError(e.toString()));
    }
  }

  void _onFilterDirectionChanged(
    FilterDirectionChanged event,
    Emitter<FlightRadarState> emit,
  ) {
    if (state is FlightRadarLoaded) {
      final current = state as FlightRadarLoaded;
      final filtered = _applyFilters(
        current.allFlights,
        direction: event.direction,
        carrier: current.activeCarrier,
        query: current.searchQuery,
      );
      emit(current.copyWith(
        activeDirection: event.direction,
        filteredFlights: filtered,
      ));
    }
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<FlightRadarState> emit,
  ) {
    if (state is FlightRadarLoaded) {
      final current = state as FlightRadarLoaded;
      final filtered = _applyFilters(
        current.allFlights,
        direction: current.activeDirection,
        carrier: current.activeCarrier,
        query: event.query,
      );
      emit(current.copyWith(
        searchQuery: event.query,
        filteredFlights: filtered,
      ));
    }
  }

  void _onCarrierFilterChanged(
    CarrierFilterChanged event,
    Emitter<FlightRadarState> emit,
  ) {
    if (state is FlightRadarLoaded) {
      final current = state as FlightRadarLoaded;
      final filtered = _applyFilters(
        current.allFlights,
        direction: current.activeDirection,
        carrier: event.carrier,
        query: current.searchQuery,
      );
      emit(current.copyWith(
        activeCarrier: event.carrier,
        filteredFlights: filtered,
      ));
    }
  }

  List<FlightRadarFlight> _applyFilters(
    List<FlightRadarFlight> flights, {
    required String direction,
    required String carrier,
    required String query,
  }) {
    return flights.where((f) {
      // Direction filter
      if (direction != 'all' && f.type != direction) {
        return false;
      }
      // Carrier filter
      if (carrier != 'all') {
        if (!f.carrier.toLowerCase().contains(carrier.toLowerCase())) {
          return false;
        }
      }
      // Query filter
      if (query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final matchCode = f.code.toLowerCase().contains(q);
        final matchCarrier = f.carrier.toLowerCase().contains(q);
        final matchOrigin = f.originCity.toLowerCase().contains(q) || f.originCode.toLowerCase().contains(q);
        final matchDest = f.destCity.toLowerCase().contains(q) || f.destCode.toLowerCase().contains(q);
        if (!matchCode && !matchCarrier && !matchOrigin && !matchDest) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
