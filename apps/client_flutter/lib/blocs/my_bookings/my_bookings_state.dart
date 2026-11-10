import 'package:equatable/equatable.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

abstract class MyBookingsState extends Equatable {
  const MyBookingsState();
  @override
  List<Object?> get props => [];
}

class MyBookingsInitial extends MyBookingsState {}

class MyBookingsLoading extends MyBookingsState {}

class MyBookingsLoaded extends MyBookingsState {
  final List<Booking> bookings;
  final List<Booking> activeBookings;
  final List<Booking> pastBookings;

  const MyBookingsLoaded({
    required this.bookings,
    required this.activeBookings,
    required this.pastBookings,
  });

  @override
  List<Object?> get props => [bookings, activeBookings, pastBookings];
}

class MyBookingsError extends MyBookingsState {
  final String message;
  const MyBookingsError(this.message);
  @override
  List<Object?> get props => [message];
}
