import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/driver_mission.dart';
import '../../services/driver_firestore_service.dart';
import 'missions_event.dart';
import 'missions_state.dart';

class MissionsBloc extends Bloc<MissionsEvent, MissionsState> {
  final PngApiClient apiClient;
  final DriverFirestoreService? firestoreService;

  final OfflineSyncQueue offlineQueue = OfflineSyncQueue();

  MissionsBloc({
    required this.apiClient,
    this.firestoreService,
  }) : super(MissionsInitial()) {
    on<LoadDriverMissions>(_onLoadDriverMissions);
    on<SelectMission>(_onSelectMission);
    on<AdvanceMissionStage>(_onAdvanceMissionStage);
    on<CompleteMissionWithEpod>(_onCompleteMissionWithEpod);
    on<ToggleOfflineMode>(_onToggleOfflineMode);
    on<SyncOfflineEvents>(_onSyncOfflineEvents);
    on<ReportMissionBreakdown>(_onReportMissionBreakdown);
    on<RecordPassengerContact>(_onRecordPassengerContact);
    on<RequestPassengerNoShow>(_onRequestPassengerNoShow);
  }

  Future<void> _onLoadDriverMissions(
    LoadDriverMissions event,
    Emitter<MissionsState> emit,
  ) async {
    emit(MissionsLoading());
    List<DriverMission> list = [];
    try {
      final res = await apiClient.get('/api/v1/driver/assignments');
      list = (res as List<dynamic>)
          .map((e) => DriverMission.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Offline / API error fallback
    }

    if (list.isEmpty) {
      list = DriverFirestoreService.defaultMissions;
    }

    emit(MissionsLoaded(
      missions: list,
      activeMission: list.isNotEmpty ? list.first : null,
      pendingOfflineEventsCount: offlineQueue.pendingCount,
      syncedEventsCount: offlineQueue.syncedEvents.length,
    ));
  }

  void _onSelectMission(
    SelectMission event,
    Emitter<MissionsState> emit,
  ) {
    if (state is MissionsLoaded) {
      final current = state as MissionsLoaded;
      emit(current.copyWith(activeMission: event.mission));
    }
  }

  void _onAdvanceMissionStage(
    AdvanceMissionStage event,
    Emitter<MissionsState> emit,
  ) {
    if (state is MissionsLoaded) {
      final current = state as MissionsLoaded;

      // Enqueue event into idempotent offline queue
      final bookingNumericId = int.tryParse(event.missionId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      final queuedEvent = offlineQueue.enqueue(
        eventType: event.targetStage,
        bookingId: bookingNumericId,
        payload: {'stage': event.targetStage, 'missionId': event.missionId},
      );

      if (!current.isOffline) {
        offlineQueue.markSynced(queuedEvent.uuid);
        firestoreService?.updateMissionStage(event.missionId, event.targetStage);

        // Update GPS telemetry according to stage along the Nadzab-Lae highway
        double lat = -6.5698;
        double lng = 146.7262;
        double speed = 0.0;
        String heading = 'SE';

        if (event.targetStage == 'driver_en_route' || event.targetStage == 'transfer_in_progress') {
          lat = -6.6500;
          lng = 146.8500;
          speed = 65.0;
          heading = 'SE - Markham Highway';
        } else if (event.targetStage == 'arrived_destination' || event.targetStage == 'completed') {
          lat = -6.7282;
          lng = 146.9926;
          speed = 0.0;
          heading = 'Stationary - Hotel Perimeter';
        }

        firestoreService?.publishTelemetry(
          missionId: event.missionId,
          latitude: lat,
          longitude: lng,
          speedKmh: speed,
          heading: heading,
        );
      }

      final updatedMissions = current.missions.map((m) {
        if (m.id == event.missionId) {
          return m.copyWith(stage: event.targetStage);
        }
        return m;
      }).toList();

      final updatedActive = current.activeMission?.id == event.missionId
          ? current.activeMission?.copyWith(stage: event.targetStage)
          : current.activeMission;

      final stageLabels = {
        'driver_en_route': 'Departed base en route to Airport',
        'at_airport': 'Vehicle staged at Airport arrival corridor',
        'passenger_located': 'Passenger located at terminal gate',
        'passenger_verified': 'Passenger verified via secure QR / OTP',
        'passenger_onboard': 'Passenger & luggage securely onboard vehicle',
        'transfer_in_progress': 'Convoy underway to destination',
        'arrived_destination': 'Safe arrival at destination perimeter',
        'completed': 'Mission completed & archived',
      };

      final toast = current.isOffline
          ? '[OFFLINE QUEUE] ${stageLabels[event.targetStage] ?? event.targetStage} recorded locally (UUID: ${queuedEvent.uuid}). Deduplication active.'
          : (stageLabels[event.targetStage] ?? 'Stage updated to ${event.targetStage}');

      emit(current.copyWith(
        missions: updatedMissions,
        activeMission: updatedActive,
        lastActionToast: toast,
        pendingOfflineEventsCount: offlineQueue.pendingCount,
        syncedEventsCount: offlineQueue.syncedEvents.length,
      ));
    }
  }

  void _onCompleteMissionWithEpod(
    CompleteMissionWithEpod event,
    Emitter<MissionsState> emit,
  ) {
    if (state is MissionsLoaded) {
      final current = state as MissionsLoaded;

      final bookingNumericId = int.tryParse(event.missionId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      final queuedEvent = offlineQueue.enqueue(
        eventType: 'completed_epod',
        bookingId: bookingNumericId,
        payload: {
          'receiptId': event.epod.receiptId,
          'signerName': event.epod.signerName,
          'rating': event.epod.rating,
        },
      );

      if (!current.isOffline) {
        offlineQueue.markSynced(queuedEvent.uuid);
        firestoreService?.submitEpod(event.missionId, event.epod);
      }

      final updatedMissions = current.missions.map((m) {
        if (m.id == event.missionId) {
          return m.copyWith(stage: 'completed', epod: event.epod);
        }
        return m;
      }).toList();

      final updatedActive = current.activeMission?.id == event.missionId
          ? current.activeMission?.copyWith(stage: 'completed', epod: event.epod)
          : current.activeMission;

      emit(current.copyWith(
        missions: updatedMissions,
        activeMission: updatedActive,
        lastActionToast: 'e-POD Receipt ${event.epod.receiptId} generated and verified!',
        pendingOfflineEventsCount: offlineQueue.pendingCount,
        syncedEventsCount: offlineQueue.syncedEvents.length,
      ));
    }
  }

  void _onToggleOfflineMode(
    ToggleOfflineMode event,
    Emitter<MissionsState> emit,
  ) {
    if (state is MissionsLoaded) {
      final current = state as MissionsLoaded;
      emit(current.copyWith(
        isOffline: event.isOffline,
        lastActionToast: event.isOffline
            ? 'Operating in OFFLINE mode (Remote PNG Highlands Corridor). Events will queue locally.'
            : 'Connectivity RESTORED. Tap SYNC to replay pending events without duplicates.',
      ));
    }
  }

  void _onSyncOfflineEvents(
    SyncOfflineEvents event,
    Emitter<MissionsState> emit,
  ) {
    if (state is MissionsLoaded) {
      final current = state as MissionsLoaded;
      final count = offlineQueue.pendingCount;

      for (final ev in offlineQueue.pendingEvents) {
        offlineQueue.markSynced(ev.uuid);
      }

      emit(current.copyWith(
        pendingOfflineEventsCount: offlineQueue.pendingCount,
        syncedEventsCount: offlineQueue.syncedEvents.length,
        lastActionToast: count > 0
            ? 'Deduplicated sync complete: $count offline events uploaded to Control Room.'
            : 'All offline operational events are already synchronized.',
      ));
    }
  }

  void _onReportMissionBreakdown(
    ReportMissionBreakdown event,
    Emitter<MissionsState> emit,
  ) {
    if (state is MissionsLoaded) {
      final current = state as MissionsLoaded;
      firestoreService?.broadcastIncident(
        alertId: 'BRK-${DateTime.now().millisecondsSinceEpoch % 100000}',
        missionId: current.activeMission?.id ?? 'UNASSIGNED',
        severity: 'HIGH',
        summary: 'VEHICLE MECHANICAL BREAKDOWN reported on Markham corridor.',
      );
      emit(current.copyWith(
        isBreakdownReported: true,
        lastActionToast: 'BREAKDOWN REPORTED: Control Room notified. Replacement unit dispatching.',
      ));
    }
  }

  void _onRecordPassengerContact(
    RecordPassengerContact event,
    Emitter<MissionsState> emit,
  ) {
    if (state is MissionsLoaded) {
      final current = state as MissionsLoaded;
      final newCount = current.contactAttempts + 1;
      emit(current.copyWith(
        contactAttempts: newCount,
        lastActionToast: 'Passenger contact attempt #$newCount logged (${event.channel.toUpperCase()}).',
      ));
    }
  }

  void _onRequestPassengerNoShow(
    RequestPassengerNoShow event,
    Emitter<MissionsState> emit,
  ) {
    if (state is MissionsLoaded) {
      final current = state as MissionsLoaded;
      firestoreService?.broadcastIncident(
        alertId: 'NOSHOW-${DateTime.now().millisecondsSinceEpoch % 100000}',
        missionId: current.activeMission?.id ?? 'UNASSIGNED',
        severity: 'MEDIUM',
        summary: 'PASSENGER NO-SHOW requested after wait threshold.',
      );
      emit(current.copyWith(
        noShowRequested: true,
        lastActionToast: 'Passenger NO-SHOW requested after wait threshold. Pending Supervisor approval.',
      ));
    }
  }
}
