import 'package:equatable/equatable.dart';

enum CorporateBookingStatus {
  pendingApproval,
  approved,
  dispatched,
  inTransit,
  completed,
  cancelled,
}

class CorporateBooking extends Equatable {
  final String id;
  final String refNumber;
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
  final CorporateBookingStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String notes;

  const CorporateBooking({
    required this.id,
    required this.refNumber,
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
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.notes = '',
  });

  factory CorporateBooking.fromJson(Map<String, dynamic> json) {
    CorporateBookingStatus parseStatus(String? s) {
      switch (s) {
        case 'pending_approval':
          return CorporateBookingStatus.pendingApproval;
        case 'approved':
          return CorporateBookingStatus.approved;
        case 'dispatched':
          return CorporateBookingStatus.dispatched;
        case 'in_transit':
        case 'transfer_in_progress':
          return CorporateBookingStatus.inTransit;
        case 'completed':
          return CorporateBookingStatus.completed;
        case 'cancelled':
          return CorporateBookingStatus.cancelled;
        default:
          return CorporateBookingStatus.dispatched;
      }
    }

    final airportRaw = json['airport'] as Map<String, dynamic>? ?? {};
    final passengersRaw = json['passengers'] as List<dynamic>? ?? [];
    final firstPax = passengersRaw.isNotEmpty ? passengersRaw.first as Map<String, dynamic> : null;
    final paxName = firstPax?['name'] as String? ?? json['passenger_name'] as String? ?? 'Executive Traveler';

    final pickupDt = DateTime.tryParse(json['pickup_datetime']?.toString() ?? '') ?? DateTime.now();

    return CorporateBooking(
      id: json['id']?.toString() ?? json['name'] as String? ?? 'CB-${DateTime.now().millisecondsSinceEpoch}',
      refNumber: json['name'] as String? ?? json['ref_number'] as String? ?? 'PNG-TR-CORP',
      leadPassenger: paxName,
      passengerCount: passengersRaw.isNotEmpty ? passengersRaw.length : (json['passenger_count'] as int? ?? 1),
      flightNumber: json['flight_number'] as String? ?? 'PX102',
      airportName: airportRaw['name'] as String? ?? json['airport_name'] as String? ?? 'Nadzab / Tomodachi (LAE)',
      pickupLocation: json['pickup_location'] as String? ?? 'Arrival Terminal 1',
      destination: json['destination'] as String? ?? 'Lae International Hotel',
      scheduledPickup: pickupDt,
      vehicleType: json['vehicle'] as String? ?? json['vehicle_type'] as String? ?? 'Toyota LandCruiser 79 Security Spec',
      escortLevel: json['escort_level'] as String? ?? (json['security_required'] == true ? 'ARMED TACTICAL ESCORT' : 'STANDARD CHAUFFEUR'),
      poNumber: json['po_number'] as String? ?? 'PO-2026-PNG-8802',
      costCenter: json['cost_center'] as String? ?? 'CC-MOROBE-OPS',
      farePgk: (json['total_amount'] as num?)?.toDouble() ?? (json['fare_pgk'] as num?)?.toDouble() ?? 1350.0,
      status: parseStatus(json['state'] as String?),
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'].toString()) : null,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': refNumber,
    'passenger_name': leadPassenger,
    'passenger_count': passengerCount,
    'flight_number': flightNumber,
    'airport_name': airportName,
    'pickup_location': pickupLocation,
    'destination': destination,
    'pickup_datetime': scheduledPickup.toIso8601String(),
    'vehicle_type': vehicleType,
    'escort_level': escortLevel,
    'po_number': poNumber,
    'cost_center': costCenter,
    'fare_pgk': farePgk,
    'state': status.name,
    'approved_by': approvedBy,
    'approved_at': approvedAt?.toIso8601String(),
    'notes': notes,
  };

  CorporateBooking copyWith({
    CorporateBookingStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return CorporateBooking(
      id: id,
      refNumber: refNumber,
      leadPassenger: leadPassenger,
      passengerCount: passengerCount,
      flightNumber: flightNumber,
      airportName: airportName,
      pickupLocation: pickupLocation,
      destination: destination,
      scheduledPickup: scheduledPickup,
      vehicleType: vehicleType,
      escortLevel: escortLevel,
      poNumber: poNumber,
      costCenter: costCenter,
      farePgk: farePgk,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      notes: notes,
    );
  }

  @override
  List<Object?> get props => [id, refNumber, status, poNumber];
}

