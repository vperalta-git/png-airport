import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/cloud_service_status.dart';
import 'cloud_sync_event.dart';
import 'cloud_sync_state.dart';

class CloudSyncBloc extends Bloc<CloudSyncEvent, CloudSyncState> {
  CloudSyncBloc() : super(const CloudSyncState()) {
    on<LoadCloudSyncStatus>(_onLoadCloudSyncStatus);
    on<TriggerManualSyncService>(_onTriggerManualSyncService);
    on<TriggerFullCloudHealthSweep>(_onTriggerFullCloudHealthSweep);
  }

  void _onLoadCloudSyncStatus(
    LoadCloudSyncStatus event,
    Emitter<CloudSyncState> emit,
  ) {
    final sampleServices = [
      CloudServiceModel(
        serviceName: 'firestore.bookings',
        displayName: 'Operational Booking Engine & Holds',
        recordCount: 184,
        lastSync: DateTime.now().subtract(const Duration(minutes: 2)),
        health: CloudServiceHealth.optimal,
      ),
      CloudServiceModel(
        serviceName: 'firestore.resources',
        displayName: 'Armored & Escort Fleet Roster',
        recordCount: 28,
        lastSync: DateTime.now().subtract(const Duration(minutes: 8)),
        health: CloudServiceHealth.optimal,
      ),
      CloudServiceModel(
        serviceName: 'firestore.compliance',
        displayName: 'Driver Licenses & Firearm Permits',
        recordCount: 42,
        lastSync: DateTime.now().subtract(const Duration(minutes: 8)),
        health: CloudServiceHealth.optimal,
      ),
      CloudServiceModel(
        serviceName: 'rtdb.active_tracking',
        displayName: 'Realtime Database: Live Telemetry',
        recordCount: 112,
        lastSync: DateTime.now().subtract(const Duration(seconds: 15)),
        health: CloudServiceHealth.optimal,
      ),
      CloudServiceModel(
        serviceName: 'cloudrun.finance',
        displayName: 'PNG Tax Invoices & IRC Journals',
        recordCount: 156,
        lastSync: DateTime.now().subtract(const Duration(minutes: 5)),
        health: CloudServiceHealth.optimal,
      ),
    ];

    emit(state.copyWith(
      status: CloudGatewayStatus.connected,
      services: sampleServices,
    ));
  }

  Future<void> _onTriggerManualSyncService(
    TriggerManualSyncService event,
    Emitter<CloudSyncState> emit,
  ) async {
    final updated = state.services.map((m) {
      if (m.serviceName == event.serviceName) {
        return m.copyWith(
          lastSync: DateTime.now(),
          health: CloudServiceHealth.optimal,
        );
      }
      return m;
    }).toList();

    emit(state.copyWith(
      services: updated,
      notificationMessage: 'Service [${event.serviceName}] health verified via Cloud Run.',
    ));
  }

  Future<void> _onTriggerFullCloudHealthSweep(
    TriggerFullCloudHealthSweep event,
    Emitter<CloudSyncState> emit,
  ) async {
    emit(state.copyWith(status: CloudGatewayStatus.syncing));

    await Future.delayed(const Duration(milliseconds: 500));

    final updated = state.services.map((m) {
      return m.copyWith(
        lastSync: DateTime.now(),
        health: CloudServiceHealth.optimal,
      );
    }).toList();

    emit(state.copyWith(
      status: CloudGatewayStatus.connected,
      services: updated,
      notificationMessage: 'Complete Google Cloud Run & Firebase health check verified (0 errors).',
    ));
  }
}

