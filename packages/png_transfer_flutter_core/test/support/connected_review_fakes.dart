import 'dart:async';
import 'package:png_transfer_flutter_core/connected/connected_session.dart';
import 'package:png_transfer_flutter_core/services/png_api_client.dart';

Map<String, dynamic> reviewProfile(String role, {String uid = 'review-user'}) =>
    {
      'uid': uid,
      'role': role,
      'active': true,
      'fullName': 'Review $role',
      'email': 'review@example.invalid',
      'organizationId': 'review-organization',
      'branchId': 'review-lae',
      'airportId': 'airport_nadzab_lae',
    };

class ReviewIdentity implements ConnectedIdentity {
  String? currentUid;
  String nextUid = 'review-user';
  int signIns = 0, signOuts = 0, tokenReads = 0;
  Future<void> Function(String, String)? onSignIn;
  final events = StreamController<String?>.broadcast(sync: true);
  ReviewIdentity({this.currentUid});
  @override
  String? get uid => currentUid;
  @override
  Stream<String?> get changes => events.stream;
  void authenticate(String? value) {
    currentUid = value;
    events.add(value);
  }

  @override
  Future<void> signIn(String email, String password) async {
    signIns++;
    await onSignIn?.call(email, password);
    authenticate(nextUid);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    authenticate(null);
  }

  @override
  Future<String?> token({bool refresh = false}) async {
    tokenReads++;
    return uid == null ? null : 'test-token-for-$uid';
  }

  Future<void> close() => events.close();
}

class ReviewApi extends PngApiClient {
  final ReviewIdentity identity;
  String profileRole;
  int profileReads = 0, logoutCalls = 0;
  Future<dynamic> Function()? readProfile;
  Object? logoutFailure;
  final requestedPaths = <String>[];
  ReviewApi(this.identity, {this.profileRole = 'DRIVER'});

  @override
  Future<dynamic> get(String endpoint) async {
    requestedPaths.add(endpoint);
    switch (endpoint) {
      case '/api/v1/auth/me':
        profileReads++;
        return readProfile != null
            ? readProfile!()
            : reviewProfile(profileRole, uid: identity.uid!);
      case '/api/v1/bookings':
      case '/api/v1/resources/drivers':
      case '/api/v1/resources/vehicles':
      case '/api/v1/reports/audit':
      case '/api/v1/users':
        return <dynamic>[];
      case '/api/v1/config':
        return {
          'country': 'PG',
          'currency': 'PGK',
          'timezone': 'Pacific/Port_Moresby',
          'pricingConfigured': false,
          'pricingNotice': 'No approved pricing configured',
          'airports': [
            {'id': 'airport_nadzab_lae'}
          ],
          'vehicleCategories': [
            {
              'id': 'STANDARD_SEDAN',
              'name': 'Sedan',
              'passengerCapacity': 3,
              'luggageCapacity': 2
            }
          ]
        };
      case '/api/v1/reports/dashboard':
        return {
          'awaitingAssignment': 0,
          'activeTrips': 0,
          'completedTrips': 0,
          'pendingPayments': 0
        };
    }
    throw StateError('Unexpected test endpoint: $endpoint');
  }

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    requestedPaths.add(endpoint);
    if (endpoint == '/api/v1/auth/logout') {
      logoutCalls++;
      if (logoutFailure != null) throw logoutFailure!;
      return {'signedOut': true};
    }
    throw StateError('Unexpected test mutation: $endpoint');
  }
}
