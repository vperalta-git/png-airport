import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/driver_mission.dart';

class DriverFirestoreService {
  final FirebaseFirestore _firestore;

  DriverFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Default Morobe Province / Nadzab Airport seed missions
  static List<DriverMission> get defaultMissions => [
    const DriverMission(
      id: 'TRF-00108',
      bookingRef: 'PNG-TR-8802',
      passengerName: 'David Kila (Mining Consultant)',
      passengerPhone: '+675 7234 5678',
      passengerEmail: 'david.kila@morobe-resources.pg',
      flight: 'PX102 (Nadzab Tomodachi International)',
      eta: '14:30 Today',
      pickup: 'Nadzab Airport (AYNZ) Arrival Gate B',
      dropoff: 'Lae International Hotel, Morobe Province',
      stage: 'assigned',
      vehicle: 'Toyota LandCruiser 79 Security Spec (B6 Armored)',
      specialNotes: 'VIP Executive mining personnel. Armed escort mandatory across Markham Highway corridor.',
      securityEscortRequired: true,
      securityLevel: 'Level 2 Armed Escort Protocol',
    ),
    const DriverMission(
      id: 'TRF-00109',
      bookingRef: 'PNG-TR-8805',
      passengerName: 'Sarah Jenkins (UN Logistics)',
      passengerPhone: '+675 7199 4432',
      passengerEmail: 's.jenkins@un-lae.org',
      flight: 'CG405 (PNG Air)',
      eta: '17:15 Today',
      pickup: 'Nadzab Terminal Perimeter',
      dropoff: 'Morobe Provincial Government HQ, Top Town Lae',
      stage: 'assigned',
      vehicle: 'Prado B6 Tactical Escort',
      specialNotes: 'Scheduled arrival transfer. Luggage cleared via secure screening.',
      securityEscortRequired: true,
      securityLevel: 'Level 1 Standard Escort',
    ),
  ];

  /// Stream assigned missions from Firestore
  Stream<List<DriverMission>> streamAssignedMissions() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return defaultMissions;
      }
      final list = <DriverMission>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          list.add(DriverMission.fromJson(data));
        } catch (_) {
          // Graceful skip
        }
      }
      return list.isNotEmpty ? list : defaultMissions;
    });
  }

  /// Update booking milestone stage in Firestore
  Future<void> updateMissionStage(String missionId, String stage) async {
    try {
      final docId = missionId.replaceAll('TRF-', '');
      await _firestore.collection('bookings').doc(docId).set({
        'state': stage,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Ignored for offline local simulation
    }
  }

  /// Seal e-POD in Firestore
  Future<void> submitEpod(String missionId, EpodData epod) async {
    try {
      final docId = missionId.replaceAll('TRF-', '');
      await _firestore.collection('bookings').doc(docId).set({
        'state': 'completed',
        'epod_receipt_id': epod.receiptId,
        'epod_signer_name': epod.signerName,
        'epod_rating': epod.rating,
        'epod_notes': epod.notes,
        'epod_signed_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Ignored for offline local simulation
    }
  }

  /// Publish real-time GPS telemetry for the active booking
  Future<void> publishTelemetry({
    required String missionId,
    required double latitude,
    required double longitude,
    required double speedKmh,
    required String heading,
  }) async {
    try {
      final docId = missionId.replaceAll('TRF-', '');
      await _firestore
          .collection('bookings')
          .doc(docId)
          .collection('telemetry')
          .doc('current')
          .set({
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmh': speedKmh,
        'heading': heading,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Broadcast SOS Distress Alarm or Field Incident to Control Room
  Future<void> broadcastIncident({
    required String alertId,
    required String missionId,
    required String severity,
    required String summary,
  }) async {
    try {
      await _firestore.collection('incidents').doc(alertId).set({
        'alert_id': alertId,
        'mission_id': missionId,
        'severity': severity,
        'summary': summary,
        'reported_at': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    } catch (_) {}
  }

  /// Update driver duty presence
  Future<void> setDutyStatus({required bool isOnDuty, required String callsign}) async {
    try {
      await _firestore.collection('driver_presence').doc(callsign).set({
        'callsign': callsign,
        'is_on_duty': isOnDuty,
        'last_ping': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}

