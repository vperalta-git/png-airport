import 'package:equatable/equatable.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

abstract class AirportsState extends Equatable {
  const AirportsState();
  @override
  List<Object?> get props => [];
}

class AirportsInitial extends AirportsState {}

class AirportsLoading extends AirportsState {}

class AirportsLoaded extends AirportsState {
  final List<Airport> airports;
  final Airport selectedAirport;
  final List<VehicleCategory> vehicleCategories;

  const AirportsLoaded({
    required this.airports,
    required this.selectedAirport,
    required this.vehicleCategories,
  });

  AirportsLoaded copyWith({
    List<Airport>? airports,
    Airport? selectedAirport,
    List<VehicleCategory>? vehicleCategories,
  }) {
    return AirportsLoaded(
      airports: airports ?? this.airports,
      selectedAirport: selectedAirport ?? this.selectedAirport,
      vehicleCategories: vehicleCategories ?? this.vehicleCategories,
    );
  }

  @override
  List<Object?> get props => [airports, selectedAirport, vehicleCategories];
}

class AirportsError extends AirportsState {
  final String message;
  const AirportsError(this.message);
  @override
  List<Object?> get props => [message];
}
