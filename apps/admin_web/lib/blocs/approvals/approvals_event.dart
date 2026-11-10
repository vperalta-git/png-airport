import 'package:equatable/equatable.dart';

abstract class ApprovalsEvent extends Equatable {
  const ApprovalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadEscortApprovals extends ApprovalsEvent {
  const LoadEscortApprovals();
}

class ApproveEscortRequest extends ApprovalsEvent {
  final String approvalId;
  final String supervisorNotes;

  const ApproveEscortRequest({
    required this.approvalId,
    required this.supervisorNotes,
  });

  @override
  List<Object?> get props => [approvalId, supervisorNotes];
}

class RejectEscortRequest extends ApprovalsEvent {
  final String approvalId;
  final String rejectionReason;

  const RejectEscortRequest({
    required this.approvalId,
    required this.rejectionReason,
  });

  @override
  List<Object?> get props => [approvalId, rejectionReason];
}
