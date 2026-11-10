import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('../types/fixtures/$name.v1.json').readAsStringSync())
        as Map<String, dynamic>;
http.Response ok(dynamic data) => http.Response(
    jsonEncode({'schemaVersion': '1', 'success': true, 'data': data}), 200);
const profile = {
  'uid': 'test-customer',
  'fullName': 'Test Customer',
  'role': 'PASSENGER'
};
const catalog = {
  'pricingConfigured': true,
  'pricingNotice': 'TEST ONLY server rates',
  'airports': [
    {'id': 'airport_nadzab_lae'}
  ],
  'vehicleCategories': [
    {
      'id': 'STANDARD_SEDAN',
      'name': 'Sedan',
      'passengerCapacity': 3,
      'luggageCapacity': 2
    },
    {
      'id': 'EXECUTIVE_SUV',
      'name': 'SUV',
      'passengerCapacity': 5,
      'luggageCapacity': 4
    }
  ]
};
Future<void> reach(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(target, 250,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final role in ['PASSENGER', 'DISPATCHER', 'DRIVER', 'SUPERVISOR']) {
    testWidgets('$role login validates input and blocks repeated submissions',
        (tester) async {
      final pending = Completer<void>();
      int calls = 0;
      await tester.pumpWidget(MaterialApp(
          home: DemoLoginPanel(
              role: role,
              onLogin: (e, p) {
                calls++;
                return pending.future;
              },
              onRegister: (n, e, p, ph) async {})));
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(calls, 0);
      await tester.enterText(
          find.byType(TextFormField).at(0), 'staff@example.invalid');
      await tester.enterText(
          find.byType(TextFormField).at(1), 'test-password-only');
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls, 1);
      pending.completeError(
          ApiException('NETWORK_ERROR', 'Demo services unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('Demo services unavailable'), findsOneWidget);
      expect(find.textContaining('No live payment collection'), findsOneWidget);
      expect(find.text('Create a customer account'),
          role == 'PASSENGER' ? findsOneWidget : findsNothing);
    });
  }
  testWidgets(
      'customer quote and uncertain booking retry retain the same intent',
      (tester) async {
    final sent = <Map<String, dynamic>>[];
    BookingV1? result;
    final client = PngApiClient(client: MockClient((request) async {
      if (request.url.path.endsWith('/quotes')) return ok(fixture('quotation'));
      if (request.url.path.endsWith('/bookings')) {
        sent.add(jsonDecode(request.body) as Map<String, dynamic>);
        if (sent.length == 1) throw const SocketException('Lost response');
        return ok(fixture('booking'));
      }
      throw StateError('Unexpected request');
    }));
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await Navigator.push<BookingV1>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DemoBookingForm(
                                  api: client,
                                  profile: profile,
                                  catalog: catalog)));
                    },
                    child: const Text('Open booking'))))));
    await tester.tap(find.text('Open booking'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'TEST destination Lae');
    await reach(tester, 'Get server quote');
    expect(find.text('PGK 123.45'), findsOneWidget);
    await reach(tester, 'Confirm demo reservation');
    expect(sent.length, 1);
    await tester.scrollUntilVisible(find.textContaining('result is uncertain'), -250,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('result is uncertain'), findsOneWidget);
    await reach(tester, 'Retry same reservation');
    expect(sent.length, 2);
    expect(sent[0], sent[1]);
    expect(sent[0].containsKey('pricing'), isFalse);
    expect(result?.id, 'BK-test-only');
    expect(find.text('Open booking'), findsOneWidget);
  });
  testWidgets('history uses backend records and keeps payment separate',
      (tester) async {
    final record = fixture('booking')..['status'] = 'COMPLETED';
    final api = PngApiClient(
        client: MockClient((r) async =>
            ok(r.url.path.endsWith('/config') ? catalog : [record])));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DemoBookings(api: api, profile: profile))));
    await tester.pumpAndSettle();
    expect(find.text('No reservations in this view.'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Payment: Pending'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // disposes polling timer
  });
  testWidgets('PNG time and integer minor-unit display are stable',
      (tester) async {
    expect(pngTime('2030-01-01T16:30:00Z'), '02 Jan 2030, 02:30 PNG');
    expect(pgk(12345), 'PGK 123.45');
  });
}
