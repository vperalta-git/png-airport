import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSupervisorMetrics extends AnalyticsEvent {
  const LoadSupervisorMetrics();
}

class RefreshMetrics extends AnalyticsEvent {
  const RefreshMetrics();
}
