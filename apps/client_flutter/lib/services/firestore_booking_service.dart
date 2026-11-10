import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

class FirestoreBookingService {
  final FirebaseFirestore _firestore;

  FirestoreBookingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream all bookings in real time, ordered by pickup_datetime or ID
  Stream<List<Booking>> streamBookings() {
    return _firestore
        .collection('bookings')
        .snapshots()
        .map((snapshot) {
          final list = <Booking>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              list.add(Booking.fromJson(data));
            } catch (e) {
              // Ignore malformed doc or continue
            }
          }
          // Sort descending by id so latest bookings are first
          list.sort((a, b) => b.id.compareTo(a.id));
          return list;
        });
  }

  /// Stream a single booking by ID in real time
  Stream<Booking?> streamBooking(int bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId.toString())
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return Booking.fromJson(snapshot.data()!);
        });
  }

  /// Stream real-time driver GPS tracking coordinates
  Stream<Map<String, dynamic>?> streamDriverTelemetry(int bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId.toString())
        .collection('telemetry')
        .doc('current')
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Creates a new booking directly in Cloud Firestore (operational booking service)
  Future<Booking> createBookingInFirestore(Map<String, dynamic> payload) async {
    final docRef = _firestore.collection('bookings').doc();
    final tempId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final leadPassenger = (payload['passengers'] as List<dynamic>?)?.isNotEmpty == true
        ? payload['passengers'][0] as Map<String, dynamic>
        : null;

    final docData = <String, dynamic>{
      ...payload,
      'id': tempId,
      'doc_id': docRef.id,
      'reference': 'PNG-TR-PENDING',
      'name': 'PNG-TR-PENDING',
      'state': 'draft',
      'synced_to_cloud': true,
      'booking_channel': 'mobile',
      'lead_passenger_name': leadPassenger != null
          ? '${leadPassenger['first_name'] ?? ''} ${leadPassenger['last_name'] ?? ''}'.trim()
          : 'Lead Passenger',
      'lead_passenger_phone': leadPassenger?['mobile'] ?? '',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await docRef.set(docData);
    return Booking.fromJson(docData);
  }
}
