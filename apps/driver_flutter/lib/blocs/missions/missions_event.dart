import 'package:equatable/equatable.dart';
import '../../models/driver_mission.dart';

abstract class MissionsEvent extends Equatable {
  const MissionsEvent();
  @override
  List<Object?> get props => [];
}

class LoadDriverMissions extends MissionsEvent {
  final bool forceRefresh;
  const LoadDriverMissions({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class SelectMission extends MissionsEvent {
  final DriverMission mission;
  const SelectMission(this.mission);
  @override
  List<Object?> get props => [mission];
}

class AdvanceMissionStage extends MissionsEvent {
  final String missionId;
  final String targetStage;
  const AdvanceMissionStage({required this.missionId, required this.targetStage});
  @override
  List<Object?> get props => [missionId, targetStage];
}

class CompleteMissionWithEpod extends MissionsEvent {
  final String missionId;
  final EpodData epod;
  const CompleteMissionWithEpod({required this.missionId, required this.epod});
  @override
  List<Object?> get props => [missionId, epod];
}

class ToggleOfflineMode extends MissionsEvent {
  final bool isOffline;
  const ToggleOfflineMode(this.isOffline);
  @override
  List<Object?> get props => [isOffline];
}

class SyncOfflineEvents extends MissionsEvent {
  const SyncOfflineEvents();
}

class ReportMissionBreakdown extends MissionsEvent {
  final String missionId;
  final String description;
  const ReportMissionBreakdown({required this.missionId, required this.description});
  @override
  List<Object?> get props => [missionId, description];
}

class RecordPassengerContact extends MissionsEvent {
  final String missionId;
  final String channel;
  final String notes;
  const RecordPassengerContact({required this.missionId, required this.channel, required this.notes});
  @override
  List<Object?> get props => [missionId, channel, notes];
}

class RequestPassengerNoShow extends MissionsEvent {
  final String missionId;
  final String reason;
  const RequestPassengerNoShow({required this.missionId, required this.reason});
  @override
  List<Object?> get props => [missionId, reason];
}
