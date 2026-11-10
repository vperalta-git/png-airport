import 'package:equatable/equatable.dart';

enum CloudServiceHealth { optimal, syncing, warning, error }

class CloudServiceModel extends Equatable {
  final String serviceName; // e.g. "Cloud Firestore: bookings"
  final String displayName; // e.g. "Operational Booking Engine"
  final int recordCount;
  final DateTime lastSync;
  final CloudServiceHealth health;
  final String? errorMessage;

  const CloudServiceModel({
    required this.serviceName,
    required this.displayName,
    required this.recordCount,
    required this.lastSync,
    required this.health,
    this.errorMessage,
  });

  CloudServiceModel copyWith({
    String? serviceName,
    String? displayName,
    int? recordCount,
    DateTime? lastSync,
    CloudServiceHealth health = CloudServiceHealth.optimal,
    String? errorMessage,
  }) {
    return CloudServiceModel(
      serviceName: serviceName ?? this.serviceName,
      displayName: displayName ?? this.displayName,
      recordCount: recordCount ?? this.recordCount,
      lastSync: lastSync ?? this.lastSync,
      health: health,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        serviceName,
        displayName,
        recordCount,
        lastSync,
        health,
        errorMessage,
      ];
}

