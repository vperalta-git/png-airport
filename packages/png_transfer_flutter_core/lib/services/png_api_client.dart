import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_session.dart';
import '../models/contracts_v1.dart';

class ApiException implements Exception {
  final String code, message;
  final int? status;
  ApiException(this.code, this.message, {this.status});
  @override
  String toString() => 'ApiException [$code]: $message';
}

class PngApiClient {
  String _baseUrl;
  String? authToken;
  final http.Client? _testClient;
  final Future<String?> Function()? tokenProvider;
  PngApiClient(
      {String? baseUrl, String? token, http.Client? client, this.tokenProvider})
      : _baseUrl = AppConfig.normalizeUrl(baseUrl ?? AppConfig.apiBaseUrl),
        authToken = token,
        _testClient = client;
  String get baseUrl => _baseUrl;
  set baseUrl(String value) => _baseUrl = AppConfig.normalizeUrl(value);
  void updateBaseUrl(String value) {
    baseUrl = value;
    AppConfig.apiBaseUrl = _baseUrl;
  }

  void updateToken(String? token) => authToken = token;
  void updateSession(UserSession? session) => authToken = session?.sessionId;
  bool get isAuthenticated => authToken?.isNotEmpty == true;
  Future<dynamic> get(String endpoint) => _request('GET', endpoint);
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) =>
      _request('POST', endpoint, body);
  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) =>
      _request('PATCH', endpoint, body);
  Future<dynamic> _request(String method, String endpoint,
      [Map<String, dynamic>? body]) async {
    AppConfig.validate();
    if (!endpoint.startsWith('/api/v1/') ||
        endpoint.contains('..') ||
        endpoint.contains('?') ||
        endpoint.contains('#')) {
      throw ArgumentError('Only versioned local API paths are supported.');
    }
    final client = _testClient ?? http.Client();
    try {
      final request = http.Request(
          method, Uri.parse('${AppConfig.normalizeUrl(_baseUrl)}$endpoint'))
        ..followRedirects = false;
      final token = tokenProvider == null
          ? authToken
          : await tokenProvider!().timeout(const Duration(seconds: 8));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      });
      if (body != null) request.body = jsonEncode(body);
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['schemaVersion'] != contractVersion) {
        throw ApiException('CONTRACT_ERROR', 'Unsupported API contract.',
            status: response.statusCode);
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['success'] != true) {
        final error = data['error'] as Map<String, dynamic>? ?? {};
        throw ApiException(error['code'] as String? ?? 'API_ERROR',
            error['message'] as String? ?? 'Request failed.',
            status: response.statusCode);
      }
      return data['data'];
    } catch (error) {
      if (error is ApiException) rethrow;
      if (error is FormatException || error is TypeError) {
        throw ApiException('PARSE_ERROR', 'Unreadable API response.');
      }
      throw ApiException('NETWORK_ERROR',
          'Local API unavailable. Check backend and emulators.');
    } finally {
      if (_testClient == null) client.close();
    }
  }

  Future<QuotationV1> requestQuotationV1(TransferInputV1 input) async =>
      QuotationV1.fromJson(await post('/api/v1/quotes', {
        'schemaVersion': contractVersion,
        'input': input.toJson()
      }) as Map<String, dynamic>);
  Future<BookingV1> getBookingV1(String id) async => BookingV1.fromJson(
      await get('/api/v1/bookings/${Uri.encodeComponent(documentIdV1(id))}')
          as Map<String, dynamic>);

  // Existing UI method signatures are preserved. Batch A backend rejects these
  // legacy authentication routes until Firebase Auth integration in Batch B.
  Future<UserSession> login(String email, String password) =>
      loginWithEmail(email, password);
  Future<UserSession> loginWithEmail(String email, String password) async {
    final data =
        await post('/api/v1/auth/login', {'email': email, 'password': password})
            as Map<String, dynamic>;
    final token = data['token'] as String?;
    updateToken(token);
    return UserSession.fromJson(data['user'] as Map<String, dynamic>,
        sid: token);
  }

  Future<void> sendWhatsAppOtp(String number) async {
    await post('/api/v1/auth/whatsapp/otp', {'whatsapp_number': number});
  }

  Future<UserSession> loginWithWhatsApp(String number, String otp) async {
    final data = await post('/api/v1/auth/whatsapp/verify',
        {'whatsapp_number': number, 'otp': otp}) as Map<String, dynamic>;
    final token = data['token'] as String?;
    updateToken(token);
    return UserSession.fromJson(data['user'] as Map<String, dynamic>,
        sid: token);
  }

  Future<UserSession> register(
      {required String name,
      required String email,
      required String password,
      required String whatsappNumber,
      String? company,
      UserRole role = UserRole.passenger}) async {
    if (role != UserRole.passenger) {
      throw ApiException(
          'FORBIDDEN', 'Public registration cannot grant staff permissions.');
    }
    final data = await post('/api/v1/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'whatsapp_number': whatsappNumber,
      'company': company
    }) as Map<String, dynamic>;
    final token = data['token'] as String?;
    updateToken(token);
    return UserSession.fromJson(data['user'] as Map<String, dynamic>,
        sid: token);
  }
}
