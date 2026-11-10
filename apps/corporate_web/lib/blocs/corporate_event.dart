import 'package:equatable/equatable.dart';
import '../models/corporate_passenger.dart';

abstract class CorporateEvent extends Equatable {
  const CorporateEvent();

  @override
  List<Object?> get props => [];
}

class LoadCorporateData extends CorporateEvent {
  const LoadCorporateData();
}

class CreateCorporateTransfer extends CorporateEvent {
  final String leadPassenger;
  final int passengerCount;
  final String flightNumber;
  final String airportName;
  final String pickupLocation;
  final String destination;
  final DateTime scheduledPickup;
  final String vehicleType;
  final String escortLevel;
  final String poNumber;
  final String costCenter;
  final double farePgk;
  final String notes;

  const CreateCorporateTransfer({
    required this.leadPassenger,
    required this.passengerCount,
    required this.flightNumber,
    required this.airportName,
    required this.pickupLocation,
    required this.destination,
    required this.scheduledPickup,
    required this.vehicleType,
    required this.escortLevel,
    required this.poNumber,
    required this.costCenter,
    required this.farePgk,
    this.notes = '',
  });

  @override
  List<Object?> get props => [leadPassenger, flightNumber, poNumber];
}

class ApproveCorporateBooking extends CorporateEvent {
  final String bookingId;
  final bool isApproved;
  final String approverName;

  const ApproveCorporateBooking({
    required this.bookingId,
    required this.isApproved,
    required this.approverName,
  });

  @override
  List<Object?> get props => [bookingId, isApproved];
}

class RegisterNewPassenger extends CorporateEvent {
  final CorporatePassenger passenger;

  const RegisterNewPassenger(this.passenger);

  @override
  List<Object?> get props => [passenger];
}

