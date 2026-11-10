import 'package:equatable/equatable.dart';
import '../../models/escort_approval.dart';

enum ApprovalsStatus { initial, loading, loaded, failure }

class ApprovalsState extends Equatable {
  final ApprovalsStatus status;
  final List<EscortApproval> approvals;
  final String? notificationMessage;

  const ApprovalsState({
    this.status = ApprovalsStatus.initial,
    this.approvals = const [],
    this.notificationMessage,
  });

  List<EscortApproval> get pendingQueue =>
      approvals.where((a) => a.decision == ApprovalDecision.pending).toList();

  List<EscortApproval> get historyQueue =>
      approvals.where((a) => a.decision != ApprovalDecision.pending).toList();

  ApprovalsState copyWith({
    ApprovalsStatus? status,
    List<EscortApproval>? approvals,
    String? notificationMessage,
  }) {
    return ApprovalsState(
      status: status ?? this.status,
      approvals: approvals ?? this.approvals,
      notificationMessage: notificationMessage ?? this.notificationMessage,
    );
  }

  @override
  List<Object?> get props => [status, approvals, notificationMessage];
}
