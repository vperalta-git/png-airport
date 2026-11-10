import 'package:equatable/equatable.dart';
import '../../models/supervisor_metrics.dart';

enum AnalyticsStatus { initial, loading, loaded, failure }

class AnalyticsState extends Equatable {
  final AnalyticsStatus status;
  final SupervisorMetrics? metrics;
  final String? errorMessage;
  final DateTime lastUpdated;

  const AnalyticsState({
    this.status = AnalyticsStatus.initial,
    this.metrics,
    this.errorMessage,
    required this.lastUpdated,
  });

  AnalyticsState copyWith({
    AnalyticsStatus? status,
    SupervisorMetrics? metrics,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      metrics: metrics ?? this.metrics,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [status, metrics, errorMessage, lastUpdated];
}
