import 'package:equatable/equatable.dart';

class QuoteRequest extends Equatable {
  final int airportId;
  final int? zoneId;
  final int? vehicleCategoryId;
  final double distanceKm;
  final bool securityRequired;
  final bool meetGreetRequired;
  final int? corporateAccountId;

  const QuoteRequest({
    required this.airportId,
    this.zoneId,
    this.vehicleCategoryId,
    this.distanceKm = 10.0,
    this.securityRequired = false,
    this.meetGreetRequired = true,
    this.corporateAccountId,
  });

  Map<String, dynamic> toJson() => {
        'airport_id': airportId,
        if (zoneId != null) 'zone_id': zoneId,
        if (vehicleCategoryId != null) 'vehicle_category_id': vehicleCategoryId,
        'distance_km': distanceKm,
        'security_required': securityRequired,
        'meet_greet_required': meetGreetRequired,
        if (corporateAccountId != null) 'corporate_account_id': corporateAccountId,
      };

  @override
  List<Object?> get props => [
        airportId,
        zoneId,
        vehicleCategoryId,
        distanceKm,
        securityRequired,
        meetGreetRequired,
        corporateAccountId,
      ];
}

class QuoteResponse extends Equatable {
  final double baseFare;
  final double distanceKm;
  final double distanceCharge;
  final double airportFee;
  final double meetGreetFee;
  final double securityEscortFee;
  final double afterHoursFee;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String currency;
  final int? ruleAppliedId;
  final String? ruleName;

  const QuoteResponse({
    required this.baseFare,
    required this.distanceKm,
    required this.distanceCharge,
    required this.airportFee,
    required this.meetGreetFee,
    required this.securityEscortFee,
    required this.afterHoursFee,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    this.currency = 'PGK',
    this.ruleAppliedId,
    this.ruleName,
  });

  factory QuoteResponse.fromJson(Map<String, dynamic> json) {
    return QuoteResponse(
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      distanceCharge: (json['distance_charge'] as num?)?.toDouble() ?? 0.0,
      airportFee: (json['airport_fee'] as num?)?.toDouble() ?? 0.0,
      meetGreetFee: (json['meet_greet_fee'] as num?)?.toDouble() ?? 0.0,
      securityEscortFee: (json['security_escort_fee'] as num?)?.toDouble() ?? 0.0,
      afterHoursFee: (json['after_hours_fee'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'PGK',
      ruleAppliedId: json['rule_applied_id'] as int?,
      ruleName: json['rule_name'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        baseFare,
        distanceKm,
        securityEscortFee,
        subtotal,
        total,
        currency,
      ];
}
