import 'package:equatable/equatable.dart';

class ServiceZone extends Equatable {
  final int id;
  final String name;
  final String code;
  final String zoneType;
  final String riskLevel;
  final String pricingZone;
  final double? centerLatitude;
  final double? centerLongitude;
  final double? radiusKm;

  const ServiceZone({
    required this.id,
    required this.name,
    required this.code,
    required this.zoneType,
    required this.riskLevel,
    required this.pricingZone,
    this.centerLatitude,
    this.centerLongitude,
    this.radiusKm,
  });

  factory ServiceZone.fromJson(Map<String, dynamic> json) {
    return ServiceZone(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      zoneType: json['zone_type'] as String? ?? 'city',
      riskLevel: json['risk_level'] as String? ?? 'low',
      pricingZone: json['pricing_zone'] as String? ?? 'zone_a',
      centerLatitude: (json['center_latitude'] as num?)?.toDouble(),
      centerLongitude: (json['center_longitude'] as num?)?.toDouble(),
      radiusKm: (json['radius_km'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'zone_type': zoneType,
        'risk_level': riskLevel,
        'pricing_zone': pricingZone,
        'center_latitude': centerLatitude,
        'center_longitude': centerLongitude,
        'radius_km': radiusKm,
      };

  bool get isHighRisk => riskLevel == 'high' || riskLevel == 'extreme';

  @override
  List<Object?> get props => [id, name, code, riskLevel];
}

class Airport extends Equatable {
  final int id;
  final String name;
  final String iataCode;
  final String icaoCode;
  final String city;
  final String? province;
  final String timezone;
  final double latitude;
  final double longitude;
  final double serviceRadiusKm;
  final bool transferEnabled;
  final bool securityServiceEnabled;
  final bool meetGreetEnabled;
  final String? arrivalInstructions;
  final String? departureInstructions;
  final String? emergencyContact;
  final List<ServiceZone> zones;

  const Airport({
    required this.id,
    required this.name,
    required this.iataCode,
    required this.icaoCode,
    required this.city,
    this.province,
    this.timezone = 'Pacific/Port_Moresby',
    required this.latitude,
    required this.longitude,
    required this.serviceRadiusKm,
    this.transferEnabled = true,
    this.securityServiceEnabled = true,
    this.meetGreetEnabled = true,
    this.arrivalInstructions,
    this.departureInstructions,
    this.emergencyContact,
    this.zones = const [],
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    final zonesRaw = json['zones'] as List<dynamic>? ?? [];
    return Airport(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      iataCode: json['iata_code'] as String? ?? '',
      icaoCode: json['icao_code'] as String? ?? '',
      city: json['city'] as String? ?? '',
      province: json['province'] as String?,
      timezone: json['timezone'] as String? ?? 'Pacific/Port_Moresby',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -6.5698,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 146.7262,
      serviceRadiusKm: (json['service_radius_km'] as num?)?.toDouble() ?? 80.0,
      transferEnabled: json['transfer_enabled'] as bool? ?? true,
      securityServiceEnabled: json['security_service_enabled'] as bool? ?? true,
      meetGreetEnabled: json['meet_greet_enabled'] as bool? ?? true,
      arrivalInstructions: json['arrival_instructions'] as String?,
      departureInstructions: json['departure_instructions'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      zones: zonesRaw.map((z) => ServiceZone.fromJson(z as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iata_code': iataCode,
        'icao_code': icaoCode,
        'city': city,
        'province': province,
        'timezone': timezone,
        'latitude': latitude,
        'longitude': longitude,
        'service_radius_km': serviceRadiusKm,
        'transfer_enabled': transferEnabled,
        'security_service_enabled': securityServiceEnabled,
        'meet_greet_enabled': meetGreetEnabled,
        'arrival_instructions': arrivalInstructions,
        'departure_instructions': departureInstructions,
        'emergency_contact': emergencyContact,
        'zones': zones.map((z) => z.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, name, iataCode, icaoCode, city];
}
