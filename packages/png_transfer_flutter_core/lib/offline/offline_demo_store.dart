import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/contracts_v1.dart';
import '../services/png_api_client.dart';

/// In-process practice data only. Never a replacement for the NestJS backend.
abstract class OfflineDemoPersistence {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class MemoryDemoPersistence implements OfflineDemoPersistence {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    value = next;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

const offlinePracticePassword = 'DemoOnly2026!';
const offlineScope = {
  'organizationId': 'offline-demo-aerotrans',
  'branchId': 'offline-demo-lae',
  'airportId': 'airport_nadzab_lae'
};
const offlineCategories = [
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
  },
];
Map<String, dynamic> _copy(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
Never _fail(String message, [String code = 'OFFLINE_VALIDATION']) =>
    throw ApiException(code, message);
String _text(dynamic value, String name, {int max = 160}) {
  if (value is! String || value.trim().isEmpty || value.trim().length > max) {
    _fail('Enter a valid $name.');
  }
  return value.trim();
}

String _phone(dynamic value) {
  if (value == null || value == '') return '';
  var contact =
      _text(value, 'phone', max: 32).replaceAll(RegExp(r'[\s()-]'), '');
  if (RegExp(r'^\d{8}$').hasMatch(contact)) contact = '+675$contact';
  if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(contact)) {
    _fail('Use a valid +country-code phone number.');
  }
  return contact;
}

String _email(dynamic value) {
  final address = _text(value, 'email', max: 254).toLowerCase();
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
    _fail('Enter a valid email address.');
  }
  return address;
}

bool _terminal(dynamic status) =>
    ['COMPLETED', 'CLOSED', 'CANCELLED'].contains(status);
Map<String, dynamic> _laneSummary(List<dynamic> jobs) => {
      'bookings': jobs.length,
      'awaitingAssignment': jobs
          .where((b) => b['dispatch'] == null && !_terminal(b['status']))
          .length,
      'activeTrips': jobs
          .where((b) => b['dispatch'] != null && !_terminal(b['status']))
          .length,
      'completedTrips': jobs
          .where((b) => ['COMPLETED', 'CLOSED'].contains(b['status']))
          .length,
      'pendingPayments':
          jobs.where((b) => b['payment']['status'] == 'PENDING').length,
    };
const _early = [
  'BOOKING_REQUESTED',
  'AVAILABILITY_CONFIRMED',
  'CONFIRMED',
  'DISPATCHED'
];

class OfflineDemoStore extends ChangeNotifier {
  final OfflineDemoPersistence persistence;
  Map<String, dynamic> _state;
  Future<void> _tail = Future<void>.value();
  OfflineDemoStore._(this.persistence, this._state);
  static Future<OfflineDemoStore> open(
      OfflineDemoPersistence persistence) async {
    final raw = await persistence.read();
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['formatVersion'] != 1 ||
          data['marker'] != 'AEROTRANS_OFFLINE_ONLY') {
        _fail(
            'Unsupported offline practice data. Reset only this offline demo to start again.');
      }
      for (final key in [
        'users',
        'vehicles',
        'quotations',
        'bookings',
        'credentials',
        'requests'
      ]) {
        if (data[key] is! Map) {
          _fail('Practice data is unreadable. Reset the offline demo.');
        }
      }
      for (final b in (data['bookings'] as Map).values) {
        BookingV1.fromJson(Map<String, dynamic>.from(b as Map));
      }
      return OfflineDemoStore._(persistence, data);
    }
    final store = OfflineDemoStore._(persistence, {
      'formatVersion': 1,
      'marker': 'AEROTRANS_OFFLINE_ONLY',
      'sequence': 0,
      'users': <String, dynamic>{},
      'vehicles': <String, dynamic>{},
      'quotations': <String, dynamic>{},
      'bookings': <String, dynamic>{},
      'credentials': <String, dynamic>{},
      'requests': <String, dynamic>{},
      'events': <dynamic>[],
      'audit': <dynamic>[],
      'activeUid': null
    });
    store._seed(store._state);
    await persistence.write(jsonEncode(store._state));
    return store;
  }

  String _now() =>
      DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch,
              isUtc: true)
          .toIso8601String();
  String _id(Map<String, dynamic> s, String prefix) {
    s['sequence'] = (s['sequence'] as int) + 1;
    return '$prefix-${s['sequence'].toString().padLeft(5, '0')}';
  }

  Map<String, dynamic> get catalog => {
        'country': 'PG',
        'currency': 'PGK',
        'timezone': 'Pacific/Port_Moresby',
        'demoMode': true,
        'offline': true,
        'airports': [
          {
            'id': 'airport_nadzab_lae',
            'iata': 'LAE',
            'name': 'Nadzab Tomodachi International Airport',
            'timezone': 'Pacific/Port_Moresby'
          }
        ],
        'vehicleCategories': offlineCategories,
        'pricingConfigured': true,
        'pricingNotice':
            'OFFLINE PRACTICE: local test fares only. Not approved commercial prices. No money is collected.'
      };
  List<Map<String, dynamic>> get personas => (_state['users'] as Map)
      .values
      .map((u) => _public(Map<String, dynamic>.from(u as Map)))
      .where((u) => u['active'] == true)
      .toList();
  String? get activeUid => _state['activeUid'] as String?;
  Map<String, dynamic>? profile(String? uid) {
    final user = (_state['users'] as Map)[uid];
    return user == null
        ? null
        : _public(Map<String, dynamic>.from(user as Map));
  }

  Map<String, dynamic> _public(Map<String, dynamic> u) =>
      Map<String, dynamic>.from(u)
        ..remove('passwordDigest')
        ..remove('passwordSalt');
  String _digest(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
  Map<String, dynamic> _user(Map<String, dynamic> s, String uid) {
    final u = (s['users'] as Map)[uid];
    if (u == null || u['active'] != true) {
      _fail(
          'This practice account is unavailable. Choose another demo persona.',
          'OFFLINE_ACCOUNT');
    }
    return u as Map<String, dynamic>;
  }

  void _staff(Map<String, dynamic> u, {bool manager = false}) {
    if (!(manager
            ? ['SUPERVISOR', 'SUPER_ADMIN']
            : ['DISPATCHER', 'SUPERVISOR', 'SUPER_ADMIN'])
        .contains(u['role'])) {
      _fail('This role cannot perform that action.', 'OFFLINE_FORBIDDEN');
    }
  }

  bool _visible(Map<String, dynamic> u, Map<String, dynamic> b) {
    if (u['role'] == 'PASSENGER') return b['customerId'] == u['uid'];
    if (u['role'] == 'DRIVER') {
      return b['dispatch']?['assignedDriverId'] == u['uid'];
    }
    return ['DISPATCHER', 'SUPERVISOR', 'SUPER_ADMIN'].contains(u['role']);
  }

  Map<String, dynamic> _booking(
      Map<String, dynamic> s, String id, Map<String, dynamic> u) {
    final b = (s['bookings'] as Map)[id];
    if (b == null || !_visible(u, b as Map<String, dynamic>)) {
      _fail('Reservation not found for this practice account.',
          'OFFLINE_NOT_FOUND');
    }
    return b;
  }

  void _revision(Map<String, dynamic> b, dynamic expected) {
    if (expected != b['revision']) {
      _fail('This reservation changed. Refresh and try again.',
          'REVISION_CONFLICT');
    }
  }

  String? _busy(Map<String, dynamic> s, String resourceId, String key) {
    for (final raw in (s['bookings'] as Map).values) {
      final b = raw as Map;
      if (!_terminal(b['status']) && b['dispatch']?[key] == resourceId) {
        return b['id'] as String;
      }
    }
    return null;
  }

  void _event(Map<String, dynamic> s, Map<String, dynamic> b,
      Map<String, dynamic> u, String description) {
    final e = {
      'id': _id(s, 'event'),
      'bookingId': b['id'],
      ...offlineScope,
      'actorId': u['uid'],
      'actorRole': u['role'],
      'description': description,
      'timestamp': _now(),
      'revision': b['revision'],
      'toStatus': b['status']
    };
    (s['events'] as List).add(e);
    (s['audit'] as List)
        .insert(0, {...e, 'action': description, 'resourceId': b['id']});
  }

  void _audit(Map<String, dynamic> s, Map<String, dynamic> u, String action,
      String resourceId) {
    (s['audit'] as List).insert(0, {
      'id': _id(s, 'audit'),
      ...offlineScope,
      'actorId': u['uid'],
      'action': action,
      'resourceId': resourceId,
      'timestamp': _now()
    });
  }

  void _changed(Map<String, dynamic> s, Map<String, dynamic> b,
      Map<String, dynamic> u, String action) {
    b['revision'] = (b['revision'] as int) + 1;
    b['updatedAt'] = _now();
    BookingV1.fromJson(b);
    _event(s, b, u, action);
  }

  Future<T> _write<T>(T Function(Map<String, dynamic>) action) {
    final next = _tail.then((_) async {
      final candidate = _copy(_state);
      final result = action(candidate);
      try {
        await persistence.write(jsonEncode(candidate));
      } catch (_) {
        _fail(
            'Practice changes could not be saved on this phone. Free some storage and retry.',
            'OFFLINE_SAVE_FAILED');
      }
      _state = candidate;
      notifyListeners();
      return result is Map
          ? _copy(Map<String, dynamic>.from(result)) as T
          : result;
    });
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<void> reset() => _write((s) {
        s.clear();
        s.addAll({
          'formatVersion': 1,
          'marker': 'AEROTRANS_OFFLINE_ONLY',
          'sequence': 0,
          'users': <String, dynamic>{},
          'vehicles': <String, dynamic>{},
          'quotations': <String, dynamic>{},
          'bookings': <String, dynamic>{},
          'credentials': <String, dynamic>{},
          'requests': <String, dynamic>{},
          'events': <dynamic>[],
          'audit': <dynamic>[],
          'activeUid': null
        });
        _seed(s);
      });
  Future<void> choosePersona(String uid) => _write((s) {
        _user(s, uid);
        s['activeUid'] = uid;
      });
  Future<void> signOut() => _write((s) {
        s['activeUid'] = null;
      });
  Future<Map<String, dynamic>> signIn(String address, String password) =>
      _write((s) {
        final email = _email(address);
        final found = (s['users'] as Map)
            .values
            .where((u) => u['email'] == email && u['active'] == true)
            .toList();
        if (found.isEmpty ||
            _digest(found.first['passwordSalt'] as String, password) !=
                found.first['passwordDigest']) {
          _fail('Practice email or password is incorrect.', 'OFFLINE_LOGIN');
        }
        s['activeUid'] = found.first['uid'];
        return _public(Map<String, dynamic>.from(found.first));
      });
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) =>
      _write((s) {
        final u = _createUser(s, data, 'PASSENGER');
        s['activeUid'] = u['uid'];
        return _public(u);
      });
  Map<String, dynamic> _createUser(
      Map<String, dynamic> s, Map<String, dynamic> data, String role,
      {String? uid}) {
    final name = _text(data['fullName'], 'full name'),
        email = _email(data['email']),
        password = data['password'];
    if (password is! String || password.length < 10 || password.length > 128) {
      _fail('Use 10 to 128 characters for the practice password.');
    }
    if ((s['users'] as Map).values.any((u) => u['email'] == email)) {
      _fail('This practice email is already registered.');
    }
    final salt = List.generate(
            16,
            (_) =>
                Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    final user = {
      'uid': uid ?? _id(s, 'user'),
      ...offlineScope,
      'role': role,
      'fullName': name,
      'email': email,
      'phone': _phone(data['phone']),
      'active': true,
      'available': false,
      'createdAt': _now(),
      'passwordSalt': salt,
      'passwordDigest': _digest(salt, password)
    };
    (s['users'] as Map)[user['uid']] = user;
    return user;
  }

  void _seed(Map<String, dynamic> s) {
    for (final row in [
      ['offline-customer', 'PASSENGER', 'Demo Customer', 'customer'],
      ['offline-control', 'DISPATCHER', 'Demo Control Room', 'control'],
      ['offline-driver', 'DRIVER', 'Demo Driver', 'driver'],
      ['offline-driver-2', 'DRIVER', 'Demo Driver Two', 'driver2'],
      ['offline-supervisor', 'SUPERVISOR', 'Demo Supervisor', 'supervisor']
    ]) {
      final seeded = _createUser(
          s,
          {
            'fullName': row[2],
            'email': '${row[3]}@offline.aerotrans.invalid',
            'password': offlinePracticePassword
          },
          row[1],
          uid: row[0]);
      if (row[1] == 'DRIVER') seeded['available'] = true;
    }
    for (final row in [
      ['offline-sedan', 'DEMO Sedan', 'STANDARD_SEDAN', 'DEMO-LAE-01', 3, 2],
      [
        'offline-sedan-2',
        'DEMO Sedan Two',
        'STANDARD_SEDAN',
        'DEMO-LAE-02',
        3,
        2
      ],
      ['offline-suv', 'DEMO SUV', 'EXECUTIVE_SUV', 'DEMO-LAE-03', 5, 4]
    ]) {
      final v = {
        'id': row[0],
        ...offlineScope,
        'makeModel': row[1],
        'category': row[2],
        'registrationPlate': row[3],
        'passengerCapacity': row[4],
        'luggageCapacity': row[5],
        'status': 'ACTIVE',
        'createdAt': _now()
      };
      (s['vehicles'] as Map)[v['id']] = v;
    }
    final customer = _user(s, 'offline-customer');
    for (var index = 0; index < 2; index++) {
      final quote = _quote(s, customer, {
        'airportId': 'airport_nadzab_lae',
        'direction': 'INBOUND_AIRPORT_TO_CITY',
        'vehicleCategory': 'STANDARD_SEDAN',
        'securityEscortType': 'NONE',
        'pickupDateTime': DateTime.fromMillisecondsSinceEpoch(
                DateTime.now().millisecondsSinceEpoch,
                isUtc: true)
            .add(Duration(hours: index + 1))
            .toIso8601String(),
        'destinationAddress': index == 0
            ? 'DEMO Lae city pickup walkthrough'
            : 'DEMO Lae hotel transfer',
        'passengerCount': 1,
        'luggageCount': 1
      });
      final booking = _reserve(s, customer, {
        'quotationId': quote['id'],
        'idempotencyKey': 'seed-$index',
        'paymentMethod': 'CASH_ON_BOARD',
        'passengers': [
          {'fullName': 'Demo Customer'}
        ]
      });
      if (index == 1) {
        _assign(s, _user(s, 'offline-control'),
            (s['bookings'] as Map)[booking['id']], {
          'driverId': 'offline-driver',
          'vehicleId': 'offline-sedan',
          'expectedRevision': booking['revision']
        });
      }
    }
  }

  Map<String, dynamic> _quote(Map<String, dynamic> s, Map<String, dynamic> u,
      Map<String, dynamic> raw) {
    if (u['role'] != 'PASSENGER') {
      _fail('Only a customer can request a practice quote.');
    }
    final input = TransferInputV1.fromJson(raw).toJson();
    if (input['airportId'] != 'airport_nadzab_lae' ||
        input['securityEscortType'] != 'NONE') {
      _fail(
          'This demo supports Lae / Nadzab transfers without security escorts.');
    }
    if (DateTime.parse(input['pickupDateTime'] as String).toUtc().isBefore(
        DateTime.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch,
            isUtc: true))) {
      _fail('Choose a future PNG pickup time.');
    }
    final category = offlineCategories
        .where((c) => c['id'] == input['vehicleCategory'])
        .toList();
    if (category.isEmpty ||
        input['passengerCount'] >
            (category.first['passengerCapacity'] as int) ||
        input['luggageCount'] > (category.first['luggageCapacity'] as int)) {
      _fail('Passenger or luggage count exceeds this demo category.');
    }
    final fare = input['vehicleCategory'] == 'STANDARD_SEDAN' ? 10000 : 15000;
    final quote = {
      'schemaVersion': '1',
      'id': _id(s, 'OFFLINE-QUO'),
      ...offlineScope,
      'customerId': u['uid'],
      'input': input,
      'pricing': {
        'currency': 'PGK',
        'subtotalMinor': fare,
        'taxMinor': 0,
        'totalMinor': fare
      },
      'rateVersion': 'OFFLINE-PRACTICE-NOT-AN-APPROVED-TARIFF',
      'createdAt': _now(),
      'expiresAt': DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch,
              isUtc: true)
          .add(const Duration(minutes: 15))
          .toIso8601String()
    };
    QuotationV1.fromJson(quote);
    (s['quotations'] as Map)[quote['id']] = quote;
    return _copy(quote);
  }

  Map<String, dynamic> _reserve(Map<String, dynamic> s, Map<String, dynamic> u,
      Map<String, dynamic> data) {
    if (u['role'] != 'PASSENGER') {
      _fail('Only the owning customer can reserve.');
    }
    final quote = (s['quotations'] as Map)[data['quotationId']];
    if (quote == null || quote['customerId'] != u['uid']) {
      _fail('Practice quote not found.');
    }
    final passengers = (data['passengers'] as List)
        .map((p) => {
              'fullName': _text(p['fullName'], 'passenger name'),
              if (p['phone'] != null) 'phone': _phone(p['phone'])
            })
        .toList();
    final intent = jsonEncode({
      'quotationId': data['quotationId'],
      'passengers': passengers,
      'paymentMethod': data['paymentMethod']
    });
    final key =
        '${u['uid'] as String}:${_text(data['idempotencyKey'], 'reservation retry key')}';
    final prior = (s['requests'] as Map)[key] ?? quote['consumed'];
    if (prior != null) {
      if (prior['intent'] != intent) {
        _fail('This quote or retry key was used for a different reservation.');
      }
      return _copy((s['bookings'] as Map)[prior['bookingId']]);
    }
    if (DateTime.parse(quote['expiresAt']).isBefore(
        DateTime.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch,
            isUtc: true))) {
      _fail('The practice quote expired. Get a new quote.');
    }
    if (passengers.length != quote['input']['passengerCount']) {
      _fail('Passenger names must match the quoted count.');
    }
    if (data['paymentMethod'] != 'CASH_ON_BOARD') {
      _fail(
          'This offline demo supports a cash preference only; no payment is collected.');
    }
    final id = _id(s, 'OFFLINE-BK');
    final b = {
      'schemaVersion': '1',
      'id': id,
      'referenceNumber': id,
      ...offlineScope,
      'customerId': u['uid'],
      'quotationId': quote['id'],
      'rateVersion': quote['rateVersion'],
      'input': _copy(quote['input']),
      'pricing': _copy(quote['pricing']),
      'passengers': passengers,
      'status': 'BOOKING_REQUESTED',
      'payment': {'status': 'PENDING', 'method': 'CASH_ON_BOARD'},
      'revision': 1,
      'createdAt': _now(),
      'updatedAt': _now()
    };
    BookingV1.fromJson(b);
    (s['bookings'] as Map)[id] = b;
    final request = {'bookingId': id, 'intent': intent};
    (s['requests'] as Map)[key] = request;
    quote['consumed'] = request;
    (s['credentials'] as Map)[id] = _credential(b);
    _event(s, b, u, 'BOOKING_REQUESTED');
    return _copy(b);
  }

  Map<String, dynamic> _credential(Map<String, dynamic> b) => {
        'code': (100000 + Random.secure().nextInt(900000)).toString(),
        'attempts': 0,
        'used': false,
        'expiresAt': DateTime.fromMillisecondsSinceEpoch(
                DateTime.now().millisecondsSinceEpoch,
                isUtc: true)
            .add(const Duration(hours: 24))
            .toIso8601String()
      };
  Map<String, dynamic> _assign(Map<String, dynamic> s, Map<String, dynamic> u,
      Map<String, dynamic> b, Map<String, dynamic> data) {
    _staff(u);
    if (!_early.contains(b['status'])) _fail('Reassign only before departure.');
    if (b['status'] == 'DISPATCHED' &&
        b['dispatch']?['assignedDriverId'] == data['driverId'] &&
        b['dispatch']?['assignedVehicleId'] == data['vehicleId']) {
      return _copy(b);
    }
    _revision(b, data['expectedRevision']);
    final driver = _user(s, data['driverId'] as String),
        vehicle = (s['vehicles'] as Map)[data['vehicleId']];
    if (driver['role'] != 'DRIVER' ||
        driver['available'] != true ||
        vehicle == null ||
        vehicle['status'] != 'ACTIVE' ||
        vehicle['category'] != b['input']['vehicleCategory']) {
      _fail('Choose an active on-duty driver and matching vehicle.');
    }
    if (vehicle['passengerCapacity'] < b['input']['passengerCount'] ||
        vehicle['luggageCapacity'] < b['input']['luggageCount']) {
      _fail('Vehicle capacity is insufficient.');
    }
    final driverBusy = _busy(s, driver['uid'] as String, 'assignedDriverId'),
        vehicleBusy = _busy(s, vehicle['id'] as String, 'assignedVehicleId');
    if (driverBusy != null && driverBusy != b['id'] ||
        vehicleBusy != null && vehicleBusy != b['id']) {
      _fail('Driver or vehicle is already assigned to another active trip.');
    }
    final reassign = b['dispatch'] != null;
    if (!reassign) {
      b['status'] = 'AVAILABILITY_CONFIRMED';
      _event(s, b, u, 'AVAILABILITY_CONFIRMED');
      b['status'] = 'CONFIRMED';
      _event(s, b, u, 'BOOKING_CONFIRMED');
    }
    b['dispatch'] = {
      'assignedDriverId': driver['uid'],
      'assignedVehicleId': vehicle['id']
    };
    b['status'] = 'DISPATCHED';
    _changed(s, b, u, reassign ? 'REASSIGNED' : 'DISPATCHED');
    return _copy(b);
  }

  List<Map<String, dynamic>> _drivers(
      Map<String, dynamic> s, Map<String, dynamic> u) {
    if (u['role'] != 'DRIVER') _staff(u);
    return (s['users'] as Map)
        .values
        .where((d) =>
            d['role'] == 'DRIVER' &&
            (u['role'] != 'DRIVER' || d['uid'] == u['uid']))
        .map((d) {
      final busy = _busy(s, d['uid'] as String, 'assignedDriverId');
      return <String, dynamic>{
        'id': d['uid'],
        'fullName': d['fullName'],
        'phone': d['phone'],
        'active': d['active'],
        'onDuty': d['available'] == true,
        'available':
            d['active'] == true && d['available'] == true && busy == null,
        'activeBookingId': busy,
        'completedTrips': (s['bookings'] as Map)
            .values
            .where((b) =>
                b['dispatch']?['assignedDriverId'] == d['uid'] &&
                ['COMPLETED', 'CLOSED'].contains(b['status']))
            .length
      };
    }).toList();
  }

  List<Map<String, dynamic>> _vehicles(
      Map<String, dynamic> s, Map<String, dynamic> u) {
    _staff(u);
    return (s['vehicles'] as Map).values.map((v) {
      final busy = _busy(s, v['id'] as String, 'assignedVehicleId');
      return <String, dynamic>{
        ...v,
        'available': v['status'] == 'ACTIVE' && busy == null,
        'activeBookingId': busy
      };
    }).toList();
  }

  Future<dynamic> get(String uid, String path) async {
    await _tail;
    final s = _state, u = _user(s, uid);
    final parts = _parts(path);
    if (path == '/api/v1/config') return _copy(catalog);
    if (path == '/api/v1/auth/me') return _public(_copy(u));
    if ([
      '/api/v1/bookings',
      '/api/v1/bookings/arrivals',
      '/api/v1/bookings/departures'
    ].contains(path)) {
      return (s['bookings'] as Map)
          .values
          .where((b) => _visible(u, b))
          .where((b) =>
              path == '/api/v1/bookings' ||
              b['input']['direction'] ==
                  (path.endsWith('/departures')
                      ? 'OUTBOUND_CITY_TO_AIRPORT'
                      : 'INBOUND_AIRPORT_TO_CITY'))
          .map((b) => _copy(b))
          .toList()
          .reversed
          .toList();
    }
    if (path == '/api/v1/users') {
      _staff(u, manager: true);
      return (s['users'] as Map).values.map((v) => _public(_copy(v))).toList();
    }
    if (path == '/api/v1/resources/drivers') return _drivers(s, u);
    if (path == '/api/v1/resources/vehicles') return _vehicles(s, u);
    if (path == '/api/v1/reports/audit') {
      _staff(u, manager: true);
      return (s['audit'] as List).map((e) => _copy(e)).take(200).toList();
    }
    if (path == '/api/v1/reports/dashboard') {
      _staff(u);
      final jobs = (s['bookings'] as Map).values.toList();
      return {
        'arrivals': _laneSummary(jobs
            .where((b) => b['input']['direction'] == 'INBOUND_AIRPORT_TO_CITY')
            .toList()),
        'departures': _laneSummary(jobs
            .where((b) => b['input']['direction'] == 'OUTBOUND_CITY_TO_AIRPORT')
            .toList()),
        'bookings': jobs.length,
        'awaitingAssignment': jobs
            .where((b) => b['dispatch'] == null && !_terminal(b['status']))
            .length,
        'activeTrips': jobs
            .where((b) => b['dispatch'] != null && !_terminal(b['status']))
            .length,
        'completedTrips': jobs
            .where((b) => ['COMPLETED', 'CLOSED'].contains(b['status']))
            .length,
        'cancelledTrips': jobs.where((b) => b['status'] == 'CANCELLED').length,
        'pendingPayments':
            jobs.where((b) => b['payment']['status'] == 'PENDING').length,
        'verifiedPayments': 0,
        'availableDrivers':
            _drivers(s, u).where((d) => d['available'] == true).length,
        'availableVehicles':
            _vehicles(s, u).where((v) => v['available'] == true).length
      };
    }
    if (parts.length >= 2 && parts[0] == 'bookings') {
      final b = _booking(s, parts[1], u);
      if (parts.length == 2) return _copy(b);
      if (parts[2] == 'pickup-credential') {
        if (u['role'] != 'PASSENGER' || u['uid'] != b['customerId']) {
          _fail('Only the owning demo customer can see their pickup code.');
        }
        final c = (s['credentials'] as Map)[b['id']];
        if (_terminal(b['status']) ||
            c == null ||
            c['used'] == true ||
            c['attempts'] >= 5 ||
            DateTime.parse(c['expiresAt']).isBefore(
                DateTime.fromMillisecondsSinceEpoch(
                    DateTime.now().millisecondsSinceEpoch,
                    isUtc: true))) {
          return {'available': false};
        }
        return {
          'available': true,
          'code': c['code'],
          'expiresAt': c['expiresAt']
        };
      }
      if (parts[2] == 'details') {
        final d = b['dispatch'],
            driver =
                d == null ? null : (s['users'] as Map)[d['assignedDriverId']],
            vehicle = d == null
                ? null
                : (s['vehicles'] as Map)[d['assignedVehicleId']];
        return {
          'booking': _copy(b),
          'assignmentInfo': d == null
              ? null
              : {
                  'driverName': driver?['fullName'],
                  'driverPhone': driver?['phone'],
                  'vehicleName': vehicle?['makeModel'],
                  'registrationPlate': vehicle?['registrationPlate']
                },
          'events': (s['events'] as List)
              .where((e) => e['bookingId'] == b['id'])
              .map((e) => _copy(e))
              .toList()
        };
      }
    }
    _fail('This feature is not included in the offline walkthrough.',
        'OFFLINE_UNSUPPORTED');
  }

  List<String> _parts(String path) {
    if (!path.startsWith('/api/v1/') ||
        path.contains('..') ||
        path.contains('?') ||
        path.contains('#')) {
      _fail('Unsupported practice path.');
    }
    return path.substring(8).split('/');
  }

  Future<dynamic> mutate(
      String uid, String method, String path, Map<String, dynamic> data) async {
    final outcome = await _write((s) => _mutation(s, uid, method, path, data));
    if (outcome is Map && outcome['_error'] != null) {
      _fail(outcome['_error'] as String, 'OFFLINE_OTP');
    }
    return outcome;
  }

  dynamic _mutation(Map<String, dynamic> s, String uid, String method,
      String path, Map<String, dynamic> data) {
    final u = _user(s, uid), p = _parts(path);
    if (method == 'POST' && path == '/api/v1/quotes') {
      return _quote(s, u, Map<String, dynamic>.from(data['input']));
    }
    if (method == 'POST' && path == '/api/v1/bookings') {
      return _reserve(s, u, data);
    }
    if (method == 'POST' && path == '/api/v1/auth/logout') {
      s['activeUid'] = null;
      return {'revoked': false, 'offline': true};
    }
    if (path == '/api/v1/users' && method == 'POST') {
      _staff(u, manager: true);
      if (!['DRIVER', 'DISPATCHER', 'SUPERVISOR'].contains(data['role'])) {
        _fail('Choose a supported staff role.');
      }
      final employee = _createUser(s, data, data['role']);
      _audit(s, u, 'STAFF_CREATED', employee['uid'] as String);
      return _public(employee);
    }
    if (p.length == 2 && p[0] == 'users' && method == 'PATCH') {
      _staff(u, manager: true);
      final employee = (s['users'] as Map)[p[1]];
      if (employee == null) _fail('Practice account not found.');
      if (data['fullName'] != null) {
        employee['fullName'] = _text(data['fullName'], 'full name');
      }
      if (data['phone'] != null) employee['phone'] = _phone(data['phone']);
      if (data['active'] != null) {
        if (data['active'] is! bool) _fail('Invalid account status.');
        if (p[1] == uid && data['active'] == false) {
          _fail('You cannot suspend your own practice account.');
        }
        if (data['active'] == false &&
            _busy(s, p[1], 'assignedDriverId') != null) {
          _fail('Reassign the active trip before suspending this driver.');
        }
        employee['active'] = data['active'];
      }
      _audit(s, u, 'ACCOUNT_UPDATED', p[1]);
      return _public(_copy(employee));
    }
    if (path == '/api/v1/resources/vehicles' && method == 'POST') {
      _staff(u, manager: true);
      final category =
          offlineCategories.where((c) => c['id'] == data['category']).toList();
      if (category.isEmpty) _fail('Choose a configured category.');
      final plate =
          _text(data['registrationPlate'], 'registration plate', max: 30)
              .toUpperCase();
      if ((s['vehicles'] as Map)
          .values
          .any((v) => v['registrationPlate'] == plate)) {
        _fail('Registration plate is already recorded.');
      }
      final v = {
        'id': _id(s, 'OFFLINE-VEH'),
        ...offlineScope,
        'makeModel': _text(data['makeModel'], 'vehicle name'),
        'registrationPlate': plate,
        'category': data['category'],
        'passengerCapacity': category.first['passengerCapacity'],
        'luggageCapacity': category.first['luggageCapacity'],
        'status': 'ACTIVE',
        'createdAt': _now()
      };
      (s['vehicles'] as Map)[v['id']] = v;
      _audit(s, u, 'VEHICLE_CREATED', v['id'] as String);
      return _copy(v);
    }
    if (p.length == 3 && p[0] == 'resources' && method == 'PATCH') {
      if (p[1] == 'drivers') {
        if (u['role'] != 'DRIVER') {
          _staff(u, manager: true);
        } else if (p[2] != uid) {
          _fail('Only your own duty can be changed.');
        }
        final driver = _user(s, p[2]);
        if (driver['role'] != 'DRIVER' || data['available'] is! bool) {
          _fail('Invalid driver duty change.');
        }
        if (_busy(s, p[2], 'assignedDriverId') != null) {
          _fail('Driver has active work. Complete or reassign it first.');
        }
        driver['available'] = data['available'];
        _audit(s, u, data['available'] ? 'DRIVER_ON_DUTY' : 'DRIVER_OFF_DUTY',
            p[2]);
        return {'available': driver['available']};
      }
      if (p[1] == 'vehicles') {
        _staff(u, manager: true);
        final v = (s['vehicles'] as Map)[p[2]];
        if (v == null) _fail('Vehicle not found.');
        if (_busy(s, p[2], 'assignedVehicleId') != null) {
          _fail(
              'Complete or reassign active work before editing this vehicle.');
        }
        if (data['makeModel'] != null) {
          v['makeModel'] = _text(data['makeModel'], 'vehicle name');
        }
        if (data['status'] != null) {
          if (!['ACTIVE', 'MAINTENANCE', 'INACTIVE'].contains(data['status'])) {
            _fail('Invalid vehicle status.');
          }
          v['status'] = data['status'];
        }
        _audit(s, u, 'VEHICLE_UPDATED', p[2]);
        return _copy(v);
      }
    }
    if (p.length == 3 && p[0] == 'dispatch' && method == 'POST') {
      final b = _booking(s, p[1], u);
      if (p[2] == 'assign') return _assign(s, u, b, data);
      if (p[2] == 'acknowledge') {
        if (u['role'] != 'DRIVER' ||
            b['dispatch']?['assignedDriverId'] != uid) {
          _fail('Assigned practice driver required.');
        }
        if (b['status'] != 'DISPATCHED') {
          _fail('This trip is not awaiting acceptance.');
        }
        if (b['dispatch']['acceptedAt'] != null) return _copy(b);
        _revision(b, data['expectedRevision']);
        if (data['inspection'] is! Map ||
            ['seatbelts', 'tyres', 'fuel', 'radio']
                .any((k) => data['inspection'][k] != true)) {
          _fail('Confirm all four pre-trip checks.');
        }
        b['dispatch']['acceptedAt'] = _now();
        _changed(s, b, u, 'DRIVER_ACCEPTED');
        return _copy(b);
      }
    }
    if (p.length == 3 && p[0] == 'bookings') {
      final b = _booking(s, p[1], u);
      if (p[2] == 'status' && method == 'PATCH') {
        final target = data['status'];
        _revision(b, data['expectedRevision']);
        if (target == 'CANCELLED') {
          if (!['PASSENGER', 'DISPATCHER', 'SUPERVISOR'].contains(u['role']) ||
              !_early.contains(b['status'])) {
            _fail('Cancellation is allowed only before departure.');
          }
        } else if (target == 'CLOSED') {
          _staff(u, manager: true);
          if (b['status'] != 'COMPLETED') {
            _fail('Only a completed trip can be closed.');
          }
        } else {
          if (u['role'] != 'DRIVER' ||
              b['dispatch']?['assignedDriverId'] != uid) {
            _fail('Assigned driver required.');
          }
          final next = {
            'DISPATCHED': 'DRIVER_EN_ROUTE',
            'DRIVER_EN_ROUTE':
                b['input']['direction'] == 'OUTBOUND_CITY_TO_AIRPORT'
                    ? 'AT_PICKUP'
                    : 'AT_AIRPORT',
            'PASSENGER_VERIFIED': 'TRANSFER_IN_PROGRESS',
            'TRANSFER_IN_PROGRESS': 'ARRIVED_DESTINATION',
            'ARRIVED_DESTINATION': 'COMPLETED'
          };
          if (next[b['status']] != target) {
            _fail('This trip stage cannot be skipped.');
          }
          if (target == 'DRIVER_EN_ROUTE' &&
              b['dispatch']['acceptedAt'] == null) {
            _fail('Accept the trip and pre-trip checks first.');
          }
        }
        b['status'] = target;
        _changed(s, b, u, target as String);
        return _copy(b);
      }
      if (p[2] == 'reset-otp' && method == 'POST') {
        _staff(u, manager: true);
        _revision(b, data['expectedRevision']);
        if (b['status'] !=
            (b['input']['direction'] == 'OUTBOUND_CITY_TO_AIRPORT'
                ? 'AT_PICKUP'
                : 'AT_AIRPORT')) {
          _fail('Reissue only at the pickup stage.');
        }
        final reason = _text(data['reason'], 'reason', max: 500),
            prior = (s['credentials'] as Map)[b['id']];
        var c = _credential(b);
        while (c['code'] == prior?['code']) {
          c = _credential(b);
        }
        (s['credentials'] as Map)[b['id']] = c;
        _changed(s, b, u, 'PICKUP_CODE_REISSUED: $reason');
        return _copy(b);
      }
      if (p[2] == 'verify-passenger' && method == 'POST') {
        if (u['role'] != 'DRIVER' ||
            b['dispatch']?['assignedDriverId'] != uid) {
          _fail('Assigned driver required.');
        }
        _revision(b, data['expectedRevision']);
        final c = (s['credentials'] as Map)[b['id']];
        if (b['status'] !=
                (b['input']['direction'] == 'OUTBOUND_CITY_TO_AIRPORT'
                    ? 'AT_PICKUP'
                    : 'AT_AIRPORT') ||
            c == null ||
            c['used'] == true) {
          _fail('Pickup verification is not available at this stage.');
        }
        if (DateTime.parse(c['expiresAt']).isBefore(
            DateTime.fromMillisecondsSinceEpoch(
                DateTime.now().millisecondsSinceEpoch,
                isUtc: true))) {
          _fail('Practice code expired. Ask the supervisor to reissue it.');
        }
        if (c['attempts'] >= 5) {
          return {
            '_error':
                'Practice code locked after five incorrect attempts. Ask the supervisor to reissue it.'
          };
        }
        if (data['code'] is! String ||
            !RegExp(r'^\d{6}$').hasMatch(data['code'])) {
          _fail('Enter the six digit pickup code.');
        }
        if (data['code'] != c['code']) {
          c['attempts'] = (c['attempts'] as int) + 1;
          return {
            '_error': c['attempts'] >= 5
                ? 'Practice code locked after five incorrect attempts.'
                : 'Incorrect practice pickup code.'
          };
        }
        c['used'] = true;
        b['status'] = 'PASSENGER_VERIFIED';
        _changed(s, b, u, 'PASSENGER_VERIFIED');
        return _copy(b);
      }
    }
    _fail('This feature is not included in the offline walkthrough.',
        'OFFLINE_UNSUPPORTED');
  }
}

/// The shared screens use this adapter, not HTTP. No fallback to the online client.
class OfflineDemoClient extends PngApiClient {
  final OfflineDemoStore store;
  final String uid;
  OfflineDemoClient(this.store, this.uid);
  @override
  Future<dynamic> get(String endpoint) => store.get(uid, endpoint);
  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) =>
      store.mutate(uid, 'POST', endpoint, body);
  @override
  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) =>
      store.mutate(uid, 'PATCH', endpoint, body);
}
