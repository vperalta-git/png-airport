import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../services/firestore_booking_service.dart';
import 'booking_wizard_event.dart';
import 'booking_wizard_state.dart';

class BookingWizardBloc extends Bloc<BookingWizardEvent, BookingWizardState> {
  final BookingRepository repository;
  final FirestoreBookingService? firestoreService;

  BookingWizardBloc({
    required this.repository,
    this.firestoreService,
  }) : super(const BookingWizardState()) {
    on<StepChanged>(_onStepChanged);
    on<TransferDirectionChanged>(_onTransferDirectionChanged);
    on<AirportLocationSelected>(_onAirportLocationSelected);
    on<FlightInfoChanged>(_onFlightInfoChanged);
    on<LocationsChanged>(_onLocationsChanged);
    on<VehicleAndSecuritySelected>(_onVehicleAndSecuritySelected);
    on<PassengerManifestChanged>(_onPassengerManifestChanged);
    on<RequestQuotation>(_onRequestQuotation);
    on<SubmitBookingRequest>(_onSubmitBookingRequest);
    on<ResetBookingWizard>(_onResetBookingWizard);
  }

  void _onStepChanged(StepChanged event, Emitter<BookingWizardState> emit) {
    emit(state.copyWith(currentStep: event.stepIndex, errorMessage: null));
    if (event.stepIndex == 3) {
      add(RequestQuotation());
    }
  }

  void _onTransferDirectionChanged(
    TransferDirectionChanged event,
    Emitter<BookingWizardState> emit,
  ) {
    if (event.direction == 'arrival') {
      emit(state.copyWith(
        transferDirection: event.direction,
        pickupLocation: "Nadzab Tomodachi Int'l Airport (Arrival Gate)",
        dropoffLocation: "Lae International Hotel, Morobe",
      ));
    } else {
      emit(state.copyWith(
        transferDirection: event.direction,
        pickupLocation: "Lae International Hotel, Morobe",
        dropoffLocation: "Nadzab Tomodachi Int'l Airport (Departure Terminal)",
      ));
    }
  }

  void _onAirportLocationSelected(
    AirportLocationSelected event,
    Emitter<BookingWizardState> emit,
  ) {
    emit(state.copyWith(
      airport: event.airport,
      destinationZone: event.zone,
    ));
  }

  void _onFlightInfoChanged(
    FlightInfoChanged event,
    Emitter<BookingWizardState> emit,
  ) {
    emit(state.copyWith(
      flightNumber: event.flightNumber,
      flightTime: event.flightTime,
      flightAirline: event.airline,
    ));
  }

  void _onLocationsChanged(
    LocationsChanged event,
    Emitter<BookingWizardState> emit,
  ) {
    emit(state.copyWith(
      pickupLocation: event.pickupLocation,
      dropoffLocation: event.dropoffLocation,
    ));
  }

  void _onVehicleAndSecuritySelected(
    VehicleAndSecuritySelected event,
    Emitter<BookingWizardState> emit,
  ) {
    emit(state.copyWith(
      vehicleCategory: event.vehicleCategory,
      securityRequired: event.securityRequired,
      meetGreetRequired: event.meetGreetRequired,
    ));
  }

  void _onPassengerManifestChanged(
    PassengerManifestChanged event,
    Emitter<BookingWizardState> emit,
  ) {
    emit(state.copyWith(
      passengerFirstName: event.firstName,
      passengerLastName: event.lastName,
      passengerPhone: event.phone,
      passengerEmail: event.email,
      specialInstructions: event.specialInstructions,
    ));
  }

  Future<void> _onRequestQuotation(
    RequestQuotation event,
    Emitter<BookingWizardState> emit,
  ) async {
    emit(state.copyWith(isQuoting: true));
    try {
      final req = QuoteRequest(
        airportId: state.airport?.id ?? 1,
        zoneId: state.destinationZone?.id,
        vehicleCategoryId: state.vehicleCategory?.id,
        distanceKm: 18.0,
        securityRequired: state.securityRequired,
        meetGreetRequired: state.meetGreetRequired,
      );
      final quote = await repository.calculateQuote(req);
      emit(state.copyWith(quote: quote, isQuoting: false));
    } catch (e) {
      emit(state.copyWith(isQuoting: false, errorMessage: 'Failed to calculate quote: $e'));
    }
  }

  Future<void> _onSubmitBookingRequest(
    SubmitBookingRequest event,
    Emitter<BookingWizardState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeStr = state.flightTime.contains(':') ? state.flightTime : '14:30';

      final payload = {
        'airport_id': state.airport?.id ?? 1,
        'pickup_location': state.pickupLocation,
        'destination': state.dropoffLocation,
        'pickup_datetime': '$dateStr $timeStr:00',
        'flight_number': state.flightNumber,
        'flight_airline': state.flightAirline,
        'vehicle_category_id': state.vehicleCategory?.id ?? 2,
        'security_required': state.securityRequired,
        'meet_greet_required': state.meetGreetRequired,
        'total_fare': state.quote?.total ?? 580.0,
        'passengers': [
          {
            'first_name': state.passengerFirstName,
            'last_name': state.passengerLastName,
            'mobile': state.passengerPhone,
            'email': state.passengerEmail,
            'passenger_type': state.securityRequired ? 'vip' : 'primary',
          }
        ],
      };

      final Booking booking;
      if (firestoreService != null) {
        booking = await firestoreService!.createBookingInFirestore(payload);
      } else {
        booking = await repository.createBooking(payload);
      }
      emit(state.copyWith(isSubmitting: false, createdBooking: booking));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: 'Failed to confirm booking: $e'));
    }
  }

  void _onResetBookingWizard(
    ResetBookingWizard event,
    Emitter<BookingWizardState> emit,
  ) {
    emit(const BookingWizardState());
  }
}
