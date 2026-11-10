import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/supervisor_metrics.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc() : super(AnalyticsState(lastUpdated: DateTime.now())) {
    on<LoadSupervisorMetrics>(_onLoadSupervisorMetrics);
    on<RefreshMetrics>(_onRefreshMetrics);
  }

  void _onLoadSupervisorMetrics(
    LoadSupervisorMetrics event,
    Emitter<AnalyticsState> emit,
  ) {
    emit(state.copyWith(status: AnalyticsStatus.loading));

    final regional = [
      const RegionalMetric(
        hubName: "Port Moresby (POM - Jackson's)",
        activeMissions: 18,
        revenuePgk: 46800.0,
        onTimeRate: 98.2,
      ),
      const RegionalMetric(
        hubName: 'Lae (LAE - Nadzab)',
        activeMissions: 7,
        revenuePgk: 19400.0,
        onTimeRate: 95.0,
      ),
      const RegionalMetric(
        hubName: 'Mt Hagen (HGU - Kagamuga)',
        activeMissions: 4,
        revenuePgk: 14200.0,
        onTimeRate: 92.5,
      ),
      const RegionalMetric(
        hubName: 'Goroka (GKA)',
        activeMissions: 2,
        revenuePgk: 6800.0,
        onTimeRate: 100.0,
      ),
    ];

    final metrics = SupervisorMetrics(
      dailyRevenuePgk: 87200.0,
      mtdRevenuePgk: 1428500.0,
      totalMissionsToday: 31,
      completedMissionsToday: 24,
      onTimePerformanceRate: 97.4,
      activeVehicles: 22,
      totalFleet: 28,
      armoredVehiclesInField: 14,
      activeIncidentsCount: 1,
      regionalMetrics: regional,
    );

    emit(state.copyWith(
      status: AnalyticsStatus.loaded,
      metrics: metrics,
      lastUpdated: DateTime.now(),
    ));
  }

  void _onRefreshMetrics(
    RefreshMetrics event,
    Emitter<AnalyticsState> emit,
  ) {
    add(const LoadSupervisorMetrics());
  }
}
