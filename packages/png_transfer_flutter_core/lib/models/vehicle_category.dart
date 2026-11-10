import 'package:equatable/equatable.dart';

class VehicleCategory extends Equatable {
  final int id;
  final String name;
  final String code;
  final int passengerCapacity;
  final int baggageCapacity;
  final bool securityRated;
  final double basePriceMultiplier;
  final String? icon;

  const VehicleCategory({
    required this.id,
    required this.name,
    required this.code,
    required this.passengerCapacity,
    required this.baggageCapacity,
    required this.securityRated,
    required this.basePriceMultiplier,
    this.icon,
  });

  factory VehicleCategory.fromJson(Map<String, dynamic> json) {
    return VehicleCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      passengerCapacity: json['passenger_capacity'] as int? ?? 4,
      baggageCapacity: json['baggage_capacity'] as int? ?? 3,
      securityRated: json['security_rated'] as bool? ?? false,
      basePriceMultiplier: (json['base_price_multiplier'] as num?)?.toDouble() ?? 1.0,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'passenger_capacity': passengerCapacity,
        'baggage_capacity': baggageCapacity,
        'security_rated': securityRated,
        'base_price_multiplier': basePriceMultiplier,
        'icon': icon,
      };

  @override
  List<Object?> get props => [id, name, code, securityRated];
}
