import 'package:equatable/equatable.dart';

abstract class CloudSyncEvent extends Equatable {
  const CloudSyncEvent();

  @override
  List<Object?> get props => [];
}

class LoadCloudSyncStatus extends CloudSyncEvent {
  const LoadCloudSyncStatus();
}

class TriggerManualSyncService extends CloudSyncEvent {
  final String serviceName;
  const TriggerManualSyncService(this.serviceName);

  @override
  List<Object?> get props => [serviceName];
}

class TriggerFullCloudHealthSweep extends CloudSyncEvent {
  const TriggerFullCloudHealthSweep();
}

