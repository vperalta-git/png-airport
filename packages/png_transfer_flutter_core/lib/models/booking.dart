import 'package:equatable/equatable.dart';
import 'passenger.dart';

class OperationalTimelineEvent extends Equatable {
  final String event;
  final String name;
  final String timestamp;
  final String? user;

  const OperationalTimelineEvent({
    required this.event,
    required this.name,
    required this.timestamp,
    this.user,
  });

  factory OperationalTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OperationalTimelineEvent(
      event: json['event'] as String? ?? 'event',
      name: json['name'] as String? ?? 'Status Update',
      timestamp: json['timestamp'] as String? ?? '',
      user: json['user'] as String?,
    );
  }

  @override
  List<Object?> get props => [event, name, timestamp];
}

class Booking extends Equatable {
  final int id;
  final String name;
  final String state;
  final int airportId;
  final String airportName;
  final String airportIata;
  final String pickupLocation;
  final String destination;
  final String pickupDatetime;
  final String? flightNumber;
  final String? flightAirline;
  final double totalFare;
  final String paymentStatus;
  final bool securityRequired;
  final bool meetGreetRequired;
  final String? recommendedPickupDatetime;
  final int flightDelayMinutes;
  final String? incidentState;
  final String? incidentSeverity;
  final String? noShowApprovalState;
  final int contactAttemptCount;
  final String? epodReceiptId;
  final String? driverName;
  final String? vehicleCallsign;
  final List<Passenger> passengers;
  final List<OperationalTimelineEvent> timeline;

  const Booking({
    required this.id,
    required this.name,
    required this.state,
    required this.airportId,
    required this.airportName,
    required this.airportIata,
    required this.pickupLocation,
    required this.destination,
    required this.pickupDatetime,
    this.recommendedPickupDatetime,
    this.flightDelayMinutes = 0,
    this.incidentState = 'normal',
    this.incidentSeverity,
    this.noShowApprovalState,
    this.contactAttemptCount = 0,
    this.epodReceiptId,
    this.driverName,
    this.vehicleCallsign,
    this.flightNumber,
    this.flightAirline,
    required this.totalFare,
    this.paymentStatus = 'unpaid',
    this.securityRequired = false,
    this.meetGreetRequired = true,
    this.passengers = const [],
    this.timeline = const [],
  });

  bool get isCompleted => state == 'completed';
  bool get isInProgress =>
      state == 'dispatched' ||
      state == 'driver_en_route' ||
      state == 'at_airport' ||
      state == 'passenger_located' ||
      state == 'passenger_verified' ||
      state == 'passenger_onboard' ||
      state == 'transfer_in_progress' ||
      state == 'arrived_destination';

  bool get isDelayed => flightDelayMinutes > 0 || (recommendedPickupDatetime != null && recommendedPickupDatetime != pickupDatetime);
  bool get hasActiveSos => incidentState == 'sos_active';

  factory Booking.fromJson(Map<String, dynamic> json) {
    final airportRaw = json['airport'] as Map<String, dynamic>? ?? {};
    final passengersRaw = json['passengers'] as List<dynamic>? ?? [];
    final timelineRaw = json['timeline'] as List<dynamic>? ?? [];

    return Booking(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'PNG-TR-NEW',
      state: json['state'] as String? ?? 'draft',
      airportId: airportRaw['id'] as int? ?? (json['airport_id'] as int? ?? 1),
      airportName: airportRaw['name'] as String? ?? "Nadzab Tomodachi Int'l Airport",
      airportIata: airportRaw['iata'] as String? ?? 'LAE',
      pickupLocation: json['pickup_location'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      pickupDatetime: json['pickup_datetime'] as String? ?? '',
      recommendedPickupDatetime: json['recommended_pickup_datetime'] as String?,
      flightDelayMinutes: json['flight_delay_minutes'] as int? ?? 0,
      incidentState: json['incident_state'] as String? ?? 'normal',
      incidentSeverity: json['incident_severity'] as String?,
      noShowApprovalState: json['no_show_approval_state'] as String?,
      contactAttemptCount: json['contact_attempt_count'] as int? ?? 0,
      epodReceiptId: json['epod_receipt_id'] as String?,
      driverName: json['driver'] as String?,
      vehicleCallsign: json['vehicle'] as String?,
      flightNumber: json['flight_number'] as String?,
      flightAirline: json['flight_airline'] as String?,
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      securityRequired: json['security_required'] as bool? ?? false,
      meetGreetRequired: json['meet_greet_required'] as bool? ?? true,
      passengers: passengersRaw.map((p) => Passenger.fromJson(p as Map<String, dynamic>)).toList(),
      timeline: timelineRaw.map((t) => OperationalTimelineEvent.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, state, pickupDatetime, recommendedPickupDatetime, totalFare, incidentState];
}
