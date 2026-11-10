import 'package:equatable/equatable.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

abstract class MyBookingsEvent extends Equatable {
  const MyBookingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyBookings extends MyBookingsEvent {
  final bool forceRefresh;
  const LoadMyBookings({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class BookingCreatedNotification extends MyBookingsEvent {
  final Booking newBooking;
  const BookingCreatedNotification(this.newBooking);
  @override
  List<Object?> get props => [newBooking];
}

class RealtimeBookingsUpdated extends MyBookingsEvent {
  final List<Booking> bookings;
  const RealtimeBookingsUpdated(this.bookings);
  @override
  List<Object?> get props => [bookings];
}
