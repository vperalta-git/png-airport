import 'package:equatable/equatable.dart';

enum UserRole {
  passenger,
  driver,
  security,
  dispatcher,
  supervisor,
  corporate,
  admin,
}

class UserSession extends Equatable {
  final int id;
  final String name;
  final String login;
  final int partnerId;
  final UserRole role;
  final String? sessionId;
  final String? company;
  final String? phone;
  final String? whatsappNumber;

  const UserSession({
    required this.id,
    required this.name,
    required this.login,
    required this.partnerId,
    required this.role,
    this.sessionId,
    this.company,
    this.phone,
    this.whatsappNumber,
  });

  String get displayPhone => whatsappNumber ?? phone ?? '+675 7000 0000';

  factory UserSession.fromJson(Map<String, dynamic> json, {String? sid}) {
    final roleStr = json['role'] as String? ?? 'passenger';
    final role = UserRole.values.firstWhere(
      (r) => r.name.toLowerCase() == roleStr.toLowerCase(),
      orElse: () => UserRole.passenger,
    );

    final wa = json['whatsapp_number'] as String? ??
        json['whatsappNumber'] as String? ??
        json['phone'] as String?;

    return UserSession(
      id: json['id'] as int? ?? 1,
      name: json['name'] as String? ?? 'Passenger',
      login: json['login'] as String? ?? json['email'] as String? ?? '',
      partnerId: json['partner_id'] as int? ?? 1,
      role: role,
      sessionId: sid ?? json['session_id'] as String?,
      company: json['company'] as String?,
      phone: json['phone'] as String? ?? wa,
      whatsappNumber: wa,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'login': login,
        'email': login,
        'partner_id': partnerId,
        'role': role.name,
        'session_id': sessionId,
        'company': company,
        'phone': phone,
        'whatsapp_number': whatsappNumber,
      };

  @override
  List<Object?> get props => [id, name, login, role, sessionId, whatsappNumber];
}
