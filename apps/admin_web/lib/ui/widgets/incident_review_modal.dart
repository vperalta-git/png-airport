import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/incident_case.dart';

class IncidentReviewModal extends StatefulWidget {
  final IncidentCase incidentCase;
  final Function(String policeRef, String findings, String corrective) onUpdateInvestigation;
  final VoidCallback onCloseCase;

  const IncidentReviewModal({
    super.key,
    required this.incidentCase,
    required this.onUpdateInvestigation,
    required this.onCloseCase,
  });

  @override
  State<IncidentReviewModal> createState() => _IncidentReviewModalState();
}

class _IncidentReviewModalState extends State<IncidentReviewModal> {
  late final TextEditingController _policeController;
  late final TextEditingController _findingsController;
  late final TextEditingController _correctiveController;

  @override
  void initState() {
    super.initState();
    _policeController = TextEditingController(
      text: widget.incidentCase.policeReportNumber ?? 'RPNGC-NCD-2026-0881',
    );
    _findingsController = TextEditingController(
      text: widget.incidentCase.supervisorFindings ??
          'Principal protected with zero ballistic penetration. SOP followed accurately.',
    );
    _correctiveController = TextEditingController(
      text: widget.incidentCase.correctiveAction ??
          'Update risk map for upcoming evening mining VIP shuttles.',
    );
  }

  @override
  void dispose() {
    _policeController.dispose();
    _findingsController.dispose();
    _correctiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.incidentCase.status == IncidentStatus.closed;

    return AlertDialog(
      backgroundColor: AviationColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AviationColors.goldTrim),
      ),
      title: Row(
        children: [
          const Icon(Icons.gavel, color: AviationColors.goldTrim, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Incident Compliance: ${widget.incidentCase.id}',
              style: const TextStyle(
                color: AviationColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AviationColors.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission: ${widget.incidentCase.missionRef} • ${widget.incidentCase.unitCallsign}',
                      style: const TextStyle(
                        color: AviationColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${widget.incidentCase.incidentType} @ ${widget.incidentCase.location}',
                      style: const TextStyle(color: AviationColors.goldTrim, fontSize: 11),
                    ),
                    Text(
                      'Occurred: ${DateFormat('dd MMM yyyy • HH:mm').format(widget.incidentCase.occurrenceTime)}',
                      style: const TextStyle(color: AviationColors.textSecondary, fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Field Summary: "${widget.incidentCase.initialSummary}"',
                      style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ROYAL PNG CONSTABULARY (RPNGC) POLICE REPORT #',
                style: TextStyle(
                  color: AviationColors.goldTrim,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _policeController,
                enabled: !isClosed,
                style: const TextStyle(color: AviationColors.textPrimary, fontSize: 11),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AviationColors.surfaceDark,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'SUPERVISOR INVESTIGATION FINDINGS',
                style: TextStyle(
                  color: AviationColors.goldTrim,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _findingsController,
                enabled: !isClosed,
                maxLines: 2,
                style: const TextStyle(color: AviationColors.textPrimary, fontSize: 11),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AviationColors.surfaceDark,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'CORRECTIVE ACTION & INSURANCE SUBMISSION',
                style: TextStyle(
                  color: AviationColors.goldTrim,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _correctiveController,
                enabled: !isClosed,
                maxLines: 2,
                style: const TextStyle(color: AviationColors.textPrimary, fontSize: 11),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AviationColors.surfaceDark,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back', style: TextStyle(color: AviationColors.textSecondary)),
        ),
        if (!isClosed) ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AviationColors.statusBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.onUpdateInvestigation(
                _policeController.text,
                _findingsController.text,
                _correctiveController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save & Submit to Insurance'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AviationColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.onCloseCase();
              Navigator.pop(context);
            },
            child: const Text('Close Case'),
          ),
        ],
      ],
    );
  }
}
