import 'package:equatable/equatable.dart';

class Passenger extends Equatable {
  final int? id;
  final String firstName;
  final String lastName;
  final String? mobile;
  final String? email;
  final String passengerType; // 'primary', 'guest', 'vip', 'employee', 'crew'
  final String verificationStatus; // 'pending', 'verified', 'failed'
  final String? qrToken;
  final String? otp;
  final int baggageCount;

  const Passenger({
    this.id,
    required this.firstName,
    required this.lastName,
    this.mobile,
    this.email,
    this.passengerType = 'primary',
    this.verificationStatus = 'pending',
    this.qrToken,
    this.otp,
    this.baggageCount = 1,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isVerified => verificationStatus == 'verified';

  Passenger copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? mobile,
    String? email,
    String? passengerType,
    String? verificationStatus,
    String? qrToken,
    String? otp,
    int? baggageCount,
  }) {
    return Passenger(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      passengerType: passengerType ?? this.passengerType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      qrToken: qrToken ?? this.qrToken,
      otp: otp ?? this.otp,
      baggageCount: baggageCount ?? this.baggageCount,
    );
  }

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'] as int?,
      firstName: json['first_name'] as String? ?? (json['name'] as String? ?? 'Passenger'),
      lastName: json['last_name'] as String? ?? '',
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      passengerType: json['passenger_type'] as String? ?? 'primary',
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      qrToken: json['qr_token'] as String?,
      otp: json['otp'] as String?,
      baggageCount: json['baggage_count'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'first_name': firstName,
        'last_name': lastName,
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
        'passenger_type': passengerType,
        'verification_status': verificationStatus,
        if (qrToken != null) 'qr_token': qrToken,
        if (otp != null) 'otp': otp,
        'baggage_count': baggageCount,
      };

  @override
  List<Object?> get props => [id, firstName, lastName, qrToken, otp, verificationStatus];
}
