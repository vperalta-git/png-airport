/// API v1 DTOs. Legacy presentation models remain separate during UI migration.
/// No fallback IDs, timestamps, prices or operational records are accepted here.
const contractVersion = '1';
const contractRoles = [
  'PASSENGER',
  'DISPATCHER',
  'DRIVER',
  'SUPERVISOR',
  'SUPER_ADMIN',
  'SECURITY',
  'OPERATOR',
  'CORPORATE_BOOKER'
];
const bookingStatusesV1 = [
  'DRAFT',
  'QUOTATION',
  'BOOKING_REQUESTED',
  'AVAILABILITY_CONFIRMED',
  'CONFIRMED',
  'DISPATCHED',
  'DRIVER_EN_ROUTE',
  'AT_AIRPORT',
  'AT_PICKUP',
  'PASSENGER_VERIFIED',
  'TRANSFER_IN_PROGRESS',
  'ARRIVED_DESTINATION',
  'COMPLETED',
  'CLOSED',
  'CANCELLED'
];
const paymentStatusesV1 = [
  'PENDING',
  'AUTHORIZED',
  'PAID',
  'FAILED',
  'REFUNDED',
  'CANCELLED'
];
const vehicleCategoriesV1 = [
  'STANDARD_SEDAN',
  'EXECUTIVE_SUV',
  'HEAVY_4WD',
  'ARMORED_SUV',
  'COASTER_BUS'
];
const escortTypesV1 = [
  'NONE',
  'STATIC_OFFICER',
  'ARMED_ESCORT_CHASE_VEHICLE',
  'CLOSE_PROTECTION_CONVOY'
];
const directionsV1 = [
  'INBOUND_AIRPORT_TO_CITY',
  'OUTBOUND_CITY_TO_AIRPORT',
  'INTERCITY_TRANSFER'
];

Map<String, dynamic> _object(dynamic value, String field) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$field must be an object');
  }
  return value;
}

String _text(dynamic value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field is required');
  }
  return value;
}

String documentIdV1(dynamic value, [String field = 'id']) {
  final id = _text(value, field);
  if (id != id.trim() || id.contains('/') || id == '.' || id == '..') {
    throw FormatException('$field must be a document ID string');
  }
  return id;
}

String _member(dynamic value, List<String> choices, String field) {
  if (value is! String || !choices.contains(value)) {
    throw FormatException('Invalid $field');
  }
  return value;
}

int _integer(dynamic value, String field, [int minimum = 0]) {
  if (value is! int || value < minimum || value > 9007199254740991) {
    throw FormatException('$field must be a safe integer >= $minimum');
  }
  return value;
}

String timestampV1(dynamic value, [String field = 'timestamp']) {
  final text = _text(value, field);
  final match = RegExp(
          r'^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.\d{1,3})?(Z|[+-](\d\d):(\d\d))$')
      .firstMatch(text);
  if (match == null || DateTime.tryParse(text) == null) {
    throw FormatException('$field requires an ISO offset');
  }
  final year = int.parse(match[1]!),
      month = int.parse(match[2]!),
      day = int.parse(match[3]!);
  if (month < 1 ||
      month > 12 ||
      day < 1 ||
      day > DateTime.utc(year, month + 1, 0).day ||
      int.parse(match[4]!) > 23 ||
      int.parse(match[5]!) > 59 ||
      int.parse(match[6]!) > 59 ||
      (match[8] != null &&
          (int.parse(match[8]!) > 23 || int.parse(match[9]!) > 59))) {
    throw FormatException('$field has an invalid calendar/time value');
  }
  return text;
}

void _scope(Map<String, dynamic> json) {
  if (json['schemaVersion'] != contractVersion) {
    throw const FormatException('Unsupported schemaVersion');
  }
  for (final field in [
    'id',
    'organizationId',
    'branchId',
    'airportId',
    'customerId'
  ]) {
    documentIdV1(json[field], field);
  }
}

class PricingV1 {
  final int subtotalMinor, taxMinor, totalMinor;
  const PricingV1._(this.subtotalMinor, this.taxMinor, this.totalMinor);
  factory PricingV1.fromJson(Map<String, dynamic> json) {
    if (json['currency'] != 'PGK') {
      throw const FormatException('Currency must be PGK');
    }
    final sub = _integer(json['subtotalMinor'], 'subtotalMinor'),
        tax = _integer(json['taxMinor'], 'taxMinor'),
        total = _integer(json['totalMinor'], 'totalMinor');
    if (sub + tax > 9007199254740991 || sub + tax != total) {
      throw const FormatException('Pricing does not balance');
    }
    return PricingV1._(sub, tax, total);
  }
  Map<String, dynamic> toJson() => {
        'currency': 'PGK',
        'subtotalMinor': subtotalMinor,
        'taxMinor': taxMinor,
        'totalMinor': totalMinor
      };
}

class TransferInputV1 {
  final Map<String, dynamic> _json;
  TransferInputV1._(Map<String, dynamic> json) : _json = Map.unmodifiable(json);
  factory TransferInputV1.fromJson(Map<String, dynamic> json) {
    documentIdV1(json['airportId'], 'airportId');
    _member(json['direction'], directionsV1, 'direction');
    _member(json['vehicleCategory'], vehicleCategoriesV1, 'vehicleCategory');
    _member(json['securityEscortType'], escortTypesV1, 'securityEscortType');
    timestampV1(json['pickupDateTime'], 'pickupDateTime');
    _text(json['destinationAddress'], 'destinationAddress');
    _integer(json['passengerCount'], 'passengerCount', 1);
    _integer(json['luggageCount'], 'luggageCount');
    return TransferInputV1._(json);
  }
  String get airportId => _json['airportId'] as String;
  int get passengerCount => _json['passengerCount'] as int;
  Map<String, dynamic> toJson() => Map.of(_json);
}

class QuotationV1 {
  final String id,
      organizationId,
      branchId,
      airportId,
      customerId,
      rateVersion,
      createdAt,
      expiresAt;
  final TransferInputV1 input;
  final PricingV1 pricing;
  QuotationV1._(Map<String, dynamic> j, this.input, this.pricing)
      : id = j['id'],
        organizationId = j['organizationId'],
        branchId = j['branchId'],
        airportId = j['airportId'],
        customerId = j['customerId'],
        rateVersion = j['rateVersion'],
        createdAt = j['createdAt'],
        expiresAt = j['expiresAt'];
  factory QuotationV1.fromJson(Map<String, dynamic> json) {
    _scope(json);
    final input = TransferInputV1.fromJson(_object(json['input'], 'input'));
    if (input.airportId != json['airportId']) {
      throw const FormatException('Quote airport scope mismatch');
    }
    _text(json['rateVersion'], 'rateVersion');
    final created = timestampV1(json['createdAt'], 'createdAt'),
        expires = timestampV1(json['expiresAt'], 'expiresAt');
    if (!DateTime.parse(expires).isAfter(DateTime.parse(created))) {
      throw const FormatException('Invalid quote expiry');
    }
    return QuotationV1._(
        json, input, PricingV1.fromJson(_object(json['pricing'], 'pricing')));
  }
  Map<String, dynamic> toJson() => {
        'schemaVersion': contractVersion,
        'id': id,
        'organizationId': organizationId,
        'branchId': branchId,
        'airportId': airportId,
        'customerId': customerId,
        'input': input.toJson(),
        'pricing': pricing.toJson(),
        'rateVersion': rateVersion,
        'createdAt': createdAt,
        'expiresAt': expiresAt
      };
}

class BookingV1 {
  final String id,
      organizationId,
      branchId,
      airportId,
      customerId,
      referenceNumber,
      quotationId,
      rateVersion,
      status,
      paymentStatus;
  final int revision;
  final TransferInputV1 input;
  final PricingV1 pricing;
  final String? assignedDriverId;
  final String createdAt, updatedAt;
  final Map<String, dynamic> payment;
  final List<Map<String, dynamic>> passengers;
  final Map<String, dynamic>? dispatch;
  BookingV1._(Map<String, dynamic> j, this.input, this.pricing,
      this.paymentStatus, this.assignedDriverId)
      : id = j['id'],
        organizationId = j['organizationId'],
        branchId = j['branchId'],
        airportId = j['airportId'],
        customerId = j['customerId'],
        referenceNumber = j['referenceNumber'],
        quotationId = j['quotationId'],
        rateVersion = j['rateVersion'],
        status = j['status'],
        revision = j['revision'],
        createdAt = j['createdAt'],
        updatedAt = j['updatedAt'],
        payment = Map.unmodifiable(j['payment'] as Map<String, dynamic>),
        passengers = List.unmodifiable((j['passengers'] as List).map((p) =>
            Map<String, dynamic>.unmodifiable(p as Map<String, dynamic>))),
        dispatch = j['dispatch'] == null
            ? null
            : Map.unmodifiable(j['dispatch'] as Map<String, dynamic>);
  factory BookingV1.fromJson(Map<String, dynamic> json) {
    _scope(json);
    documentIdV1(json['quotationId'], 'quotationId');
    _text(json['referenceNumber'], 'referenceNumber');
    _text(json['rateVersion'], 'rateVersion');
    _member(json['status'], bookingStatusesV1, 'booking status');
    _integer(json['revision'], 'revision');
    final input = TransferInputV1.fromJson(_object(json['input'], 'input'));
    if (input.airportId != json['airportId']) {
      throw const FormatException('Booking airport scope mismatch');
    }
    final payment = _object(json['payment'], 'payment'),
        status =
            _member(payment['status'], paymentStatusesV1, 'payment status');
    if (payment.containsKey('method')) {
      _member(
          payment['method'],
          [
            'CASH_ON_BOARD',
            'BANK_TRANSFER_BSP',
            'CARD_GATEWAY',
            'CORPORATE_CREDIT'
          ],
          'payment method');
    }
    if (payment.containsKey('providerReference')) {
      _text(payment['providerReference'], 'providerReference');
    }
    if (payment.containsKey('verifiedAt')) {
      timestampV1(payment['verifiedAt'], 'verifiedAt');
    }
    if (status == 'PAID' &&
        (payment['providerReference'] == null ||
            payment['verifiedAt'] == null)) {
      throw const FormatException('PAID requires verified evidence');
    }
    final passengers = json['passengers'];
    if (passengers is! List || passengers.length != input.passengerCount) {
      throw const FormatException('Manifest count mismatch');
    }
    for (final passenger in passengers) {
      final p = _object(passenger, 'passenger');
      _text(p['fullName'], 'fullName');
      for (final field in ['phone', 'email']) {
        if (p.containsKey(field)) _text(p[field], field);
      }
    }
    String? driver;
    if (json.containsKey('dispatch')) {
      final d = _object(json['dispatch'], 'dispatch');
      driver = documentIdV1(d['assignedDriverId'], 'assignedDriverId');
      documentIdV1(d['assignedVehicleId'], 'assignedVehicleId');
      if (d.containsKey('assignedSecurityGuardId')) {
        documentIdV1(d['assignedSecurityGuardId'], 'assignedSecurityGuardId');
      }
      if (d.containsKey('acceptedAt')) {
        timestampV1(d['acceptedAt'], 'acceptedAt');
      }
    }
    final created = timestampV1(json['createdAt'], 'createdAt'),
        updated = timestampV1(json['updatedAt'], 'updatedAt');
    if (DateTime.parse(updated).isBefore(DateTime.parse(created))) {
      throw const FormatException('updatedAt precedes createdAt');
    }
    return BookingV1._(
        json,
        input,
        PricingV1.fromJson(_object(json['pricing'], 'pricing')),
        status,
        driver);
  }
  Map<String, dynamic> toJson() => {
        'schemaVersion': contractVersion,
        'id': id,
        'organizationId': organizationId,
        'branchId': branchId,
        'airportId': airportId,
        'customerId': customerId,
        'referenceNumber': referenceNumber,
        'quotationId': quotationId,
        'rateVersion': rateVersion,
        'status': status,
        'revision': revision,
        'input': input.toJson(),
        'pricing': pricing.toJson(),
        'payment': Map.of(payment),
        'passengers': passengers.map((p) => Map.of(p)).toList(),
        if (dispatch != null) 'dispatch': Map.of(dispatch!),
        'createdAt': createdAt,
        'updatedAt': updatedAt
      };
}
