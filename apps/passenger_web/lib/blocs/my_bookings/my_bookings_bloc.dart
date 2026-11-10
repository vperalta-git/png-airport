import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../services/firestore_booking_service.dart';
import 'my_bookings_event.dart';
import 'my_bookings_state.dart';

class MyBookingsBloc extends Bloc<MyBookingsEvent, MyBookingsState> {
  final BookingRepository repository;
  final FirestoreBookingService? firestoreService;
  StreamSubscription<List<Booking>>? _firestoreSubscription;

  MyBookingsBloc({
    required this.repository,
    this.firestoreService,
  }) : super(MyBookingsInitial()) {
    on<LoadMyBookings>(_onLoadMyBookings);
    on<BookingCreatedNotification>(_onBookingCreatedNotification);
    on<RealtimeBookingsUpdated>(_onRealtimeBookingsUpdated);

    // Subscribe to live Firestore stream if service is configured
    if (firestoreService != null) {
      _firestoreSubscription = firestoreService!.streamBookings().listen(
        (bookings) {
          if (bookings.isNotEmpty) {
            add(RealtimeBookingsUpdated(bookings));
          }
        },
        onError: (err) {
          // Gracefully fallback to REST repository on connection errors
        },
      );
    }
  }

  Future<void> _onLoadMyBookings(
    LoadMyBookings event,
    Emitter<MyBookingsState> emit,
  ) async {
    if (state is! MyBookingsLoaded) {
      emit(MyBookingsLoading());
    }

    try {
      final list = await repository.getBookings();
      final active = list.where((b) => !b.isCompleted && b.state != 'cancelled').toList();
      final past = list.where((b) => b.isCompleted || b.state == 'cancelled').toList();

      emit(MyBookingsLoaded(
        bookings: list,
        activeBookings: active,
        pastBookings: past,
      ));
    } catch (e) {
      emit(MyBookingsError(e.toString()));
    }
  }

  void _onBookingCreatedNotification(
    BookingCreatedNotification event,
    Emitter<MyBookingsState> emit,
  ) {
    if (state is MyBookingsLoaded) {
      final current = state as MyBookingsLoaded;
      final updatedList = [event.newBooking, ...current.bookings];
      final active = updatedList.where((b) => !b.isCompleted && b.state != 'cancelled').toList();
      final past = updatedList.where((b) => b.isCompleted || b.state == 'cancelled').toList();

      emit(MyBookingsLoaded(
        bookings: updatedList,
        activeBookings: active,
        pastBookings: past,
      ));
    } else {
      add(const LoadMyBookings());
    }
  }

  void _onRealtimeBookingsUpdated(
    RealtimeBookingsUpdated event,
    Emitter<MyBookingsState> emit,
  ) {
    final active = event.bookings.where((b) => !b.isCompleted && b.state != 'cancelled').toList();
    final past = event.bookings.where((b) => b.isCompleted || b.state == 'cancelled').toList();

    emit(MyBookingsLoaded(
      bookings: event.bookings,
      activeBookings: active,
      pastBookings: past,
    ));
  }

  @override
  Future<void> close() {
    _firestoreSubscription?.cancel();
    return super.close();
  }
}
