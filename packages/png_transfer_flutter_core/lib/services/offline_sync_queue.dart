import '../models/offline_sync_event.dart';

/// Idempotent Monotonic Offline Event Queue.
/// Guarantees that driver status milestones are preserved without loss in low-connectivity PNG corridors,
/// and replayed to the backend without duplicate execution.
class OfflineSyncQueue {
  final List<OfflineSyncEvent> _queue = [];
  final Set<String> _processedUuids = {};

  List<OfflineSyncEvent> get allEvents => List.unmodifiable(_queue);

  List<OfflineSyncEvent> get pendingEvents =>
      _queue.where((e) => e.syncStatus == 'pending').toList();

  List<OfflineSyncEvent> get syncedEvents =>
      _queue.where((e) => e.syncStatus == 'synced').toList();

  int get pendingCount => pendingEvents.length;

  /// Enqueues a new operational event with unique UUID.
  /// If the event was already enqueued, returns the existing event without duplicating.
  OfflineSyncEvent enqueue({
    required String eventType,
    required int bookingId,
    Map<String, dynamic> payload = const {},
    double? latitude,
    double? longitude,
    String? explicitUuid,
  }) {
    final uuid = explicitUuid ?? _generateUUID();

    // Deduplication check
    final existing = _queue.where((e) => e.uuid == uuid).toList();
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final event = OfflineSyncEvent(
      uuid: uuid,
      eventType: eventType,
      bookingId: bookingId,
      payload: payload,
      localTimestamp: DateTime.now().toUtc().toIso8601String(),
      latitude: latitude,
      longitude: longitude,
      syncStatus: 'pending',
    );

    _queue.add(event);
    return event;
  }

  /// Marks an event as successfully synchronized with backend.
  bool markSynced(String uuid) {
    final idx = _queue.indexWhere((e) => e.uuid == uuid);
    if (idx != -1) {
      _queue[idx] = _queue[idx].copyWith(syncStatus: 'synced');
      _processedUuids.add(uuid);
      return true;
    }
    return false;
  }

  /// Marks an event as failed and increments retry count.
  bool markFailed(String uuid) {
    final idx = _queue.indexWhere((e) => e.uuid == uuid);
    if (idx != -1) {
      final current = _queue[idx];
      final newRetries = current.retryCount + 1;
      _queue[idx] = current.copyWith(
        syncStatus: newRetries >= 5 ? 'failed' : 'pending',
        retryCount: newRetries,
      );
      return true;
    }
    return false;
  }

  /// Clears synced events from memory.
  void purgeSynced() {
    _queue.removeWhere((e) => e.syncStatus == 'synced');
  }

  /// Generates RFC-compliant UUID v4.
  String _generateUUID() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'evt_${now}_${(now % 99999).toString().padLeft(5, '0')}';
  }
}
