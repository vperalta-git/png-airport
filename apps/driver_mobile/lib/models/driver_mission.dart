import 'package:equatable/equatable.dart';

class EpodData extends Equatable {
  final String receiptId;
  final String signerName;
  final String signedAt;
  final int rating;
  final String notes;
  final List<List<double>>? signaturePoints;
  final bool notifiedControlRoom;
  final bool notifiedClientEmail;
  final bool notifiedWhatsapp;

  const EpodData({
    required this.receiptId,
    required this.signerName,
    required this.signedAt,
    this.rating = 5,
    this.notes = 'Safe arrival at destination. Luggage and personnel cleared.',
    this.signaturePoints,
    this.notifiedControlRoom = true,
    this.notifiedClientEmail = true,
    this.notifiedWhatsapp = true,
  });

  factory EpodData.fromJson(Map<String, dynamic> json) {
    return EpodData(
      receiptId: json['receipt_id'] as String? ?? 'EPOD-PNG-2026-0000',
      signerName: json['signer_name'] as String? ?? 'Passenger',
      signedAt: json['signed_at'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      notes: json['notes'] as String? ?? '',
      notifiedControlRoom: json['notified_control_room'] as bool? ?? true,
      notifiedClientEmail: json['notified_client_email'] as bool? ?? true,
      notifiedWhatsapp: json['notified_whatsapp'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'receipt_id': receiptId,
        'signer_name': signerName,
        'signed_at': signedAt,
        'rating': rating,
        'notes': notes,
        'notified_control_room': notifiedControlRoom,
        'notified_client_email': notifiedClientEmail,
        'notified_whatsapp': notifiedWhatsapp,
      };

  @override
  List<Object?> get props => [receiptId, signerName, signedAt, rating];
}

class DriverMission extends Equatable {
  final String id;
  final String bookingRef;
  final String passengerName;
  final String passengerPhone;
  final String passengerEmail;
  final String flight;
  final String eta;
  final String pickup;
  final String dropoff;
  final String stage; // 'assigned', 'driver_en_route', 'at_airport', 'passenger_located', 'passenger_verified', 'passenger_onboard', 'transfer_in_progress', 'arrived_destination', 'completed'
  final String vehicle;
  final String specialNotes;
  final bool securityEscortRequired;
  final String securityLevel; // 'Level 1 Standard', 'Level 2 Armed Escort', 'Level 3 Tactical Convoy'
  final EpodData? epod;

  const DriverMission({
    required this.id,
    required this.bookingRef,
    required this.passengerName,
    required this.passengerPhone,
    required this.passengerEmail,
    required this.flight,
    required this.eta,
    required this.pickup,
    required this.dropoff,
    required this.stage,
    required this.vehicle,
    required this.specialNotes,
    this.securityEscortRequired = true,
    this.securityLevel = 'Level 2 Armed Escort Protocol',
    this.epod,
  });

  factory DriverMission.fromJson(Map<String, dynamic> json) {
    final airportRaw = json['airport'] as Map<String, dynamic>? ?? {};
    final passengersRaw = json['passengers'] as List<dynamic>? ?? [];
    final firstPax = passengersRaw.isNotEmpty ? passengersRaw.first as Map<String, dynamic> : null;
    final paxName = firstPax?['name'] as String? ?? json['passenger_name'] as String? ?? 'Lead Traveler';
    final paxPhone = firstPax?['mobile'] as String? ?? json['passenger_phone'] as String? ?? '+675 7000 0000';
    final paxEmail = firstPax?['email'] as String? ?? json['passenger_email'] as String? ?? '';
    final secReq = json['security_required'] as bool? ?? false;

    return DriverMission(
      id: json['id']?.toString() ?? 'TRF-${json['name']}',
      bookingRef: json['name'] as String? ?? 'PNG-TR-NEW',
      passengerName: paxName,
      passengerPhone: paxPhone,
      passengerEmail: paxEmail,
      flight: '${json['flight_number'] ?? 'PX Flight'} (${airportRaw['name'] ?? 'Airport'})',
      eta: json['recommended_pickup_datetime'] as String? ?? json['pickup_datetime'] as String? ?? 'Scheduled',
      pickup: json['pickup_location'] as String? ?? 'Arrival Terminal',
      dropoff: json['destination'] as String? ?? 'Destination',
      stage: json['state'] as String? ?? 'assigned',
      vehicle: json['vehicle'] as String? ?? 'Company Transport Unit',
      specialNotes: secReq ? 'Armed Security Protocol Activated.' : 'Standard Commercial Transfer.',
      securityEscortRequired: secReq,
      securityLevel: secReq ? 'Level 2 Armed Escort Protocol' : 'Level 1 Standard',
      epod: json['epod_receipt_id'] != null
          ? EpodData(
              receiptId: json['epod_receipt_id'] as String,
              signerName: paxName,
              signedAt: DateTime.now().toIso8601String(),
            )
          : null,
    );
  }

  bool get isCompleted => stage == 'completed';

  DriverMission copyWith({
    String? stage,
    EpodData? epod,
  }) {
    return DriverMission(
      id: id,
      bookingRef: bookingRef,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      passengerEmail: passengerEmail,
      flight: flight,
      eta: eta,
      pickup: pickup,
      dropoff: dropoff,
      stage: stage ?? this.stage,
      vehicle: vehicle,
      specialNotes: specialNotes,
      securityEscortRequired: securityEscortRequired,
      securityLevel: securityLevel,
      epod: epod ?? this.epod,
    );
  }

  @override
  List<Object?> get props => [id, bookingRef, stage, epod];
}
