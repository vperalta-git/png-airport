import 'package:equatable/equatable.dart';
import '../../models/dispatch_job.dart';

enum DispatchStatus { initial, loading, loaded, failure }

class DispatchState extends Equatable {
  final DispatchStatus status;
  final List<DispatchJob> pendingJobs;
  final List<DispatchJob> completedDispatches;
  final String? notificationMessage;

  const DispatchState({
    this.status = DispatchStatus.initial,
    this.pendingJobs = const [],
    this.completedDispatches = const [],
    this.notificationMessage,
  });

  int get pendingCount => pendingJobs.where((j) => !j.isDispatched).length;

  DispatchState copyWith({
    DispatchStatus? status,
    List<DispatchJob>? pendingJobs,
    List<DispatchJob>? completedDispatches,
    String? notificationMessage,
  }) {
    return DispatchState(
      status: status ?? this.status,
      pendingJobs: pendingJobs ?? this.pendingJobs,
      completedDispatches: completedDispatches ?? this.completedDispatches,
      notificationMessage: notificationMessage ?? this.notificationMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pendingJobs,
        completedDispatches,
        notificationMessage,
      ];
}
