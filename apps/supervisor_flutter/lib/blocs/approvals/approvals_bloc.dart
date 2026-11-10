import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/escort_approval.dart';
import 'approvals_event.dart';
import 'approvals_state.dart';

class ApprovalsBloc extends Bloc<ApprovalsEvent, ApprovalsState> {
  final PngApiClient? apiClient;

  ApprovalsBloc({this.apiClient}) : super(const ApprovalsState()) {
    on<LoadEscortApprovals>(_onLoadEscortApprovals);
    on<ApproveEscortRequest>(_onApproveEscortRequest);
    on<RejectEscortRequest>(_onRejectEscortRequest);
  }

  Future<void> _onLoadEscortApprovals(
    LoadEscortApprovals event,
    Emitter<ApprovalsState> emit,
  ) async {
    emit(state.copyWith(status: ApprovalsStatus.loading));

    if (apiClient != null) {
      try {
        final res = await apiClient!.get('/api/v1/supervisor/approvals');
        final list = (res as List<dynamic>)
            .map((e) => EscortApproval.fromJson(e as Map<String, dynamic>))
            .toList();
        emit(state.copyWith(
          status: ApprovalsStatus.loaded,
          approvals: list,
        ));
        return;
      } catch (_) {
        // Fallback to empty if offline
      }
    }

    emit(state.copyWith(
      status: ApprovalsStatus.loaded,
      approvals: const [],
    ));
  }

  void _onApproveEscortRequest(
    ApproveEscortRequest event,
    Emitter<ApprovalsState> emit,
  ) {
    final updated = state.approvals.map((req) {
      if (req.id == event.approvalId) {
        return req.copyWith(
          decision: ApprovalDecision.approved,
          supervisorNotes: event.supervisorNotes,
          reviewedAt: DateTime.now(),
        );
      }
      return req;
    }).toList();

    emit(state.copyWith(
      approvals: updated,
      notificationMessage:
          'Escort Mission ${event.approvalId} APPROVED by Supervisor. Dispatched to Control Room for allocation.',
    ));
  }

  void _onRejectEscortRequest(
    RejectEscortRequest event,
    Emitter<ApprovalsState> emit,
  ) {
    if (event.rejectionReason.trim().isEmpty) {
      emit(state.copyWith(
        notificationMessage: 'REJECTION BLOCKED: A recorded justification reason is mandatory to reject an exception.',
      ));
      return;
    }

    final updated = state.approvals.map((req) {
      if (req.id == event.approvalId) {
        return req.copyWith(
          decision: ApprovalDecision.rejected,
          supervisorNotes: 'REJECTED: ${event.rejectionReason.trim()}',
          reviewedAt: DateTime.now(),
        );
      }
      return req;
    }).toList();

    emit(state.copyWith(
      approvals: updated,
      notificationMessage:
          'Escort Mission ${event.approvalId} REJECTED with recorded reason: "${event.rejectionReason.trim()}". Returned to Client.',
    ));
  }
}
