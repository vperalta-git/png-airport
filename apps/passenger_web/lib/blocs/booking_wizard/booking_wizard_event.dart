import 'package:equatable/equatable.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

abstract class BookingWizardEvent extends Equatable {
  const BookingWizardEvent();
  @override
  List<Object?> get props => [];
}

class StepChanged extends BookingWizardEvent {
  final int stepIndex;
  const StepChanged(this.stepIndex);
  @override
  List<Object?> get props => [stepIndex];
}

class TransferDirectionChanged extends BookingWizardEvent {
  final String direction; // 'arrival' | 'departure'
  const TransferDirectionChanged(this.direction);
  @override
  List<Object?> get props => [direction];
}

class AirportLocationSelected extends BookingWizardEvent {
  final Airport airport;
  final ServiceZone? zone;
  const AirportLocationSelected({required this.airport, this.zone});
  @override
  List<Object?> get props => [airport, zone];
}

class FlightInfoChanged extends BookingWizardEvent {
  final String flightNumber;
  final String flightTime;
  final String airline;
  const FlightInfoChanged({required this.flightNumber, required this.flightTime, required this.airline});
  @override
  List<Object?> get props => [flightNumber, flightTime, airline];
}

class LocationsChanged extends BookingWizardEvent {
  final String pickupLocation;
  final String dropoffLocation;
  const LocationsChanged({required this.pickupLocation, required this.dropoffLocation});
  @override
  List<Object?> get props => [pickupLocation, dropoffLocation];
}

class VehicleAndSecuritySelected extends BookingWizardEvent {
  final VehicleCategory vehicleCategory;
  final bool securityRequired;
  final bool meetGreetRequired;
  const VehicleAndSecuritySelected({
    required this.vehicleCategory,
    required this.securityRequired,
    required this.meetGreetRequired,
  });
  @override
  List<Object?> get props => [vehicleCategory, securityRequired, meetGreetRequired];
}

class PassengerManifestChanged extends BookingWizardEvent {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String specialInstructions;
  const PassengerManifestChanged({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.specialInstructions,
  });
  @override
  List<Object?> get props => [firstName, lastName, phone, email, specialInstructions];
}

class RequestQuotation extends BookingWizardEvent {}

class SubmitBookingRequest extends BookingWizardEvent {}

class ResetBookingWizard extends BookingWizardEvent {}
