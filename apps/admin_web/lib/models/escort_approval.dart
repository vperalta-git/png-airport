import 'package:equatable/equatable.dart';

enum EscortRiskLevel { moderate, high, severeCritical }
enum ApprovalDecision { pending, approved, rejected }

class EscortApproval extends Equatable {
  final String id;
  final String bookingRef;
  final String clientOrganization;
  final String passengerName;
  final String airportIata;
  final String routeDescription;
  final DateTime scheduledDeparture;
  final EscortRiskLevel riskLevel;
  final bool requiresArmoredCruiser;
  final int armedGuardsRequested;
  final bool requiresPoliceEscortVehicle;
  final double quotePgk;
  final ApprovalDecision decision;
  final String? supervisorNotes;
  final DateTime? reviewedAt;

  const EscortApproval({
    required this.id,
    required this.bookingRef,
    required this.clientOrganization,
    required this.passengerName,
    required this.airportIata,
    required this.routeDescription,
    required this.scheduledDeparture,
    required this.riskLevel,
    required this.requiresArmoredCruiser,
    required this.armedGuardsRequested,
    required this.requiresPoliceEscortVehicle,
    required this.quotePgk,
    this.decision = ApprovalDecision.pending,
    this.supervisorNotes,
    this.reviewedAt,
  });

  factory EscortApproval.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    ApprovalDecision dec = ApprovalDecision.pending;
    if (statusStr == 'approved') {
      dec = ApprovalDecision.approved;
    } else if (statusStr == 'rejected') {
      dec = ApprovalDecision.rejected;
    }

    return EscortApproval(
      id: json['booking_id']?.toString() ?? json['id']?.toString() ?? 'appr_01',
      bookingRef: json['reference'] as String? ?? 'BK-PNG-2026-0001',
      clientOrganization: json['exception_type'] as String? ?? 'Corporate Movement',
      passengerName: json['passenger'] as String? ?? 'Traveler',
      airportIata: 'POM',
      routeDescription: json['reason'] as String? ?? 'Operational Review Required',
      scheduledDeparture: DateTime.now().add(const Duration(hours: 2)),
      riskLevel: EscortRiskLevel.high,
      requiresArmoredCruiser: true,
      armedGuardsRequested: 2,
      requiresPoliceEscortVehicle: false,
      quotePgk: 0.0,
      decision: dec,
      supervisorNotes: json['reason'] as String?,
    );
  }

  EscortApproval copyWith({
    String? id,
    String? bookingRef,
    String? clientOrganization,
    String? passengerName,
    String? airportIata,
    String? routeDescription,
    DateTime? scheduledDeparture,
    EscortRiskLevel? riskLevel,
    bool? requiresArmoredCruiser,
    int? armedGuardsRequested,
    bool? requiresPoliceEscortVehicle,
    double? quotePgk,
    ApprovalDecision? decision,
    String? supervisorNotes,
    DateTime? reviewedAt,
  }) {
    return EscortApproval(
      id: id ?? this.id,
      bookingRef: bookingRef ?? this.bookingRef,
      clientOrganization: clientOrganization ?? this.clientOrganization,
      passengerName: passengerName ?? this.passengerName,
      airportIata: airportIata ?? this.airportIata,
      routeDescription: routeDescription ?? this.routeDescription,
      scheduledDeparture: scheduledDeparture ?? this.scheduledDeparture,
      riskLevel: riskLevel ?? this.riskLevel,
      requiresArmoredCruiser: requiresArmoredCruiser ?? this.requiresArmoredCruiser,
      armedGuardsRequested: armedGuardsRequested ?? this.armedGuardsRequested,
      requiresPoliceEscortVehicle:
          requiresPoliceEscortVehicle ?? this.requiresPoliceEscortVehicle,
      quotePgk: quotePgk ?? this.quotePgk,
      decision: decision ?? this.decision,
      supervisorNotes: supervisorNotes ?? this.supervisorNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingRef,
        clientOrganization,
        passengerName,
        airportIata,
        routeDescription,
        scheduledDeparture,
        riskLevel,
        requiresArmoredCruiser,
        armedGuardsRequested,
        requiresPoliceEscortVehicle,
        quotePgk,
        decision,
        supervisorNotes,
        reviewedAt,
      ];
}
