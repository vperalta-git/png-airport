import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_flutter_core/models/contracts_v1.dart';
import 'package:png_transfer_flutter_core/offline/offline_demo_store.dart';
import 'package:png_transfer_flutter_core/services/png_api_client.dart';

void main() {
  test(
      'shared typed client stays offline and retries the same quoted reservation',
      () async {
    await HttpOverrides.runZoned(() async {
      final disk = MemoryDemoPersistence(),
          store = await OfflineDemoStore.open(MemoryDemoPersistence());
      final client = OfflineDemoClient(store, 'offline-customer');
      final time = DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch,
              isUtc: true)
          .add(const Duration(hours: 1))
          .toIso8601String();
      final quote = await client.requestQuotationV1(TransferInputV1.fromJson({
        'airportId': 'airport_nadzab_lae',
        'direction': 'INBOUND_AIRPORT_TO_CITY',
        'vehicleCategory': 'STANDARD_SEDAN',
        'securityEscortType': 'NONE',
        'pickupDateTime': time,
        'destinationAddress': 'DEMO quoted test',
        'passengerCount': 1,
        'luggageCount': 1
      }));
      final intent = {
        'schemaVersion': '1',
        'quotationId': quote.id,
        'idempotencyKey': 'retry-practice-123',
        'paymentMethod': 'CASH_ON_BOARD',
        'passengers': [
          {'fullName': 'Demo person'}
        ]
      };
      final first = await client.post('/api/v1/bookings', intent);
      final again = await client.post('/api/v1/bookings', intent);
      expect(first['id'], again['id']);
      expect((await client.getBookingV1(first['id'])).paymentStatus, 'PENDING');
      await expectLater(
          client.post('/api/v1/bookings', {
            ...intent,
            'passengers': [
              {'fullName': 'Changed person'}
            ]
          }),
          throwsA(isA<ApiException>()));
      final other = await store.register({
        'fullName': 'Another demo customer',
        'email': 'other@offline.invalid',
        'password': offlinePracticePassword
      });
      await expectLater(
          OfflineDemoClient(store, other['uid']).getBookingV1(first['id']),
          throwsA(isA<ApiException>()));
      await expectLater(
          client.post(
              '/api/v1/payments/settlements/${first['id'] as String}', {}),
          throwsA(isA<ApiException>()));
      expect(disk.value, isNull);
      store.dispose();
    },
        createHttpClient: (_) =>
            throw StateError('No network client may be created'));
  });
}
