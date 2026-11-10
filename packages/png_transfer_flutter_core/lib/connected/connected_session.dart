import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/contracts_v1.dart';
import '../services/png_api_client.dart';

bool _validScope(Map<dynamic, dynamic> profile) {
  try {
    for (final field in ['organizationId', 'branchId', 'airportId']) {
      documentIdV1(profile[field], field);
    }
    return true;
  } on FormatException {
    return false;
  }
}

/// Firebase supplies identity; the backend supplies the permitted workspace.
abstract class ConnectedIdentity {
  String? get uid;
  Stream<String?> get changes;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<String?> token({bool refresh = false});
}

class FirebaseConnectedIdentity implements ConnectedIdentity {
  final FirebaseAuth auth;
  FirebaseConnectedIdentity(this.auth);
  @override
  String? get uid => auth.currentUser?.uid;
  @override
  Stream<String?> get changes =>
      auth.authStateChanges().map((user) => user?.uid);
  @override
  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  @override
  Future<void> signOut() => auth.signOut();
  @override
  Future<String?> token({bool refresh = false}) async =>
      auth.currentUser?.getIdToken(refresh);
}

class ConnectedSession extends ChangeNotifier {
  final ConnectedIdentity identity;
  final PngApiClient api;
  StreamSubscription<String?>? _subscription;
  Future<void>? _profileRequest;
  String? _requestUid;
  int _generation = 0;
  bool _disposed = false, loading = false, actionBusy = false;
  Map<String, dynamic>? profile;
  String? error, notice;
  ConnectedSession({required this.identity, required this.api});
  bool get working => loading || actionBusy;
  bool get hasIdentity => identity.uid != null;

  void _publish() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    _subscription ??= identity.changes.listen((uid) {
      if (uid != identity.uid) return;
      if (actionBusy && uid != null) return;
      if (uid == null) {
        _generation++;
        _profileRequest = null;
        _requestUid = null;
        profile = null;
        loading = false;
        _publish();
      } else {
        unawaited(restore());
      }
    }, onError: (Object _) {
      _generation++;
      _profileRequest = null;
      _requestUid = null;
      profile = null;
      loading = false;
      error = 'Authentication could not be restored. Retry or sign in again.';
      _publish();
    });
    await restore();
  }

  Future<void> restore() async {
    final uid = identity.uid;
    if (uid == null) {
      _generation++;
      _profileRequest = null;
      _requestUid = null;
      profile = null;
      loading = false;
      _publish();
      return;
    }
    if (_profileRequest != null && _requestUid == uid) {
      await _profileRequest;
      return;
    }
    final version = ++_generation;
    loading = true;
    profile = null;
    error = null;
    _requestUid = uid;
    _publish();
    final request = _readProfile(uid, version);
    _profileRequest = request;
    try {
      await request;
    } finally {
      if (identical(_profileRequest, request)) _profileRequest = null;
    }
  }

  Future<void> _readProfile(String uid, int version) async {
    try {
      final token = await identity
          .token(refresh: true)
          .timeout(const Duration(seconds: 8));
      if (token == null || token.isEmpty) {
        throw ApiException('AUTH_REQUIRED', 'Please sign in again.');
      }
      final result = await api.get('/api/v1/auth/me');
      if (result is! Map ||
          result['uid'] != uid ||
          result['active'] != true ||
          !_validScope(result) ||
          !const [
            'PASSENGER',
            'DISPATCHER',
            'DRIVER',
            'SUPERVISOR',
            'SUPER_ADMIN'
          ].contains(result['role'])) {
        throw ApiException('ACCOUNT_UNAVAILABLE',
            'This account has no supported, active workspace. Contact your supervisor.');
      }
      if (!_disposed && version == _generation && identity.uid == uid) {
        profile = Map<String, dynamic>.from(result);
        error = null;
      }
    } catch (failure) {
      if (!_disposed && version == _generation) {
        profile = null;
        error = failure is ApiException
            ? failure.message
            : 'Cannot verify your account with the backend. Check the connection and retry.';
      }
    } finally {
      if (!_disposed && version == _generation) {
        loading = false;
        _publish();
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    if (working) return;
    actionBusy = true;
    error = null;
    notice = null;
    _publish();
    try {
      await identity
          .signIn(email, password)
          .timeout(const Duration(seconds: 15));
      await restore();
    } finally {
      actionBusy = false;
      _publish();
    }
  }

  Future<void> register(
      String name, String email, String password, String phone) async {
    if (working) return;
    actionBusy = true;
    error = null;
    notice = null;
    _publish();
    try {
      await api.post('/api/v1/auth/register', {
        'schemaVersion': '1',
        'fullName': name.trim(),
        'email': email.trim(),
        'password': password,
        if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      });
      await identity
          .signIn(email, password)
          .timeout(const Duration(seconds: 15));
      await restore();
    } finally {
      actionBusy = false;
      _publish();
    }
  }

  Future<void> signOut() async {
    if (actionBusy) return;
    actionBusy = true;
    ++_generation;
    _profileRequest = null;
    _requestUid = null;
    profile = null;
    loading = false;
    error = null;
    _publish();
    try {
      if (hasIdentity) {
        try {
          await api.post('/api/v1/auth/logout', {});
        } catch (_) {
          notice =
              'Signed out on this phone. Backend session revocation could not '
              'be confirmed because the server was unavailable.';
        }
      }
      await identity.signOut().timeout(const Duration(seconds: 10));
    } catch (_) {
      error =
          'Sign-out could not be completed. Retry before changing accounts.';
      notice = null;
    } finally {
      actionBusy = false;
      _publish();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }
}
