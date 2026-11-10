import 'package:equatable/equatable.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

class BookingWizardState extends Equatable {
  final int currentStep; // 0: Route & Flight, 1: Vehicle & Security, 2: Passenger Details, 3: Review & Quote
  final String transferDirection; // 'arrival' | 'departure'
  final Airport? airport;
  final ServiceZone? destinationZone;
  final String pickupLocation;
  final String dropoffLocation;
  final String flightNumber;
  final String flightTime;
  final String flightAirline;
  final VehicleCategory? vehicleCategory;
  final bool securityRequired;
  final bool meetGreetRequired;
  final String passengerFirstName;
  final String passengerLastName;
  final String passengerPhone;
  final String passengerEmail;
  final String specialInstructions;
  final QuoteResponse? quote;
  final bool isQuoting;
  final bool isSubmitting;
  final Booking? createdBooking;
  final String? errorMessage;

  const BookingWizardState({
    this.currentStep = 0,
    this.transferDirection = 'arrival',
    this.airport,
    this.destinationZone,
    this.pickupLocation = "Nadzab Tomodachi Int'l Airport (Terminal 1 Arrival Gate)",
    this.dropoffLocation = "Lae International Hotel, Morobe",
    this.flightNumber = "PX102",
    this.flightTime = "14:30",
    this.flightAirline = "Air Niugini",
    this.vehicleCategory,
    this.securityRequired = true,
    this.meetGreetRequired = true,
    this.passengerFirstName = "David",
    this.passengerLastName = "Vance",
    this.passengerPhone = "+675 7123 4567",
    this.passengerEmail = "david.vance@bhp.com",
    this.specialInstructions = "VIP Armed escort meet & greet on tarmac arrival corridor.",
    this.quote,
    this.isQuoting = false,
    this.isSubmitting = false,
    this.createdBooking,
    this.errorMessage,
  });

  BookingWizardState copyWith({
    int? currentStep,
    String? transferDirection,
    Airport? airport,
    ServiceZone? destinationZone,
    String? pickupLocation,
    String? dropoffLocation,
    String? flightNumber,
    String? flightTime,
    String? flightAirline,
    VehicleCategory? vehicleCategory,
    bool? securityRequired,
    bool? meetGreetRequired,
    String? passengerFirstName,
    String? passengerLastName,
    String? passengerPhone,
    String? passengerEmail,
    String? specialInstructions,
    QuoteResponse? quote,
    bool? isQuoting,
    bool? isSubmitting,
    Booking? createdBooking,
    String? errorMessage,
  }) {
    return BookingWizardState(
      currentStep: currentStep ?? this.currentStep,
      transferDirection: transferDirection ?? this.transferDirection,
      airport: airport ?? this.airport,
      destinationZone: destinationZone ?? this.destinationZone,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      flightNumber: flightNumber ?? this.flightNumber,
      flightTime: flightTime ?? this.flightTime,
      flightAirline: flightAirline ?? this.flightAirline,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      securityRequired: securityRequired ?? this.securityRequired,
      meetGreetRequired: meetGreetRequired ?? this.meetGreetRequired,
      passengerFirstName: passengerFirstName ?? this.passengerFirstName,
      passengerLastName: passengerLastName ?? this.passengerLastName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerEmail: passengerEmail ?? this.passengerEmail,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      quote: quote ?? this.quote,
      isQuoting: isQuoting ?? this.isQuoting,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdBooking: createdBooking ?? this.createdBooking,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        transferDirection,
        airport,
        destinationZone,
        pickupLocation,
        dropoffLocation,
        flightNumber,
        vehicleCategory,
        securityRequired,
        meetGreetRequired,
        quote,
        isQuoting,
        isSubmitting,
        createdBooking,
        errorMessage,
      ];
}
