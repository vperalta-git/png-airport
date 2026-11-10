import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/escort_approval.dart';

class ApprovalCard extends StatelessWidget {
  final EscortApproval request;
  final Function(String notes) onApprove;
  final Function(String reason) onReject;

  const ApprovalCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  Color _getRiskColor(EscortRiskLevel risk) {
    switch (risk) {
      case EscortRiskLevel.moderate:
        return AviationColors.statusOrange;
      case EscortRiskLevel.high:
        return Colors.orangeAccent;
      case EscortRiskLevel.severeCritical:
        return AviationColors.alertRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(request.riskLevel);
    final isPending = request.decision == ApprovalDecision.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AviationColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPending ? riskColor : AviationColors.surfaceBorder,
          width: isPending ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AviationColors.primaryNavy,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AviationColors.goldTrim.withValues(alpha: 0.5)),
                ),
                child: Text(
                  request.bookingRef,
                  style: const TextStyle(
                    color: AviationColors.goldTrim,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.clientOrganization,
                  style: const TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: riskColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  '${request.riskLevel.name.toUpperCase()} RISK',
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Passenger: ${request.passengerName}',
            style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.route, size: 14, color: AviationColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.routeDescription,
                  style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AviationColors.surfaceDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _specBadge(
                  Icons.shield,
                  request.requiresArmoredCruiser ? 'B6 ARMORED' : 'STANDARD',
                  request.requiresArmoredCruiser ? AviationColors.goldTrim : AviationColors.textSecondary,
                ),
                const SizedBox(width: 8),
                _specBadge(
                  Icons.person,
                  '${request.armedGuardsRequested} ARMED GUARDS',
                  AviationColors.statusBlue,
                ),
                if (request.requiresPoliceEscortVehicle) ...[
                  const SizedBox(width: 8),
                  _specBadge(
                    Icons.local_police,
                    'POLICE CHASE',
                    AviationColors.alertRed,
                  ),
                ],
                const Spacer(),
                Text(
                  'PGK ${request.quotePgk.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AviationColors.goldTrim,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (request.supervisorNotes != null) ...[
            const SizedBox(height: 8),
            Text(
              'Supervisor Decision: ${request.supervisorNotes}',
              style: TextStyle(
                color: request.decision == ApprovalDecision.approved
                    ? AviationColors.statusGreen
                    : AviationColors.alertRed,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const Divider(height: 18, color: AviationColors.surfaceBorder),
          Row(
            children: [
              Text(
                'Departure: ${DateFormat('dd MMM • HH:mm').format(request.scheduledDeparture)}',
                style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
              ),
              const Spacer(),
              if (isPending) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AviationColors.alertRed,
                    side: const BorderSide(color: AviationColors.alertRed),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  onPressed: () => _showRejectDialog(context),
                  child: const Text('Reject', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, size: 14),
                  label: const Text('Authorize Escort', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AviationColors.goldTrim,
                    foregroundColor: AviationColors.darkBackground,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  onPressed: () => _showApproveDialog(context),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (request.decision == ApprovalDecision.approved
                            ? AviationColors.statusGreen
                            : AviationColors.alertRed)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    request.decision.name.toUpperCase(),
                    style: TextStyle(
                      color: request.decision == ApprovalDecision.approved
                          ? AviationColors.statusGreen
                          : AviationColors.alertRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    final controller = TextEditingController(
      text: 'Approved: B6 LandCruiser + ${request.armedGuardsRequested} armed security assigned.',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AviationColors.cardBackground,
        title: const Text('Authorize High-Risk Convoy',
            style: TextStyle(color: AviationColors.textPrimary, fontSize: 14)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12),
          decoration: const InputDecoration(
            labelText: 'Supervisor Approval Note',
            labelStyle: TextStyle(color: AviationColors.textSecondary),
            filled: true,
            fillColor: AviationColors.surfaceDark,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AviationColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AviationColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              onApprove(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Authorize & Transmit to Desk'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController(
      text: 'Route too high risk for single convoy. Advise rescheduling to daylight hours.',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AviationColors.cardBackground,
        title: const Text('Reject Escort Request',
            style: TextStyle(color: AviationColors.alertRed, fontSize: 14)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12),
          decoration: const InputDecoration(
            labelText: 'Reason for Rejection',
            labelStyle: TextStyle(color: AviationColors.textSecondary),
            filled: true,
            fillColor: AviationColors.surfaceDark,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AviationColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AviationColors.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              onReject(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }
}
