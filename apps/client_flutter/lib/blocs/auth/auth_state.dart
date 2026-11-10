import 'package:equatable/equatable.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserSession user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  final String? message;
  const Unauthenticated({this.message});
  @override
  List<Object?> get props => [message];
}

class OtpSent extends AuthState {
  final String whatsappNumber;
  final String codeHint;

  const OtpSent({
    required this.whatsappNumber,
    required this.codeHint,
  });

  @override
  List<Object?> get props => [whatsappNumber, codeHint];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}
