import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'airports_event.dart';
import 'airports_state.dart';

class AirportsBloc extends Bloc<AirportsEvent, AirportsState> {
  final AirportRepository repository;

  AirportsBloc({required this.repository}) : super(AirportsInitial()) {
    on<LoadAirports>(_onLoadAirports);
    on<SelectAirport>(_onSelectAirport);
  }

  Future<void> _onLoadAirports(
    LoadAirports event,
    Emitter<AirportsState> emit,
  ) async {
    emit(AirportsLoading());
    try {
      final airports = await repository.getAirports(forceRefresh: event.forceRefresh);
      final categories = await repository.getVehicleCategories();
      final selected = airports.isNotEmpty ? airports.first : const Airport(
        id: 1,
        name: "Nadzab Tomodachi International Airport",
        iataCode: "LAE",
        icaoCode: "AYNZ",
        city: "Lae",
        latitude: -6.5698,
        longitude: 146.7262,
        serviceRadiusKm: 60.0,
      );

      emit(AirportsLoaded(
        airports: airports,
        selectedAirport: selected,
        vehicleCategories: categories,
      ));
    } catch (e) {
      emit(AirportsError(e.toString()));
    }
  }

  void _onSelectAirport(
    SelectAirport event,
    Emitter<AirportsState> emit,
  ) {
    if (state is AirportsLoaded) {
      final current = state as AirportsLoaded;
      emit(current.copyWith(selectedAirport: event.airport));
    }
  }
}
