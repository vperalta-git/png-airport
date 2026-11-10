import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/corporate_booking.dart';
import '../models/corporate_passenger.dart';
import '../models/corporate_invoice.dart';
import '../models/corporate_rate.dart';

class CorporateFirestoreService {
  final FirebaseFirestore _firestore;

  CorporateFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Default corporate bookings
  static List<CorporateBooking> get defaultBookings => [
    CorporateBooking(
      id: 'CB-2026-001',
      refNumber: 'PNG-TR-8802',
      leadPassenger: 'David Kila',
      passengerCount: 2,
      flightNumber: 'PX102 (Air Niugini)',
      airportName: 'Nadzab / Tomodachi (LAE)',
      pickupLocation: 'Nadzab Arrival Terminal 1',
      destination: 'Lae International Hotel, Morobe',
      scheduledPickup: DateTime.now().add(const Duration(minutes: 45)),
      vehicleType: 'Toyota LandCruiser 79 Security Spec (B6 Armored)',
      escortLevel: 'LEVEL 2 ARMED ESCORT PROTOCOL',
      poNumber: 'PO-2026-MMR-8802',
      costCenter: 'CC-MOROBE-OPS',
      farePgk: 1350.0,
      status: CorporateBookingStatus.dispatched,
      approvedBy: 'H. Abal (Travel Mgr)',
      approvedAt: DateTime.now().subtract(const Duration(hours: 4)),
      notes: 'VIP Executive mining personnel. Armed escort mandatory across Markham Highway corridor.',
    ),
    CorporateBooking(
      id: 'CB-2026-002',
      refNumber: 'PNG-TR-8805',
      leadPassenger: 'Sarah Jenkins',
      passengerCount: 1,
      flightNumber: 'CG405 (PNG Air)',
      airportName: 'Nadzab / Tomodachi (LAE)',
      pickupLocation: 'Nadzab Terminal 1 Arrival Gate',
      destination: 'Morobe Provincial Government HQ, Top Town',
      scheduledPickup: DateTime.now().add(const Duration(hours: 2)),
      vehicleType: 'Prado B6 Tactical Escort',
      escortLevel: 'LEVEL 1 STANDARD ESCORT',
      poNumber: 'PO-2026-UNL-8805',
      costCenter: 'CC-UN-LOGISTICS',
      farePgk: 890.0,
      status: CorporateBookingStatus.approved,
      approvedBy: 'H. Abal (Travel Mgr)',
      approvedAt: DateTime.now().subtract(const Duration(hours: 2)),
      notes: 'Scheduled arrival transfer. Luggage cleared via secure screening.',
    ),
    CorporateBooking(
      id: 'CB-2026-003',
      refNumber: 'PNG-TR-8814',
      leadPassenger: 'Hiroshi Tanaka',
      passengerCount: 3,
      flightNumber: 'PX104 (Air Niugini)',
      airportName: 'Nadzab / Tomodachi (LAE)',
      pickupLocation: 'Nadzab VIP Lounge Terminal',
      destination: 'Lae Port Maritime Container Terminal',
      scheduledPickup: DateTime.now().add(const Duration(hours: 5)),
      vehicleType: 'LandCruiser 200 Convoy',
      escortLevel: 'LEVEL 3 ARMED CONVOY (2 VEHICLES)',
      poNumber: 'PO-2026-JICA-001',
      costCenter: 'CC-MARITIME-ENG',
      farePgk: 2450.0,
      status: CorporateBookingStatus.pendingApproval,
      notes: 'Port infrastructure inspection delegation. High security escort required.',
    ),
    CorporateBooking(
      id: 'CB-2026-004',
      refNumber: 'PNG-TR-8790',
      leadPassenger: 'Marcus Henderson',
      passengerCount: 1,
      flightNumber: 'PX004 (Brisbane - POM)',
      airportName: "Jackson's International (POM)",
      pickupLocation: "Jackson's Intl T1 VIP Apron",
      destination: 'The Stanley Hotel & Suites, Waigani',
      scheduledPickup: DateTime.now().subtract(const Duration(days: 1)),
      vehicleType: 'Toyota LandCruiser 200 B6 Armored',
      escortLevel: 'LEVEL 2 ARMED ESCORT PROTOCOL',
      poNumber: 'PO-2026-CHV-4491',
      costCenter: 'CC-EXPLORATION-PNG',
      farePgk: 1650.0,
      status: CorporateBookingStatus.completed,
      approvedBy: 'Corporate Procurement',
      approvedAt: DateTime.now().subtract(const Duration(days: 2)),
      notes: 'Transferred and sealed via e-POD EPOD-PNG-2026-8790.',
    ),
  ];

  /// Default corporate passengers directory
  static List<CorporatePassenger> get defaultPassengers => [
    const CorporatePassenger(
      id: 'pax_01',
      fullName: 'David Kila',
      title: 'Principal Mining Engineer',
      department: 'Morobe Geological Services',
      email: 'david.kila@morobe-resources.pg',
      phone: '+675 7234 5678',
      idNumber: 'PNG-PASSPORT-A992140',
      isVip: true,
      emergencyContact: '+675 7333 4444 (Base Ops)',
    ),
    const CorporatePassenger(
      id: 'pax_02',
      fullName: 'Sarah Jenkins',
      title: 'Country Logistics Coordinator',
      department: 'United Nations Field Support',
      email: 's.jenkins@un-lae.org',
      phone: '+675 7199 4432',
      idNumber: 'UN-LP-778899',
      isVip: true,
      emergencyContact: '+675 7100 0001 (UN Security)',
    ),
    const CorporatePassenger(
      id: 'pax_03',
      fullName: 'Hiroshi Tanaka',
      title: 'Infrastructure Project Director',
      department: 'JICA Port Development Unit',
      email: 'tanaka.hiroshi@jica.go.jp',
      phone: '+675 7888 1234',
      idNumber: 'JPN-P-9901481',
      isVip: true,
      emergencyContact: '+675 7222 3333 (Embassy Liaison)',
    ),
    const CorporatePassenger(
      id: 'pax_04',
      fullName: 'Marcus Henderson',
      title: 'Vice President Exploration',
      department: 'Chevron Asia-Pacific',
      email: 'm.henderson@chevron.com',
      phone: '+61 400 123 456',
      idNumber: 'AUS-P-E882194',
      isVip: true,
      emergencyContact: '+61 2 9000 8888 (HQ Emergency)',
    ),
  ];

  /// Default invoices
  static List<CorporateInvoice> get defaultInvoices => [
    CorporateInvoice(
      invoiceNumber: 'INV-PNG-2026-1101',
      billingPeriod: 'November 2026 (Fortnight 1)',
      poNumber: 'PO-2026-MMR-CORP',
      totalTransfers: 12,
      subtotalPgk: 15400.0,
      gstPgk: 1540.0,
      totalPgk: 16940.0,
      status: InvoiceStatus.approved,
      issueDate: DateTime.now().subtract(const Duration(days: 4)),
      dueDate: DateTime.now().add(const Duration(days: 26)),
    ),
    CorporateInvoice(
      invoiceNumber: 'INV-PNG-2026-1002',
      billingPeriod: 'October 2026 (Monthly Consolidation)',
      poNumber: 'PO-2026-MMR-CORP-OCT',
      totalTransfers: 28,
      subtotalPgk: 38200.0,
      gstPgk: 3820.0,
      totalPgk: 42020.0,
      status: InvoiceStatus.paid,
      issueDate: DateTime.now().subtract(const Duration(days: 34)),
      dueDate: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  /// Default contracted corporate rates
  static List<CorporateRateItem> get defaultRates => [
    const CorporateRateItem(
      routeName: 'Nadzab Airport (AYNZ) ➔ Lae City Top Town',
      airport: 'Nadzab / Tomodachi (LAE)',
      destinationZone: 'Lae Commercial / Hotel District',
      vehicleType: 'Toyota LandCruiser 79 Security Spec (B6 Armored)',
      securityLevel: 'Level 2 Armed Close Protection Protocol',
      contractedRatePgk: 1350.0,
      notes: 'Fixed corporate tariff. Includes RPNGC armed officer & 60 min flight delay standby.',
    ),
    const CorporateRateItem(
      routeName: 'Nadzab Airport (AYNZ) ➔ Lae Port Maritime Wharf',
      airport: 'Nadzab / Tomodachi (LAE)',
      destinationZone: 'Lae Maritime Port / Industrial Zone',
      vehicleType: 'Prado B6 Tactical Chaperone',
      securityLevel: 'Level 2 Armed Escort Protocol',
      contractedRatePgk: 1450.0,
      notes: 'Industrial zone routing with armed perimeter escort.',
    ),
    const CorporateRateItem(
      routeName: 'Jackson\'s Airport (POM) ➔ Waigani Government Center',
      airport: "Jackson's International (POM)",
      destinationZone: 'Waigani / The Stanley / Parliament',
      vehicleType: 'Toyota LandCruiser 200 B6 Armored',
      securityLevel: 'Level 2 Armed Escort Protocol',
      contractedRatePgk: 1650.0,
      notes: 'VIP freeway convoy routing via Poreporena corridor.',
    ),
    const CorporateRateItem(
      routeName: 'Full Day Tactical Convoy Standby (2 Vehicles + 2 Armed Officers)',
      airport: 'Nadzab / Lae Corridor',
      destinationZone: 'Morobe Province Exploration Radius',
      vehicleType: 'Lead LandCruiser 79 + Chase Prado',
      securityLevel: 'Level 3 Armed Convoy',
      contractedRatePgk: 4200.0,
      billingUnit: 'Per Day (10 Hours)',
      notes: 'Dedicated mobile escort for mining and infrastructure field delegations.',
    ),
  ];

  /// Stream corporate bookings from Firestore
  Stream<List<CorporateBooking>> streamCorporateBookings() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return defaultBookings;
      }
      final list = <CorporateBooking>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          list.add(CorporateBooking.fromJson(data));
        } catch (_) {}
      }
      return list.isNotEmpty ? list : defaultBookings;
    });
  }

  /// Create a new corporate booking in Firestore
  Future<CorporateBooking> createCorporateBooking({
    required String leadPassenger,
    required int passengerCount,
    required String flightNumber,
    required String airportName,
    required String pickupLocation,
    required String destination,
    required DateTime scheduledPickup,
    required String vehicleType,
    required String escortLevel,
    required String poNumber,
    required String costCenter,
    required double farePgk,
    required String notes,
  }) async {
    final docRef = _firestore.collection('bookings').doc();
    final refNum = 'PNG-TR-${DateTime.now().millisecondsSinceEpoch % 100000}';

    final booking = CorporateBooking(
      id: docRef.id,
      refNumber: refNum,
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
      status: CorporateBookingStatus.approved,
      approvedBy: 'Corporate Travel Portal',
      approvedAt: DateTime.now(),
      notes: notes,
    );

    try {
      await docRef.set({
        'name': refNum,
        'passenger_name': leadPassenger,
        'passenger_count': passengerCount,
        'flight_number': flightNumber,
        'airport_name': airportName,
        'pickup_location': pickupLocation,
        'destination': destination,
        'pickup_datetime': scheduledPickup.toIso8601String(),
        'vehicle': vehicleType,
        'escort_level': escortLevel,
        'po_number': poNumber,
        'cost_center': costCenter,
        'fare_pgk': farePgk,
        'total_amount': farePgk,
        'state': 'dispatched',
        'security_required': escortLevel.contains('ARMED'),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return booking;
  }

  /// Update approval status in Firestore
  Future<void> updateBookingApproval({
    required String bookingId,
    required bool isApproved,
    required String approverName,
  }) async {
    try {
      final docId = bookingId.replaceAll('CB-', '').replaceAll('PNG-TR-', '');
      await _firestore.collection('bookings').doc(docId).set({
        'state': isApproved ? 'approved' : 'cancelled',
        'approved_by': approverName,
        'approved_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}

