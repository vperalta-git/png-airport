import 'package:equatable/equatable.dart';

enum ConvoyStatus {
  idleAtBase,
  stagedAtAirport,
  passengerBoarded,
  inTransit,
  atDestination,
  distress,
}

class ConvoyUnit extends Equatable {
  final String id;
  final String callsign; // e.g. "Alpha-1 (Armored)"
  final String vehicleName; // e.g. "Toyota LandCruiser 200 B6"
  final String plateNumber;
  final String driverName;
  final String leadSecurityOfficer;
  final bool hasArmedEscort;
  final ConvoyStatus status;
  final String currentZone; // e.g. "POM - Jackson's Intl"
  final String destination; // e.g. "The Stanley Hotel & Suites, Waigani"
  final String? activeBookingRef;
  final String? passengerName;
  final double currentSpeedKmh;
  final int fuelPercent;
  final DateTime lastPing;

  const ConvoyUnit({
    required this.id,
    required this.callsign,
    required this.vehicleName,
    required this.plateNumber,
    required this.driverName,
    required this.leadSecurityOfficer,
    required this.hasArmedEscort,
    required this.status,
    required this.currentZone,
    required this.destination,
    this.activeBookingRef,
    this.passengerName,
    required this.currentSpeedKmh,
    required this.fuelPercent,
    required this.lastPing,
  });

  ConvoyUnit copyWith({
    String? id,
    String? callsign,
    String? vehicleName,
    String? plateNumber,
    String? driverName,
    String? leadSecurityOfficer,
    bool? hasArmedEscort,
    ConvoyStatus? status,
    String? currentZone,
    String? destination,
    String? activeBookingRef,
    String? passengerName,
    double? currentSpeedKmh,
    int? fuelPercent,
    DateTime? lastPing,
  }) {
    return ConvoyUnit(
      id: id ?? this.id,
      callsign: callsign ?? this.callsign,
      vehicleName: vehicleName ?? this.vehicleName,
      plateNumber: plateNumber ?? this.plateNumber,
      driverName: driverName ?? this.driverName,
      leadSecurityOfficer: leadSecurityOfficer ?? this.leadSecurityOfficer,
      hasArmedEscort: hasArmedEscort ?? this.hasArmedEscort,
      status: status ?? this.status,
      currentZone: currentZone ?? this.currentZone,
      destination: destination ?? this.destination,
      activeBookingRef: activeBookingRef ?? this.activeBookingRef,
      passengerName: passengerName ?? this.passengerName,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      fuelPercent: fuelPercent ?? this.fuelPercent,
      lastPing: lastPing ?? this.lastPing,
    );
  }

  @override
  List<Object?> get props => [
        id,
        callsign,
        vehicleName,
        plateNumber,
        driverName,
        leadSecurityOfficer,
        hasArmedEscort,
        status,
        currentZone,
        destination,
        activeBookingRef,
        passengerName,
        currentSpeedKmh,
        fuelPercent,
        lastPing,
      ];
}
