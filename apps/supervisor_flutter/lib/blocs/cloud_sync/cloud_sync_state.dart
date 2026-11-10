import 'package:equatable/equatable.dart';
import '../../models/cloud_service_status.dart';

enum CloudGatewayStatus { initial, connecting, connected, syncing, error }

class CloudSyncState extends Equatable {
  final CloudGatewayStatus status;
  final List<CloudServiceModel> services;
  final String cloudRunEndpoint;
  final int latencyMs;
  final String? notificationMessage;

  const CloudSyncState({
    this.status = CloudGatewayStatus.initial,
    this.services = const [],
    this.cloudRunEndpoint = 'https://png-transfer-backend-asia-southeast1.run.app',
    this.latencyMs = 38,
    this.notificationMessage,
  });

  CloudSyncState copyWith({
    CloudGatewayStatus? status,
    List<CloudServiceModel>? services,
    String? cloudRunEndpoint,
    int? latencyMs,
    String? notificationMessage,
  }) {
    return CloudSyncState(
      status: status ?? this.status,
      services: services ?? this.services,
      cloudRunEndpoint: cloudRunEndpoint ?? this.cloudRunEndpoint,
      latencyMs: latencyMs ?? this.latencyMs,
      notificationMessage: notificationMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        services,
        cloudRunEndpoint,
        latencyMs,
        notificationMessage,
      ];
}

