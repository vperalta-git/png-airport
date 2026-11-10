import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../services/firestore_auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final PngApiClient apiClient;
  final FirestoreAuthService authService;

  AuthBloc({
    required this.apiClient,
    FirestoreAuthService? authService,
  })  : authService = authService ?? FirestoreAuthService(apiClient: apiClient),
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<EmailLoginSubmitted>(_onEmailLoginSubmitted);
    on<SendWhatsAppOtpRequested>(_onSendWhatsAppOtpRequested);
    on<WhatsAppLoginSubmitted>(_onWhatsAppLoginSubmitted);
    on<RegistrationSubmitted>(_onRegistrationSubmitted);
    on<GuestContinueRequested>(_onGuestContinueRequested);
    on<ProfileUpdated>(_onProfileUpdated);
    on<LogoutRequested>(_onLogoutRequested);
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) {
    // Default logged in demo passenger for instant operational usage in field/tests
    const defaultPassenger = UserSession(
      id: 101,
      name: 'Captain David Vance',
      login: 'david.vance@bhp.com',
      partnerId: 42,
      role: UserRole.passenger,
      company: 'BHP Minerals PNG / Ok Tedi Exploration',
      phone: '+675 7123 4567',
      whatsappNumber: '+675 7123 4567',
    );
    apiClient.updateSession(defaultPassenger);
    emit(const Authenticated(defaultPassenger));
  }

  Future<void> _onEmailLoginSubmitted(
    EmailLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authService.loginWithEmail(event.email, event.password);
      apiClient.updateSession(user);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSendWhatsAppOtpRequested(
    SendWhatsAppOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final hint = await authService.sendWhatsAppOtp(event.whatsappNumber);
      emit(OtpSent(whatsappNumber: event.whatsappNumber, codeHint: hint));
    } catch (e) {
      emit(AuthFailure('Failed to dispatch WhatsApp OTP: $e'));
    }
  }

  Future<void> _onWhatsAppLoginSubmitted(
    WhatsAppLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authService.loginWithWhatsApp(event.whatsappNumber, event.otp);
      apiClient.updateSession(user);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegistrationSubmitted(
    RegistrationSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authService.registerWithEmail(
        name: event.name,
        email: event.email,
        password: event.password,
        whatsappNumber: event.whatsappNumber,
        company: event.company,
        role: event.role,
      );
      apiClient.updateSession(user);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure('Registration failed: $e'));
    }
  }

  void _onGuestContinueRequested(
    GuestContinueRequested event,
    Emitter<AuthState> emit,
  ) {
    const guest = UserSession(
      id: 999,
      name: 'Guest Passenger',
      login: 'guest@pngtransfer.pg',
      partnerId: 999,
      role: UserRole.passenger,
      company: 'Individual Travel',
      phone: '+675 7000 0000',
      whatsappNumber: '+675 7000 0000',
    );
    apiClient.updateSession(guest);
    emit(const Authenticated(guest));
  }

  void _onProfileUpdated(ProfileUpdated event, Emitter<AuthState> emit) {
    if (state is Authenticated) {
      final current = (state as Authenticated).user;
      final updated = UserSession(
        id: current.id,
        name: event.name.isNotEmpty ? event.name : current.name,
        login: current.login,
        partnerId: current.partnerId,
        role: current.role,
        sessionId: current.sessionId,
        company: event.company.isNotEmpty ? event.company : current.company,
        phone: event.phone.isNotEmpty ? event.phone : current.phone,
        whatsappNumber: event.whatsappNumber ?? current.whatsappNumber,
      );
      apiClient.updateSession(updated);
      emit(Authenticated(updated));
    }
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) {
    apiClient.updateSession(null);
    emit(const Unauthenticated(message: 'Signed out successfully.'));
  }
}
