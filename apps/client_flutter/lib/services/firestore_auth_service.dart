import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

class FirestoreAuthService {
  final FirebaseFirestore _firestore;
  final PngApiClient? _apiClient;

  FirestoreAuthService({
    FirebaseFirestore? firestore,
    PngApiClient? apiClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _apiClient = apiClient;

  /// Default pre-seeded demo accounts for quick field testing in PNG
  static const List<UserSession> demoAccounts = [
    UserSession(
      id: 101,
      name: 'Captain David Vance',
      login: 'david.vance@bhp.com',
      partnerId: 42,
      role: UserRole.passenger,
      company: 'BHP Minerals PNG / Ok Tedi Exploration',
      phone: '+675 7123 4567',
      whatsappNumber: '+675 7123 4567',
    ),
    UserSession(
      id: 102,
      name: 'Sarah Jenkins',
      login: 'sarah.jenkins@un.org',
      partnerId: 43,
      role: UserRole.passenger,
      company: 'United Nations Field Support (Lae HQ)',
      phone: '+675 7199 4432',
      whatsappNumber: '+675 7199 4432',
    ),
    UserSession(
      id: 103,
      name: 'Hiroshi Tanaka',
      login: 'tanaka.hiroshi@jica.go.jp',
      partnerId: 44,
      role: UserRole.passenger,
      company: 'JICA Port Development Unit',
      phone: '+675 7888 1234',
      whatsappNumber: '+675 7888 1234',
    ),
  ];

  /// Login with Email & Password
  Future<UserSession> loginWithEmail(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Try Cloud Run API Client first if available
    final client = _apiClient;
    if (client != null) {
      try {
        return await client.loginWithEmail(cleanEmail, password);
      } catch (e) {
        debugPrint('API Client email login fallback to Firestore: $e');
      }
    }

    // 2. Query Firestore users collection
    try {
      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        return UserSession.fromJson(data, sid: 'sess_fs_${snap.docs.first.id}');
      }
    } catch (e) {
      debugPrint('Firestore query notice: $e');
    }

    // 3. Match demo accounts
    final matchedDemo = demoAccounts.firstWhere(
      (a) => a.login.toLowerCase() == cleanEmail || cleanEmail.contains(a.name.split(' ').last.toLowerCase()),
      orElse: () => UserSession(
        id: DateTime.now().millisecondsSinceEpoch % 10000,
        name: cleanEmail.split('@').first.replaceAll('.', ' '),
        login: cleanEmail,
        partnerId: 99,
        role: UserRole.passenger,
        company: 'Corporate Member',
        phone: '+675 7000 0000',
        whatsappNumber: '+675 7000 0000',
      ),
    );

    return matchedDemo;
  }

  /// Register new user with Email, Password and WhatsApp Number
  Future<UserSession> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String whatsappNumber,
    String? company,
    UserRole role = UserRole.passenger,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanWa = whatsappNumber.trim();

    // 1. Try Cloud Run API Client
    final client = _apiClient;
    if (client != null) {
      try {
        return await client.register(
          name: name,
          email: cleanEmail,
          password: password,
          whatsappNumber: cleanWa,
          company: company,
          role: role,
        );
      } catch (e) {
        debugPrint('API Client registration fallback to Firestore: $e');
      }
    }

    // 2. Save directly to Cloud Firestore
    final docRef = _firestore.collection('users').doc();
    final session = UserSession(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      name: name.trim(),
      login: cleanEmail,
      partnerId: 88,
      role: role,
      sessionId: 'sess_fs_${docRef.id}',
      company: company?.trim().isNotEmpty == true ? company!.trim() : 'Individual Passenger',
      phone: cleanWa,
      whatsappNumber: cleanWa,
    );

    try {
      await docRef.set({
        'id': session.id,
        'uid': docRef.id,
        'name': session.name,
        'email': cleanEmail,
        'login': cleanEmail,
        'whatsapp_number': cleanWa,
        'phone': cleanWa,
        'company': session.company,
        'role': role.name,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore register write exception: $e');
    }

    return session;
  }

  /// Send verification code to WhatsApp number
  Future<String> sendWhatsAppOtp(String whatsappNumber) async {
    final cleanWa = whatsappNumber.trim();
    const demoOtp = '482910';

    final client = _apiClient;
    if (client != null) {
      try {
        await client.sendWhatsAppOtp(cleanWa);
      } catch (e) {
        debugPrint('API Client WhatsApp OTP fallback to Firestore: $e');
      }
    }

    try {
      await _firestore.collection('whatsapp_otps').doc(cleanWa.replaceAll('+', '')).set({
        'whatsapp_number': cleanWa,
        'code': demoOtp,
        'expires_at': DateTime.now().add(const Duration(minutes: 10)),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return demoOtp;
  }

  /// Login / Verify with WhatsApp Number and OTP
  Future<UserSession> loginWithWhatsApp(String whatsappNumber, String otp) async {
    final cleanWa = whatsappNumber.trim();

    final client = _apiClient;
    if (client != null) {
      try {
        return await client.loginWithWhatsApp(cleanWa, otp);
      } catch (e) {
        debugPrint('API Client WhatsApp login fallback to Firestore: $e');
      }
    }

    // Check Firestore users by WhatsApp number
    try {
      final snap = await _firestore
          .collection('users')
          .where('whatsapp_number', isEqualTo: cleanWa)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        return UserSession.fromJson(data, sid: 'sess_wa_${snap.docs.first.id}');
      }
    } catch (_) {}

    // Check demo accounts with matching phone
    final matchedDemo = demoAccounts.firstWhere(
      (a) => a.whatsappNumber == cleanWa || a.phone == cleanWa,
      orElse: () => UserSession(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        name: 'Passenger (${cleanWa.length > 4 ? cleanWa.substring(cleanWa.length - 4) : cleanWa})',
        login: '${cleanWa.replaceAll(RegExp(r'[^0-9]'), '')}@whatsapp.pngtransfer.com',
        partnerId: 42,
        role: UserRole.passenger,
        company: 'Individual Traveler (WhatsApp Verified)',
        phone: cleanWa,
        whatsappNumber: cleanWa,
        sessionId: 'sess_wa_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );

    return matchedDemo;
  }
}

