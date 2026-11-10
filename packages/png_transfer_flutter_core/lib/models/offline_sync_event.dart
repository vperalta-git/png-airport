import 'package:equatable/equatable.dart';

class OfflineSyncEvent extends Equatable {
  final String uuid;
  final String eventType;
  final int bookingId;
  final Map<String, dynamic> payload;
  final String localTimestamp;
  final double? latitude;
  final double? longitude;
  final String syncStatus; // 'pending', 'synced', 'failed'
  final int retryCount;

  const OfflineSyncEvent({
    required this.uuid,
    required this.eventType,
    required this.bookingId,
    this.payload = const {},
    required this.localTimestamp,
    this.latitude,
    this.longitude,
    this.syncStatus = 'pending',
    this.retryCount = 0,
  });

  OfflineSyncEvent copyWith({
    String? syncStatus,
    int? retryCount,
  }) {
    return OfflineSyncEvent(
      uuid: uuid,
      eventType: eventType,
      bookingId: bookingId,
      payload: payload,
      localTimestamp: localTimestamp,
      latitude: latitude,
      longitude: longitude,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': uuid,
      'event_type': eventType,
      'booking_id': bookingId,
      'payload': payload,
      'timestamp': localTimestamp,
      'latitude': latitude,
      'longitude': longitude,
      'idempotency_key': uuid,
    };
  }

  factory OfflineSyncEvent.fromJson(Map<String, dynamic> json) {
    return OfflineSyncEvent(
      uuid: json['event_id'] as String? ?? json['uuid'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      bookingId: json['booking_id'] as int? ?? 0,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      localTimestamp: json['timestamp'] as String? ?? json['localTimestamp'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      syncStatus: json['syncStatus'] as String? ?? 'pending',
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [uuid, eventType, bookingId, syncStatus, retryCount];
}
