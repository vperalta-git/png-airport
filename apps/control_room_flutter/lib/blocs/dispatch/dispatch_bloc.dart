import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/dispatch_job.dart';
import '../../services/control_room_firestore_service.dart';
import 'dispatch_event.dart';
import 'dispatch_state.dart';

class DispatchBloc extends Bloc<DispatchEvent, DispatchState> {
  final PngApiClient? apiClient;
  final ControlRoomFirestoreService? firestoreService;

  DispatchBloc({
    this.apiClient,
    this.firestoreService,
  }) : super(const DispatchState()) {
    on<LoadDispatchQueue>(_onLoadDispatchQueue);
    on<AssignAndDispatchJob>(_onAssignAndDispatchJob);
  }

  Future<void> _onLoadDispatchQueue(
    LoadDispatchQueue event,
    Emitter<DispatchState> emit,
  ) async {
    emit(state.copyWith(status: DispatchStatus.loading));

    List<DispatchJob> jobs = [];
    if (apiClient != null) {
      try {
        final res = await apiClient!.get('/api/v1/dispatch/queue');
        jobs = (res as List<dynamic>)
            .map((e) => DispatchJob.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Fallback to Firestore / default
      }
    }

    if (jobs.isEmpty) {
      jobs = ControlRoomFirestoreService.defaultPendingJobs;
    }

    emit(state.copyWith(
      status: DispatchStatus.loaded,
      pendingJobs: jobs,
    ));
  }

  void _onAssignAndDispatchJob(
    AssignAndDispatchJob event,
    Emitter<DispatchState> emit,
  ) {
    // 1. Check for overlapping driver or vehicle conflict across active dispatches
    final activeDispatches = state.completedDispatches.where((j) => j.isDispatched).toList();
    final driverConflict = activeDispatches.where((j) => j.assignedDriverId == event.driverId && j.id != event.jobId).toList();
    final vehicleConflict = activeDispatches.where((j) => j.assignedVehicleCallsign == event.vehicleCallsign && j.id != event.jobId).toList();

    if (driverConflict.isNotEmpty) {
      emit(state.copyWith(
        notificationMessage:
            'CONFLICT BLOCKED: Driver ${event.driverName} is already committed to active mission ${driverConflict.first.bookingRef}. Concurrent assignment prevented.',
      ));
      return;
    }

    if (vehicleConflict.isNotEmpty) {
      emit(state.copyWith(
        notificationMessage:
            'CONFLICT BLOCKED: Vehicle ${event.vehicleCallsign} is already deployed on mission ${vehicleConflict.first.bookingRef}. Concurrent assignment prevented.',
      ));
      return;
    }

    final updatedPending = <DispatchJob>[];
    DispatchJob? dispatchedJob;

    for (final job in state.pendingJobs) {
      if (job.id == event.jobId) {
        dispatchedJob = job.copyWith(
          assignedDriverId: event.driverId,
          assignedDriverName: event.driverName,
          assignedVehicleCallsign: event.vehicleCallsign,
          isDispatched: true,
        );
      } else {
        updatedPending.add(job);
      }
    }

    final updatedCompleted = List<DispatchJob>.from(state.completedDispatches);
    if (dispatchedJob != null) {
      updatedCompleted.insert(0, dispatchedJob);

      // Write assignment directly to Firestore
      firestoreService?.assignJob(
        jobId: event.jobId,
        driverId: event.driverId,
        driverName: event.driverName,
        vehicleCallsign: event.vehicleCallsign,
      );
    }

    emit(state.copyWith(
      pendingJobs: updatedPending,
      completedDispatches: updatedCompleted,
      notificationMessage:
          'Mission ${dispatchedJob?.bookingRef ?? event.jobId} assigned to ${event.driverName} (${event.vehicleCallsign}) without conflicts and broadcast to field driver tablet.',
    ));
  }
}
