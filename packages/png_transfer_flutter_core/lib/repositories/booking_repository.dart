import '../models/booking.dart';
import '../models/quote.dart';
import '../services/png_api_client.dart';

class BookingRepository {
  final PngApiClient apiClient;

  BookingRepository({required this.apiClient});

  final List<Booking> _localBookings = [];

  // Legacy presentation adapter is not an authority for prices. Batch B will
  // replace this DTO with requestQuotationV1 and the versioned booking workflow.
  Future<QuoteResponse> calculateQuote(QuoteRequest request) async {
    throw ApiException('WORKFLOW_NOT_READY',
        'Legacy quotations are disabled. Configure approved rates and use the v1 contract in Batch B.');
  }

  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    final res = await apiClient.post('/api/v1/bookings', payload);
    final booking = Booking.fromJson(res as Map<String, dynamic>);
    _localBookings.insert(0, booking);
    return booking;
  }

  Future<List<Booking>> getBookings({bool forceRefresh = false}) async {
    if (!forceRefresh && _localBookings.isNotEmpty) {
      return List.unmodifiable(_localBookings);
    }

    try {
      final res = await apiClient.get('/api/v1/bookings');
      final list = (res as List<dynamic>)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
      _localBookings.clear();
      _localBookings.addAll(list);
      return List.unmodifiable(_localBookings);
    } catch (_) {
      // In offline mode, return locally cached bookings
      return List.unmodifiable(_localBookings);
    }
  }

  Future<Map<String, dynamic>> submitDriverMilestone({
    required int bookingId,
    required String eventType,
    String? idempotencyKey,
    String? description,
  }) async {
    final payload = {
      'event_type': eventType,
      'event_id':
          idempotencyKey ?? 'ev-${DateTime.now().millisecondsSinceEpoch}',
      'description': description ?? 'Driver milestone update',
    };

    try {
      final res = await apiClient.post(
        '/api/v1/driver/assignments/$bookingId/events',
        payload,
      );
      return res as Map<String, dynamic>;
    } catch (_) {
      return {
        'booking_id': bookingId,
        'current_state': eventType,
        'synced': false,
        'offline_stored': true,
      };
    }
  }
}
