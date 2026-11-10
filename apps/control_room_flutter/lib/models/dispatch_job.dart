import 'package:equatable/equatable.dart';

enum DispatchUrgency { normal, highVip, emergency }

class DispatchJob extends Equatable {
  final String id;
  final String bookingRef;
  final String passengerName;
  final String passengerOrganization;
  final String flightNumber;
  final String airportIata;
  final String pickupZone;
  final String dropoffZone;
  final DateTime scheduledPickup;
  final bool requiresArmored;
  final bool requiresArmedEscort;
  final DispatchUrgency urgency;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedVehicleCallsign;
  final bool isDispatched;

  const DispatchJob({
    required this.id,
    required this.bookingRef,
    required this.passengerName,
    required this.passengerOrganization,
    required this.flightNumber,
    required this.airportIata,
    required this.pickupZone,
    required this.dropoffZone,
    required this.scheduledPickup,
    required this.requiresArmored,
    required this.requiresArmedEscort,
    required this.urgency,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedVehicleCallsign,
    this.isDispatched = false,
  });

  factory DispatchJob.fromJson(Map<String, dynamic> json) {
    final airportRaw = json['airport'] as Map<String, dynamic>? ?? {};
    final passengersRaw = json['passengers'] as List<dynamic>? ?? [];
    final firstPax = passengersRaw.isNotEmpty ? passengersRaw.first as Map<String, dynamic> : null;
    final paxName = firstPax?['name'] as String? ?? json['passenger_name'] as String? ?? 'Traveler';
    final org = json['passenger_organization'] as String? ?? 'Corporate Account';
    final dtStr = json['pickup_datetime'] as String? ?? '';
    final dt = DateTime.tryParse(dtStr) ?? DateTime.now();
    final secReq = json['security_required'] as bool? ?? false;
    final state = json['state'] as String? ?? 'draft';

    return DispatchJob(
      id: json['id']?.toString() ?? 'job_${json['name']}',
      bookingRef: json['name'] as String? ?? 'PNG-TR-NEW',
      passengerName: paxName,
      passengerOrganization: org,
      flightNumber: json['flight_number'] as String? ?? 'PX Air Niugini',
      airportIata: airportRaw['iata'] as String? ?? 'POM',
      pickupZone: json['pickup_location'] as String? ?? 'Airport Terminal',
      dropoffZone: json['destination'] as String? ?? 'City Center',
      scheduledPickup: dt,
      requiresArmored: secReq,
      requiresArmedEscort: secReq,
      urgency: secReq ? DispatchUrgency.highVip : DispatchUrgency.normal,
      assignedDriverId: json['driver_id']?.toString(),
      assignedDriverName: json['driver'] as String?,
      assignedVehicleCallsign: json['vehicle'] as String?,
      isDispatched: state == 'dispatched' ||
          state == 'driver_en_route' ||
          state == 'at_airport' ||
          state == 'transfer_in_progress',
    );
  }

  DispatchJob copyWith({
    String? id,
    String? bookingRef,
    String? passengerName,
    String? passengerOrganization,
    String? flightNumber,
    String? airportIata,
    String? pickupZone,
    String? dropoffZone,
    DateTime? scheduledPickup,
    bool? requiresArmored,
    bool? requiresArmedEscort,
    DispatchUrgency? urgency,
    String? assignedDriverId,
    String? assignedDriverName,
    String? assignedVehicleCallsign,
    bool? isDispatched,
  }) {
    return DispatchJob(
      id: id ?? this.id,
      bookingRef: bookingRef ?? this.bookingRef,
      passengerName: passengerName ?? this.passengerName,
      passengerOrganization: passengerOrganization ?? this.passengerOrganization,
      flightNumber: flightNumber ?? this.flightNumber,
      airportIata: airportIata ?? this.airportIata,
      pickupZone: pickupZone ?? this.pickupZone,
      dropoffZone: dropoffZone ?? this.dropoffZone,
      scheduledPickup: scheduledPickup ?? this.scheduledPickup,
      requiresArmored: requiresArmored ?? this.requiresArmored,
      requiresArmedEscort: requiresArmedEscort ?? this.requiresArmedEscort,
      urgency: urgency ?? this.urgency,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedVehicleCallsign: assignedVehicleCallsign ?? this.assignedVehicleCallsign,
      isDispatched: isDispatched ?? this.isDispatched,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingRef,
        passengerName,
        passengerOrganization,
        flightNumber,
        airportIata,
        pickupZone,
        dropoffZone,
        scheduledPickup,
        requiresArmored,
        requiresArmedEscort,
        urgency,
        assignedDriverId,
        assignedDriverName,
        assignedVehicleCallsign,
        isDispatched,
      ];
}
