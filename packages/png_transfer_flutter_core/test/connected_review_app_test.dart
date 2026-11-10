import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_flutter_core/connected/connected_review_app.dart';
import 'package:png_transfer_flutter_core/connected/connected_session.dart';
import 'package:png_transfer_flutter_core/screens/mobile_demo_app.dart';
import 'package:png_transfer_flutter_core/services/png_api_client.dart';
import 'support/connected_review_fakes.dart';

Future<void> chooseRole(WidgetTester tester, String role) async {
  final target = find.byKey(ValueKey('connected-role-$role'));
  await tester.scrollUntilVisible(target, 180,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  late ReviewIdentity identity;
  late ReviewApi api;
  late ConnectedSession session;
  setUp(() {
    identity = ReviewIdentity();
    api = ReviewApi(identity);
    session = ConnectedSession(identity: identity, api: api);
  });
  tearDown(() async {
    session.dispose();
    await identity.close();
  });

  testWidgets('supervisor card cannot grant privileges to an actual driver',
      (tester) async {
    await tester.pumpWidget(ConnectedReviewApp(session: session));
    await tester.pumpAndSettle();
    await chooseRole(tester, 'SUPERVISOR');
    await tester.enterText(
        find.byType(TextFormField).at(0), 'driver@example.invalid');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'test-only-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('AeroTrans Driver'), findsOneWidget);
    expect(
        tester
            .widget<DemoWorkspace>(find.byType(DemoWorkspace))
            .profile['role'],
        'DRIVER');
    expect(find.byType(NavigationBar), findsNothing);
    expect(api.requestedPaths, isNot(contains('/api/v1/reports/dashboard')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'failed login retains entered fields and Back returns to all roles',
      (tester) async {
    identity.onSignIn = (_, __) async => throw ApiException(
        'INVALID_CREDENTIAL', 'Email or password is incorrect.');
    await tester.pumpWidget(ConnectedReviewApp(session: session));
    await tester.pumpAndSettle();
    await chooseRole(tester, 'PASSENGER');
    await tester.enterText(
        find.byType(TextFormField).at(0), 'customer@example.invalid');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'test-only-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(0))
            .controller
            ?.text,
        'customer@example.invalid');
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller
            ?.text,
        'test-only-password');
    await tester.tap(find.byTooltip('Back to accounts'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your workspace'), findsOneWidget);
    await chooseRole(tester, 'DRIVER');
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller
            ?.text,
        isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('changing account destroys the previous account pushed routes',
      (tester) async {
    identity.currentUid = 'review-user';
    api.profileRole = 'SUPERVISOR';
    await tester.pumpWidget(ConnectedReviewApp(session: session));
    await tester.pumpAndSettle();
    final workspace = tester.widget<DemoWorkspace>(find.byType(DemoWorkspace));
    final navigator = Navigator.of(tester.element(find.byType(DemoWorkspace)));
    unawaited(navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
            body: Center(child: Text('Previous account private detail'))))));
    await tester.pumpAndSettle();
    expect(find.text('Previous account private detail'), findsOneWidget);
    await workspace.onSwitchAccount!();
    await tester.pumpAndSettle();
    expect(identity.uid, isNull);
    expect(find.text('Previous account private detail'), findsNothing);
    expect(find.text('Choose your workspace'), findsOneWidget);
    expect(
        Navigator.of(tester.element(find.text('Choose your workspace')))
            .canPop(),
        isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('backend bootstrap failure can retry without duplicate startup',
      (tester) async {
    int attempts = 0;
    final reconnect = Completer<void>();
    await tester.pumpWidget(ConnectedReviewBootstrap(
        initialize: () async {
          attempts++;
          if (attempts == 1) throw StateError('Test backend unavailable');
          await reconnect.future;
        },
        readyBuilder: (_) => const MaterialApp(
            home: Scaffold(body: Text('Review backend ready')))));
    await tester.pumpAndSettle();
    expect(find.text('Connection needs attention'), findsOneWidget);
    expect(find.textContaining('server is unavailable'), findsOneWidget);
    final retry = tester
        .widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton))
        .onPressed!;
    retry();
    retry();
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('Connecting to review services'), findsOneWidget);
    reconnect.complete();
    await tester.pumpAndSettle();
    expect(find.text('Review backend ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
