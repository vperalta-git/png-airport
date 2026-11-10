import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_flutter_core/offline/offline_demo_store.dart';
import 'package:png_transfer_flutter_core/services/png_api_client.dart';

class FailingPersistence extends MemoryDemoPersistence {
  bool fail = false;
  @override
  Future<void> write(String value) async {
    if (fail) throw const FileSystemException('Full disk');
    await super.write(value);
  }
}

void main() {
  late MemoryDemoPersistence disk;
  late OfflineDemoStore store;
  const customer = 'offline-customer',
      control = 'offline-control',
      driver = 'offline-driver',
      secondDriver = 'offline-driver-2',
      manager = 'offline-supervisor';
  setUp(() async {
    disk = MemoryDemoPersistence();
    store = await OfflineDemoStore.open(disk);
  });
  tearDown(() => store.dispose());
  Future<Map<String, dynamic>> firstRequested() async =>
      Map<String, dynamic>.from(
          (await store.get(customer, '/api/v1/bookings') as List)
              .firstWhere((b) => b['status'] == 'BOOKING_REQUESTED'));
  Future<Map<String, dynamic>> reserve(
      {String direction = 'INBOUND_AIRPORT_TO_CITY'}) async {
    final quote = await store.mutate(customer, 'POST', '/api/v1/quotes', {
      'input': {
        'airportId': 'airport_nadzab_lae',
        'direction': direction,
        'vehicleCategory': 'STANDARD_SEDAN',
        'securityEscortType': 'NONE',
        'pickupDateTime': DateTime.fromMillisecondsSinceEpoch(
                DateTime.now().millisecondsSinceEpoch,
                isUtc: true)
            .add(const Duration(hours: 2))
            .toIso8601String(),
        'destinationAddress': 'DEMO Test Lae',
        'passengerCount': 1,
        'luggageCount': 1
      }
    });
    return Map<String, dynamic>.from(
        await store.mutate(customer, 'POST', '/api/v1/bookings', {
      'quotationId': quote['id'],
      'idempotencyKey': quote['id'],
      'paymentMethod': 'CASH_ON_BOARD',
      'passengers': [
        {'fullName': 'Demo passenger'}
      ]
    }));
  }

  test(
      'offline departure has its own queue and verifies pickup at the customer address',
      () async {
    var b = await reserve(direction: 'OUTBOUND_CITY_TO_AIRPORT');
    final id = b['id'];
    b = Map<String, dynamic>.from(
        await store.mutate(control, 'POST', '/api/v1/dispatch/$id/assign', {
      'driverId': secondDriver,
      'vehicleId': 'offline-sedan-2',
      'expectedRevision': b['revision']
    }));
    b = Map<String, dynamic>.from(await store
        .mutate(secondDriver, 'POST', '/api/v1/dispatch/$id/acknowledge', {
      'inspection': {
        'seatbelts': true,
        'tyres': true,
        'fuel': true,
        'radio': true
      },
      'expectedRevision': b['revision']
    }));
    b = Map<String, dynamic>.from(await store.mutate(
        secondDriver,
        'PATCH',
        '/api/v1/bookings/$id/status',
        {'status': 'DRIVER_EN_ROUTE', 'expectedRevision': b['revision']}));
    await expectLater(
        store.mutate(secondDriver, 'PATCH', '/api/v1/bookings/$id/status',
            {'status': 'AT_AIRPORT', 'expectedRevision': b['revision']}),
        throwsA(isA<ApiException>()));
    b = Map<String, dynamic>.from(await store.mutate(
        secondDriver,
        'PATCH',
        '/api/v1/bookings/$id/status',
        {'status': 'AT_PICKUP', 'expectedRevision': b['revision']}));
    final code =
        await store.get(customer, '/api/v1/bookings/$id/pickup-credential');
    b = Map<String, dynamic>.from(await store.mutate(
        secondDriver,
        'POST',
        '/api/v1/bookings/$id/verify-passenger',
        {'code': code['code'], 'expectedRevision': b['revision']}));
    expect(b['status'], 'PASSENGER_VERIFIED');
    expect(
        (await store.get(customer, '/api/v1/bookings/departures') as List)
            .any((v) => v['id'] == id),
        isTrue);
    expect(
        (await store.get(customer, '/api/v1/bookings/arrivals') as List)
            .any((v) => v['id'] == id),
        isFalse);
  });
  test('offline fixtures, scopes and persistence require no HTTP client',
      () async {
    await HttpOverrides.runZoned(() async {
      expect((await store.get(customer, '/api/v1/bookings') as List).length, 2);
      expect(
          (await store.get(driver, '/api/v1/bookings') as List)
              .single['status'],
          'DISPATCHED');
      expect(
          (await store.get(secondDriver, '/api/v1/bookings') as List), isEmpty);
      await store.choosePersona(control);
      final restored = await OfflineDemoStore.open(disk);
      expect(restored.activeUid, control);
      expect(
          (await restored.get(customer, '/api/v1/bookings') as List).length, 2);
      restored.dispose();
    },
        createHttpClient: (_) =>
            throw StateError('Network access is forbidden'));
  });
  test(
      'full four-role workflow checks acceptance, OTP and separate payment state',
      () async {
    var b = await firstRequested();
    final id = b['id'] as String;
    Future<void> status(String target) async {
      b = Map<String, dynamic>.from(await store.mutate(
          secondDriver,
          'PATCH',
          '/api/v1/bookings/$id/status',
          {'status': target, 'expectedRevision': b['revision']}));
    }

    b = Map<String, dynamic>.from(
        await store.mutate(control, 'POST', '/api/v1/dispatch/$id/assign', {
      'driverId': secondDriver,
      'vehicleId': 'offline-sedan-2',
      'expectedRevision': b['revision']
    }));
    await expectLater(status('DRIVER_EN_ROUTE'), throwsA(isA<ApiException>()));
    b = Map<String, dynamic>.from(await store
        .mutate(secondDriver, 'POST', '/api/v1/dispatch/$id/acknowledge', {
      'inspection': {
        'seatbelts': true,
        'tyres': true,
        'fuel': true,
        'radio': true
      },
      'expectedRevision': b['revision']
    }));
    await status('DRIVER_EN_ROUTE');
    await status('AT_AIRPORT');
    await expectLater(
        status('PASSENGER_VERIFIED'), throwsA(isA<ApiException>()));
    await expectLater(
        store.get(secondDriver, '/api/v1/bookings/$id/pickup-credential'),
        throwsA(isA<ApiException>()));
    final code =
        await store.get(customer, '/api/v1/bookings/$id/pickup-credential');
    for (var i = 0; i < 5; i++) {
      await expectLater(
          store.mutate(
              secondDriver, 'POST', '/api/v1/bookings/$id/verify-passenger', {
            'code': code['code'] == '111111' ? '222222' : '111111',
            'expectedRevision': b['revision']
          }),
          throwsA(isA<ApiException>()));
    }
    expect(
        (await store.get(
            customer, '/api/v1/bookings/$id/pickup-credential'))['available'],
        false);
    final afterRestart = await OfflineDemoStore.open(disk);
    expect(
        (await afterRestart.get(
            customer, '/api/v1/bookings/$id/pickup-credential'))['available'],
        false);
    afterRestart.dispose();
    b = Map<String, dynamic>.from(await store.mutate(
        manager,
        'POST',
        '/api/v1/bookings/$id/reset-otp',
        {'reason': 'Demo locked code', 'expectedRevision': b['revision']}));
    final replacement =
        await store.get(customer, '/api/v1/bookings/$id/pickup-credential');
    expect(replacement['code'], isNot(code['code']));
    b = Map<String, dynamic>.from(await store.mutate(
        secondDriver,
        'POST',
        '/api/v1/bookings/$id/verify-passenger',
        {'code': replacement['code'], 'expectedRevision': b['revision']}));
    await expectLater(
        store.mutate(
            secondDriver,
            'POST',
            '/api/v1/bookings/$id/verify-passenger',
            {'code': replacement['code'], 'expectedRevision': b['revision']}),
        throwsA(isA<ApiException>()));
    for (final target in [
      'TRANSFER_IN_PROGRESS',
      'ARRIVED_DESTINATION',
      'COMPLETED'
    ]) {
      await status(target);
    }
    expect(b['payment']['status'], 'PENDING');
    expect(
        (await store.get(secondDriver, '/api/v1/resources/drivers') as List)
            .single['completedTrips'],
        1);
    expect(
        (await store.get(
            manager, '/api/v1/reports/dashboard'))['verifiedPayments'],
        0);
    expect(
        (await store.get(manager, '/api/v1/reports/audit') as List)
            .any((e) => e['action'] == 'PASSENGER_VERIFIED'),
        true);
  });
  test(
      'revision and concurrent resource reservations prevent conflicting actions',
      () async {
    final b = await firstRequested(), other = await reserve();
    final pending = store.mutate(
        control, 'POST', '/api/v1/dispatch/${b['id'] as String}/assign', {
      'driverId': secondDriver,
      'vehicleId': 'offline-sedan-2',
      'expectedRevision': b['revision']
    });
    final duplicate = store.mutate(
        control, 'POST', '/api/v1/dispatch/${other['id'] as String}/assign', {
      'driverId': secondDriver,
      'vehicleId': 'offline-sedan-2',
      'expectedRevision': other['revision']
    });
    await expectLater(duplicate, throwsA(isA<ApiException>()));
    await pending;
    final id = other['id'] as String;
    await expectLater(
        store.mutate(customer, 'PATCH', '/api/v1/bookings/$id/status',
            {'status': 'CANCELLED', 'expectedRevision': 999}),
        throwsA(isA<ApiException>()));
    await expectLater(
        store.mutate(customer, 'PATCH', '/api/v1/bookings/$id/status',
            {'status': 'COMPLETED', 'expectedRevision': other['revision']}),
        throwsA(isA<ApiException>()));
  });
  test('reassignment clears acceptance and old driver access', () async {
    var b = Map<String, dynamic>.from(
        (await store.get(driver, '/api/v1/bookings') as List).single);
    final id = b['id'] as String;
    b = Map<String, dynamic>.from(
        await store.mutate(driver, 'POST', '/api/v1/dispatch/$id/acknowledge', {
      'inspection': {
        'seatbelts': true,
        'tyres': true,
        'fuel': true,
        'radio': true
      },
      'expectedRevision': b['revision']
    }));
    b = Map<String, dynamic>.from(
        await store.mutate(control, 'POST', '/api/v1/dispatch/$id/assign', {
      'driverId': secondDriver,
      'vehicleId': 'offline-sedan-2',
      'expectedRevision': b['revision']
    }));
    expect(b['dispatch']['acceptedAt'], isNull);
    expect((await store.get(driver, '/api/v1/bookings') as List), isEmpty);
    await expectLater(store.get(driver, '/api/v1/bookings/$id'),
        throwsA(isA<ApiException>()));
  });
  test('practice accounts, staff, fleet and reset persist locally', () async {
    final created = await store.register({
      'fullName': 'Demo New Customer',
      'email': 'new@offline.invalid',
      'password': 'LocalExample!12345',
      'phone': '70000000'
    });
    expect(created['phone'], '+67570000000');
    expect(
        (await store.get(created['uid'], '/api/v1/bookings') as List), isEmpty);
    expect(disk.value!.contains('LocalExample!12345'), false);
    await store.signOut();
    expect(
        (await store.signIn(
            'new@offline.invalid', 'LocalExample!12345'))['uid'],
        created['uid']);
    await expectLater(store.signIn('new@offline.invalid', 'wrong'),
        throwsA(isA<ApiException>()));
    final employee = await store.mutate(manager, 'POST', '/api/v1/users', {
      'fullName': 'Demo third driver',
      'email': 'third@offline.invalid',
      'password': offlinePracticePassword,
      'role': 'DRIVER'
    });
    expect(
        (await store.get(manager, '/api/v1/resources/drivers') as List)
            .firstWhere((d) => d['id'] == employee['uid'])['onDuty'],
        false);
    await store.mutate(manager, 'PATCH',
        '/api/v1/users/${employee['uid'] as String}', {'active': false});
    await expectLater(store.get(employee['uid'], '/api/v1/bookings'),
        throwsA(isA<ApiException>()));
    await expectLater(
        store.mutate(customer, 'POST', '/api/v1/users', {'role': 'SUPERVISOR'}),
        throwsA(isA<ApiException>()));
    final vehicle =
        await store.mutate(manager, 'POST', '/api/v1/resources/vehicles', {
      'makeModel': 'DEMO extra',
      'registrationPlate': 'DEMO-04',
      'category': 'STANDARD_SEDAN'
    });
    await store.mutate(
        manager,
        'PATCH',
        '/api/v1/resources/vehicles/${vehicle['id'] as String}',
        {'status': 'MAINTENANCE'});
    await store.reset();
    expect(store.activeUid, isNull);
    expect(store.personas.length, 5);
    expect((await store.get(customer, '/api/v1/bookings') as List).length, 2);
  });
  test('failed durable writes do not report successful changes', () async {
    final failing = FailingPersistence();
    final local = await OfflineDemoStore.open(failing);
    failing.fail = true;
    final original = jsonDecode(failing.value!);
    await expectLater(
        local.register({
          'fullName': 'Not saved',
          'email': 'not-saved@offline.invalid',
          'password': offlinePracticePassword
        }),
        throwsA(isA<ApiException>()));
    expect(local.personas.length, 5);
    expect(jsonDecode(failing.value!), original);
    local.dispose();
  });
}
