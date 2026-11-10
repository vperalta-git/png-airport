import 'package:equatable/equatable.dart';

class CorporatePassenger extends Equatable {
  final String id;
  final String fullName;
  final String title;
  final String department;
  final String email;
  final String phone;
  final String idNumber;
  final bool isVip;
  final String emergencyContact;

  const CorporatePassenger({
    required this.id,
    required this.fullName,
    required this.title,
    required this.department,
    required this.email,
    required this.phone,
    required this.idNumber,
    this.isVip = false,
    required this.emergencyContact,
  });

  factory CorporatePassenger.fromJson(Map<String, dynamic> json) {
    return CorporatePassenger(
      id: json['id'] as String? ?? 'pax_${DateTime.now().millisecondsSinceEpoch}',
      fullName: json['full_name'] as String? ?? 'Traveler',
      title: json['title'] as String? ?? 'Specialist',
      department: json['department'] as String? ?? 'Operations',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '+675 7000 0000',
      idNumber: json['id_number'] as String? ?? 'PNG-ID-0000',
      isVip: json['is_vip'] as bool? ?? false,
      emergencyContact: json['emergency_contact'] as String? ?? '+675 7111 2222',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'title': title,
    'department': department,
    'email': email,
    'phone': phone,
    'id_number': idNumber,
    'is_vip': isVip,
    'emergency_contact': emergencyContact,
  };

  @override
  List<Object?> get props => [id, fullName, department, isVip];
}

