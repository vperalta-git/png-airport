import 'package:equatable/equatable.dart';

class MetarWeather extends Equatable {
  final String temperature;
  final String condition;
  final String wind;
  final String qnh;
  final String category;
  final String metar;

  const MetarWeather({
    required this.temperature,
    required this.condition,
    required this.wind,
    required this.qnh,
    required this.category,
    required this.metar,
  });

  factory MetarWeather.fromJson(Map<String, dynamic> json) {
    return MetarWeather(
      temperature: json['temperature'] as String? ?? '26°C',
      condition: json['condition'] as String? ?? 'Fair',
      wind: json['wind'] as String? ?? '90° @ 10 kt',
      qnh: json['qnh'] as String? ?? '1015 hPa',
      category: json['category'] as String? ?? 'VFR',
      metar: json['metar'] as String? ?? 'AYNZ 020100Z 09010KT 9999 FEW020 26/22 Q1015',
    );
  }

  @override
  List<Object?> get props => [temperature, condition, wind, category];
}

class FlightRadarFlight extends Equatable {
  final String id;
  final String code;
  final String carrier;
  final String type; // 'arrival' | 'departure'
  final String originCode;
  final String originCity;
  final String destCode;
  final String destCity;
  final String scheduledTime;
  final String estimatedTime;
  final String flightDate;
  final String status;
  final String aircraft;
  final String? gate;
  final String? carousel;
  final int delayMinutes;
  final String? fr24Url;

  const FlightRadarFlight({
    required this.id,
    required this.code,
    required this.carrier,
    required this.type,
    required this.originCode,
    required this.originCity,
    required this.destCode,
    required this.destCity,
    required this.scheduledTime,
    required this.estimatedTime,
    required this.flightDate,
    required this.status,
    required this.aircraft,
    this.gate,
    this.carousel,
    this.delayMinutes = 0,
    this.fr24Url,
  });

  bool get isDelayed => delayMinutes > 0 || status.toLowerCase().contains('delayed');
  bool get isArrival => type == 'arrival';

  factory FlightRadarFlight.fromJson(Map<String, dynamic> json, {String defaultType = 'arrival'}) {
    final status = json['status'] as String? ?? 'Scheduled';
    final isDelayed = (json['statusCategory'] == 'delayed') || status.toLowerCase().contains('delay');

    return FlightRadarFlight(
      id: json['id'] as String? ?? (json['code'] as String? ?? 'FL'),
      code: json['code'] as String? ?? 'PX100',
      carrier: json['carrier'] as String? ?? 'Air Niugini',
      type: json['type'] as String? ?? defaultType,
      originCode: json['originCode'] as String? ?? 'POM',
      originCity: json['originCity'] as String? ?? 'Port Moresby',
      destCode: json['destCode'] as String? ?? 'LAE',
      destCity: json['destCity'] as String? ?? 'Lae (Nadzab)',
      scheduledTime: json['scheduledTime'] as String? ?? '12:00',
      estimatedTime: json['estimatedTime'] as String? ?? (json['scheduledTime'] as String? ?? '12:00'),
      flightDate: json['flightDate'] as String? ?? 'Today',
      status: status,
      aircraft: json['aircraft'] as String? ?? 'Boeing 737-800',
      gate: json['gate'] as String?,
      carousel: json['carousel'] as String?,
      delayMinutes: (json['delayMinutes'] as int?) ?? (isDelayed ? 25 : 0),
      fr24Url: json['fr24Url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, code, carrier, type, scheduledTime, status];
}
