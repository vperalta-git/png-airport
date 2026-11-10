import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dispatch_job.dart';
import '../../models/sos_alert.dart';

class ControlRoomFirestoreService {
  final FirebaseFirestore _firestore;

  ControlRoomFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Default seed dispatch jobs (Morobe Province Nadzab & POM Jacksons)
  static List<DispatchJob> get defaultPendingJobs => [
    DispatchJob(
      id: 'job_8802',
      bookingRef: 'PNG-TR-8802',
      passengerName: 'David Kila (Mining Consultant)',
      passengerOrganization: 'Morobe Mining & Resources Ltd',
      flightNumber: 'PX102 (Air Niugini)',
      airportIata: 'LAE',
      pickupZone: 'Nadzab Tomodachi International Terminal',
      dropoffZone: 'Lae International Hotel, Morobe',
      scheduledPickup: DateTime.now().add(const Duration(minutes: 45)),
      requiresArmored: true,
      requiresArmedEscort: true,
      urgency: DispatchUrgency.highVip,
    ),
    DispatchJob(
      id: 'job_8805',
      bookingRef: 'PNG-TR-8805',
      passengerName: 'Sarah Jenkins (UN Logistics)',
      passengerOrganization: 'United Nations Field Support - PNG',
      flightNumber: 'CG405 (PNG Air)',
      airportIata: 'LAE',
      pickupZone: 'Nadzab Terminal 1 Arrival Gate',
      dropoffZone: 'Morobe Provincial Government HQ, Top Town',
      scheduledPickup: DateTime.now().add(const Duration(hours: 2)),
      requiresArmored: false,
      requiresArmedEscort: true,
      urgency: DispatchUrgency.normal,
    ),
    DispatchJob(
      id: 'job_8809',
      bookingRef: 'PNG-TR-8809',
      passengerName: 'Markus Henderson (Chevron VP)',
      passengerOrganization: 'Chevron Asia-Pacific Exploration',
      flightNumber: 'PX004 (Brisbane - POM)',
      airportIata: 'POM',
      pickupZone: "Jackson's Intl T1 VIP Apron",
      dropoffZone: 'The Stanley Hotel & Suites, Waigani',
      scheduledPickup: DateTime.now().add(const Duration(hours: 3)),
      requiresArmored: true,
      requiresArmedEscort: true,
      urgency: DispatchUrgency.highVip,
    ),
  ];

  /// Stream dispatch queue jobs from Firestore
  Stream<List<DispatchJob>> streamDispatchQueue() {
    return _firestore
        .collection('bookings')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return defaultPendingJobs;
          }
          final list = <DispatchJob>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              list.add(DispatchJob.fromJson(data));
            } catch (_) {
              // Ignore malformed doc
            }
          }
          return list.isNotEmpty ? list : defaultPendingJobs;
        });
  }

  /// Assign driver and vehicle to a booking in Firestore
  Future<void> assignJob({
    required String jobId,
    required String driverId,
    required String driverName,
    required String vehicleCallsign,
  }) async {
    try {
      final docId = jobId.replaceAll('job_', '').replaceAll('TRF-', '');
      await _firestore.collection('bookings').doc(docId).set({
        'driver_id': driverId,
        'driver': driverName,
        'vehicle': vehicleCallsign,
        'state': 'dispatched',
        'dispatched_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Stream live emergency incidents from Firestore
  Stream<List<SosAlert>> streamIncidents() {
    return _firestore
        .collection('incidents')
        .snapshots()
        .map((snapshot) {
          final list = <SosAlert>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final statusStr = data['status'] as String? ?? 'active';
              AlertStatus status = AlertStatus.activeUnacknowledged;
              if (statusStr == 'under_response') status = AlertStatus.underResponse;
              if (statusStr == 'resolved') status = AlertStatus.resolved;

              list.add(SosAlert(
                id: doc.id,
                unitCallsign: data['mission_id'] as String? ?? 'Unit Unknown',
                driverName: data['driver_name'] as String? ?? 'Field Personnel',
                locationDesc: data['summary'] as String? ?? 'Field Incident',
                latitude: data['latitude']?.toString() ?? '-6.5698',
                longitude: data['longitude']?.toString() ?? '146.7262',
                severity: data['severity'] == 'CRITICAL'
                    ? AlertSeverity.p1AmbushHijack
                    : AlertSeverity.p2RoadblockCivil,
                status: status,
                message: data['summary'] as String? ?? 'Incident reported from field mobile unit.',
                timestamp: (data['reported_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
                responseNotes: data['response_notes'] as String?,
              ));
            } catch (_) {}
          }
          return list;
        });
  }

  /// Update incident response status in Firestore
  Future<void> updateIncidentResponse({
    required String incidentId,
    required String status,
    required String responseNotes,
  }) async {
    try {
      await _firestore.collection('incidents').doc(incidentId).set({
        'status': status,
        'response_notes': responseNotes,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}

