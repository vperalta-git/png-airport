import 'package:equatable/equatable.dart';
import '../../models/incident_case.dart';

enum IncidentReviewStatus { initial, loading, loaded, failure }

class SupervisorIncidentState extends Equatable {
  final IncidentReviewStatus status;
  final List<IncidentCase> cases;
  final String? notificationMessage;

  const SupervisorIncidentState({
    this.status = IncidentReviewStatus.initial,
    this.cases = const [],
    this.notificationMessage,
  });

  int get openCasesCount =>
      cases.where((c) => c.status != IncidentStatus.closed).length;

  SupervisorIncidentState copyWith({
    IncidentReviewStatus? status,
    List<IncidentCase>? cases,
    String? notificationMessage,
  }) {
    return SupervisorIncidentState(
      status: status ?? this.status,
      cases: cases ?? this.cases,
      notificationMessage: notificationMessage ?? this.notificationMessage,
    );
  }

  @override
  List<Object?> get props => [status, cases, notificationMessage];
}
