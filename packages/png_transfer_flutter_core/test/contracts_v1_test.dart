import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('../types/fixtures/$name.v1.json').readAsStringSync())
        as Map<String, dynamic>;
void main() {
  test(
      'Dart enum mirrors match the authoritative TypeScript definition fixture',
      () {
    final definition = fixture('definition');
    expect(contractRoles, definition['roles']);
    expect(bookingStatusesV1, definition['bookingStatuses']);
    expect(paymentStatusesV1, definition['paymentStatuses']);
    expect(vehicleCategoriesV1, definition['vehicleCategories']);
    expect(escortTypesV1, definition['escortTypes']);
    expect(directionsV1, definition['directions']);
  });
  test('Dart parses the same Nest/TypeScript string-ID and PGK fixtures', () {
    final booking = BookingV1.fromJson(fixture('booking')),
        quote = QuotationV1.fromJson(fixture('quotation'));
    expect(booking.id, 'BK-test-only');
    expect(booking.customerId, 'test-customer');
    expect(booking.paymentStatus, 'PENDING');
    expect(quote.pricing.totalMinor, 12345);
    expect(booking.toJson(), fixture('booking'));
    expect(quote.toJson(), fixture('quotation'));
  });
  test(
      'strict contracts reject malformed or legacy records rather than replacing fields',
      () {
    for (final patch in <Map<String, dynamic>>[
      {'id': 1},
      {'id': ''},
      {'schemaVersion': '2'},
      {'status': 'completed'},
      {'revision': 1.5},
      {'customerId': ''},
      {
        'pricing': {
          'currency': 'PGK',
          'subtotalMinor': 1.1,
          'taxMinor': 0,
          'totalMinor': 1
        }
      },
      {
        'payment': {'status': 'PAID'}
      },
      {'createdAt': '2030-01-14 00:00:00'},
    ]) {
      expect(() => BookingV1.fromJson({...fixture('booking'), ...patch}),
          throwsFormatException);
    }
    for (final time in [
      '2030-02-30T00:00:00Z',
      '2030-01-14T25:00:00Z',
      '2030-01-14T00:00:00+99:00'
    ]) {
      expect(() => timestampV1(time), throwsFormatException);
    }
  });
  test('local API origins cannot be changed to cloud or URL paths', () {
    for (final url in [
      'https://example.com',
      'http://example.com',
      'http://localhost:8080/api',
      'http://localhost:8080?next=x'
    ]) {
      expect(() => PngApiClient(baseUrl: url), throwsArgumentError);
    }
    final client = PngApiClient();
    expect(() => client.baseUrl = 'https://example.com', throwsArgumentError);
    expect(AppConfig.projectId, 'demo-aerotrans-png2');
  });
  test('structured unavailable error is preserved, not converted to a record',
      () async {
    final client = PngApiClient(
        client: MockClient(
            (_) async => http.Response(jsonEncode(fixture('error')), 503)));
    await expectLater(
        client.get('/api/v1/quotes'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'PRICING_NOT_CONFIGURED')));
  });
  test('typed API parser accepts a real versioned response', () async {
    final client = PngApiClient(
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'schemaVersion': '1',
              'success': true,
              'data': fixture('booking'),
              'error': null
            }),
            200)));
    expect((await client.getBookingV1('BK-test-only')).id, 'BK-test-only');
  });
}
