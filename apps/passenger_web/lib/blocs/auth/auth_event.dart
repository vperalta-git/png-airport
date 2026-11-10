import 'package:equatable/equatable.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class EmailLoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const EmailLoginSubmitted({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

/// Backwards compatibility alias
class LoginSubmitted extends EmailLoginSubmitted {
  const LoginSubmitted({required String login, required super.password})
      : super(email: login);
}

class SendWhatsAppOtpRequested extends AuthEvent {
  final String whatsappNumber;
  const SendWhatsAppOtpRequested({required this.whatsappNumber});
  @override
  List<Object?> get props => [whatsappNumber];
}

class WhatsAppLoginSubmitted extends AuthEvent {
  final String whatsappNumber;
  final String otp;
  const WhatsAppLoginSubmitted({required this.whatsappNumber, required this.otp});
  @override
  List<Object?> get props => [whatsappNumber, otp];
}

class RegistrationSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String whatsappNumber;
  final String? company;
  final UserRole role;

  const RegistrationSubmitted({
    required this.name,
    required this.email,
    required this.password,
    required this.whatsappNumber,
    this.company,
    this.role = UserRole.passenger,
  });

  @override
  List<Object?> get props => [name, email, password, whatsappNumber, company, role];
}

class GuestContinueRequested extends AuthEvent {}

class ProfileUpdated extends AuthEvent {
  final String name;
  final String company;
  final String phone;
  final String? whatsappNumber;

  const ProfileUpdated({
    required this.name,
    required this.company,
    required this.phone,
    this.whatsappNumber,
  });

  @override
  List<Object?> get props => [name, company, phone, whatsappNumber];
}

class LogoutRequested extends AuthEvent {}
