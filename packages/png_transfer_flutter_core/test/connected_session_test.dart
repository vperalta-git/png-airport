import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_flutter_core/connected/connected_session.dart';
import 'package:png_transfer_flutter_core/services/png_api_client.dart';
import 'support/connected_review_fakes.dart';

void main() {
  late ReviewIdentity identity;
  late ReviewApi api;
  late ConnectedSession session;
  setUp(() {
    identity = ReviewIdentity(currentUid: 'review-user');
    api = ReviewApi(identity);
    session = ConnectedSession(identity: identity, api: api);
  });
  tearDown(() async {
    session.dispose();
    await identity.close();
  });

  test('all core workspaces and supervisor alias use the verified profile',
      () async {
    for (final role in [
      'PASSENGER',
      'DISPATCHER',
      'DRIVER',
      'SUPERVISOR',
      'SUPER_ADMIN'
    ]) {
      api.profileRole = role;
      await session.restore();
      expect(session.profile, reviewProfile(role));
      expect(session.error, isNull);
    }
    expect(api.profileReads, 5);
  });

  test(
      'inactive, wrong identity, unsupported role and invalid scope are denied',
      () async {
    for (final invalid in [
      {...reviewProfile('DRIVER'), 'active': false},
      {...reviewProfile('DRIVER'), 'uid': 'another-user'},
      {...reviewProfile('DRIVER'), 'role': 'SECURITY'},
      {...reviewProfile('DRIVER'), 'organizationId': ''},
      {...reviewProfile('DRIVER'), 'branchId': null},
      {...reviewProfile('DRIVER'), 'airportId': ''},
      {...reviewProfile('DRIVER'), 'organizationId': '  '},
    ]) {
      api.readProfile = () async => invalid;
      await session.restore();
      expect(session.profile, isNull, reason: '$invalid');
      expect(session.error, contains('no supported, active workspace'));
    }
  });

  test('backend forbidden response never grants a workspace', () async {
    api.readProfile = () async => throw ApiException(
        'SCOPE_DENIED', 'No active account is available in this scope.',
        status: 403);
    await session.restore();
    expect(session.profile, isNull);
    expect(session.hasIdentity, isTrue);
    expect(session.error, 'No active account is available in this scope.');
  });

  test('network profile failure remains unverified and can recover on retry',
      () async {
    api.readProfile = () async =>
        throw ApiException('NETWORK_ERROR', 'Review backend unavailable');
    await session.restore();
    expect(session.profile, isNull);
    expect(session.error, 'Review backend unavailable');
    api.readProfile = null;
    await session.restore();
    expect(session.profile?['role'], 'DRIVER');
    expect(session.error, isNull);
    expect(api.profileReads, 2);
  });

  test('a pending old profile cannot restore authorization after sign-out',
      () async {
    final oldProfile = Completer<dynamic>();
    api.readProfile = () => oldProfile.future;
    final startup = session.start();
    await Future<void>.delayed(Duration.zero);
    expect(api.profileReads, 1);
    await session.signOut();
    oldProfile.complete(reviewProfile('SUPERVISOR'));
    await startup;
    expect(identity.uid, isNull);
    expect(session.profile, isNull);
    expect(session.loading, isFalse);
  });

  test('an old profile cannot overwrite a newly authenticated account',
      () async {
    final oldProfile = Completer<dynamic>();
    api.readProfile = () => identity.uid == 'review-user'
        ? oldProfile.future
        : Future.value(reviewProfile('DRIVER', uid: 'new-driver'));
    final startup = session.start();
    await Future<void>.delayed(Duration.zero);
    identity.authenticate('new-driver');
    await session.restore();
    expect(session.profile?['uid'], 'new-driver');
    oldProfile.complete(reviewProfile('SUPERVISOR'));
    await startup;
    expect(session.profile?['uid'], 'new-driver');
    expect(session.profile?['role'], 'DRIVER');
  });

  test('duplicate sign-in and profile retries share one active request',
      () async {
    identity.currentUid = null;
    final authentication = Completer<void>();
    final verification = Completer<dynamic>();
    identity.onSignIn = (_, __) => authentication.future;
    api.readProfile = () => verification.future;
    final first =
        session.signIn('review@example.invalid', 'test-only-password');
    await session.signIn('review@example.invalid', 'test-only-password');
    expect(identity.signIns, 1);
    expect(session.actionBusy, isTrue);
    authentication.complete();
    await Future<void>.delayed(Duration.zero);
    final retry = session.restore();
    expect(api.profileReads, 1);
    verification.complete(reviewProfile('DRIVER'));
    await Future.wait([first, retry]);
    expect(session.profile?['role'], 'DRIVER');
    expect(session.working, isFalse);
  });

  test(
      'logout network failure still clears local identity and reports limitation',
      () async {
    await session.start();
    api.logoutFailure = ApiException('NETWORK_ERROR', 'Backend disconnected');
    await session.signOut();
    expect(identity.uid, isNull);
    expect(identity.signOuts, 1);
    expect(session.profile, isNull);
    expect(session.error, isNull);
    expect(session.notice, contains('Signed out on this phone'));
    expect(session.notice, contains('revocation could not be confirmed'));
  });
}
