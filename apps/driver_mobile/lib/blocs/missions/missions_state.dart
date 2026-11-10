import 'package:equatable/equatable.dart';
import '../../models/driver_mission.dart';

abstract class MissionsState extends Equatable {
  const MissionsState();
  @override
  List<Object?> get props => [];
}

class MissionsInitial extends MissionsState {}

class MissionsLoading extends MissionsState {}

class MissionsLoaded extends MissionsState {
  final List<DriverMission> missions;
  final DriverMission? activeMission;
  final String? lastActionToast;
  final bool isOffline;
  final int pendingOfflineEventsCount;
  final int syncedEventsCount;
  final int contactAttempts;
  final bool isBreakdownReported;
  final bool noShowRequested;

  const MissionsLoaded({
    required this.missions,
    this.activeMission,
    this.lastActionToast,
    this.isOffline = false,
    this.pendingOfflineEventsCount = 0,
    this.syncedEventsCount = 0,
    this.contactAttempts = 0,
    this.isBreakdownReported = false,
    this.noShowRequested = false,
  });

  MissionsLoaded copyWith({
    List<DriverMission>? missions,
    DriverMission? activeMission,
    String? lastActionToast,
    bool? isOffline,
    int? pendingOfflineEventsCount,
    int? syncedEventsCount,
    int? contactAttempts,
    bool? isBreakdownReported,
    bool? noShowRequested,
  }) {
    return MissionsLoaded(
      missions: missions ?? this.missions,
      activeMission: activeMission ?? this.activeMission,
      lastActionToast: lastActionToast,
      isOffline: isOffline ?? this.isOffline,
      pendingOfflineEventsCount: pendingOfflineEventsCount ?? this.pendingOfflineEventsCount,
      syncedEventsCount: syncedEventsCount ?? this.syncedEventsCount,
      contactAttempts: contactAttempts ?? this.contactAttempts,
      isBreakdownReported: isBreakdownReported ?? this.isBreakdownReported,
      noShowRequested: noShowRequested ?? this.noShowRequested,
    );
  }

  @override
  List<Object?> get props => [
        missions,
        activeMission,
        lastActionToast,
        isOffline,
        pendingOfflineEventsCount,
        syncedEventsCount,
        contactAttempts,
        isBreakdownReported,
        noShowRequested,
      ];
}

class MissionsError extends MissionsState {
  final String message;
  const MissionsError(this.message);
  @override
  List<Object?> get props => [message];
}
