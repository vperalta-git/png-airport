import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/corporate_booking.dart';
import '../services/corporate_firestore_service.dart';
import 'corporate_event.dart';
import 'corporate_state.dart';

class _CorporateBookingsUpdated extends CorporateEvent {
  final List<CorporateBooking> bookings;
  const _CorporateBookingsUpdated(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class CorporateBloc extends Bloc<CorporateEvent, CorporateState> {
  final CorporateFirestoreService firestoreService;
  StreamSubscription<List<CorporateBooking>>? _bookingsSubscription;

  CorporateBloc({
    CorporateFirestoreService? firestoreService,
  })  : firestoreService = firestoreService ?? CorporateFirestoreService(),
        super(const CorporateState()) {
    on<LoadCorporateData>(_onLoadCorporateData);
    on<CreateCorporateTransfer>(_onCreateCorporateTransfer);
    on<ApproveCorporateBooking>(_onApproveCorporateBooking);
    on<RegisterNewPassenger>(_onRegisterNewPassenger);
    on<_CorporateBookingsUpdated>(_onCorporateBookingsUpdated);
  }

  Future<void> _onLoadCorporateData(
    LoadCorporateData event,
    Emitter<CorporateState> emit,
  ) async {
    emit(state.copyWith(status: CorporateLoadingStatus.loading));

    emit(state.copyWith(
      status: CorporateLoadingStatus.loaded,
      passengers: CorporateFirestoreService.defaultPassengers,
      invoices: CorporateFirestoreService.defaultInvoices,
      rates: CorporateFirestoreService.defaultRates,
      bookings: CorporateFirestoreService.defaultBookings,
    ));

    await _bookingsSubscription?.cancel();
    _bookingsSubscription = firestoreService.streamCorporateBookings().listen(
      (bookings) {
        add(_CorporateBookingsUpdated(bookings));
      },
      onError: (_) {
        // Fallback to default in state
      },
    );
  }

  void _onCorporateBookingsUpdated(
    _CorporateBookingsUpdated event,
    Emitter<CorporateState> emit,
  ) {
    emit(state.copyWith(bookings: event.bookings));
  }

  Future<void> _onCreateCorporateTransfer(
    CreateCorporateTransfer event,
    Emitter<CorporateState> emit,
  ) async {
    try {
      final newBooking = await firestoreService.createCorporateBooking(
        leadPassenger: event.leadPassenger,
        passengerCount: event.passengerCount,
        flightNumber: event.flightNumber,
        airportName: event.airportName,
        pickupLocation: event.pickupLocation,
        destination: event.destination,
        scheduledPickup: event.scheduledPickup,
        vehicleType: event.vehicleType,
        escortLevel: event.escortLevel,
        poNumber: event.poNumber,
        costCenter: event.costCenter,
        farePgk: event.farePgk,
        notes: event.notes,
      );

      final updatedBookings = [newBooking, ...state.bookings];
      final newBilled = state.billedThisMonthPgk + event.farePgk;

      emit(state.copyWith(
        bookings: updatedBookings,
        billedThisMonthPgk: newBilled,
        lastNotification:
            'Transfer ${newBooking.refNumber} dispatched under PO ${event.poNumber} (${event.farePgk.toStringAsFixed(0)} PGK).',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to create corporate transfer: $e'));
    }
  }

  Future<void> _onApproveCorporateBooking(
    ApproveCorporateBooking event,
    Emitter<CorporateState> emit,
  ) async {
    try {
      await firestoreService.updateBookingApproval(
        bookingId: event.bookingId,
        isApproved: event.isApproved,
        approverName: event.approverName,
      );

      final updatedBookings = state.bookings.map((b) {
        if (b.id == event.bookingId || b.refNumber == event.bookingId) {
          return b.copyWith(
            status: event.isApproved
                ? CorporateBookingStatus.approved
                : CorporateBookingStatus.cancelled,
            approvedBy: event.approverName,
            approvedAt: DateTime.now(),
          );
        }
        return b;
      }).toList();

      emit(state.copyWith(
        bookings: updatedBookings,
        lastNotification:
            'Transfer ${event.bookingId} has been ${event.isApproved ? "APPROVED" : "REJECTED"} by ${event.approverName}.',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update approval: $e'));
    }
  }

  void _onRegisterNewPassenger(
    RegisterNewPassenger event,
    Emitter<CorporateState> emit,
  ) {
    final updatedPassengers = [...state.passengers, event.passenger];
    emit(state.copyWith(
      passengers: updatedPassengers,
      lastNotification:
          'Registered executive traveler: ${event.passenger.fullName} (${event.passenger.department}).',
    ));
  }

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }
}

