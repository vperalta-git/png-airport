import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/sos_alert.dart';

class SosCommandDialog extends StatefulWidget {
  final SosAlert alert;
  final VoidCallback onAcknowledge;
  final Function(String qrfUnit, String instructions) onDispatchQrf;
  final Function(String report) onResolve;

  const SosCommandDialog({
    super.key,
    required this.alert,
    required this.onAcknowledge,
    required this.onDispatchQrf,
    required this.onResolve,
  });

  @override
  State<SosCommandDialog> createState() => _SosCommandDialogState();
}

class _SosCommandDialogState extends State<SosCommandDialog> {
  final _instructionsController = TextEditingController(
    text: 'Armed QRF backup en route. Provide security perimeter and secure principal.',
  );
  final _resolutionController = TextEditingController();
  String _selectedQrf = 'Echo-Reserve (Troopy QRF)';

  @override
  void dispose() {
    _instructionsController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AviationColors.darkBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AviationColors.alertRed, width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.emergency, color: AviationColors.alertRed, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'INCIDENT COMMAND: ${widget.alert.unitCallsign}',
              style: const TextStyle(
                color: AviationColors.alertRed,
                fontWeight: FontWeight.w900,
                fontSize: 14,
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
                  color: AviationColors.alertRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AviationColors.alertRed),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEVERITY: ${widget.alert.severity.name.toUpperCase()}',
                      style: const TextStyle(
                        color: AviationColors.alertRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Location: ${widget.alert.locationDesc}',
                      style: const TextStyle(color: AviationColors.textPrimary, fontSize: 11),
                    ),
                    Text(
                      'GPS: ${widget.alert.latitude}, ${widget.alert.longitude}',
                      style: const TextStyle(
                        color: AviationColors.goldTrim,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Driver Message: "${widget.alert.message}"',
                      style: const TextStyle(
                        color: AviationColors.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (widget.alert.status == AlertStatus.activeUnacknowledged) ...[
                const Text(
                  'STAGE 1: ACKNOWLEDGE ALERT',
                  style: TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Acknowledge & Open Hot-Channel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AviationColors.statusBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      widget.onAcknowledge();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'STAGE 2: SCRAMBLE QRF UNIT',
                style: TextStyle(
                  color: AviationColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedQrf,
                dropdownColor: AviationColors.cardBackground,
                style: const TextStyle(color: AviationColors.textPrimary, fontSize: 11),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AviationColors.surfaceDark,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Echo-Reserve (Troopy QRF)',
                    child: Text('Echo-Reserve (Troopy QRF - 7 Mile Base)'),
                  ),
                  DropdownMenuItem(
                    value: 'Delta-Armored-3 (Heavy Support)',
                    child: Text('Delta-Armored-3 (Heavy Support - Downtown)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedQrf = val);
                },
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _instructionsController,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                decoration: const InputDecoration(
                  labelText: 'Tactical Instructions to QRF',
                  labelStyle: TextStyle(color: AviationColors.textSecondary, fontSize: 11),
                  filled: true,
                  fillColor: AviationColors.surfaceDark,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.security, size: 16),
                  label: const Text('SCRAMBLE ARMED QRF NOW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AviationColors.alertRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.onDispatchQrf(_selectedQrf, _instructionsController.text);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: AviationColors.surfaceBorder),
              const Text(
                'STAGE 3: CLOSE & RESOLVE INCIDENT',
                style: TextStyle(
                  color: AviationColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _resolutionController,
                style: const TextStyle(color: AviationColors.textPrimary, fontSize: 11),
                decoration: const InputDecoration(
                  hintText: 'e.g. Escort rerouted safely, RPNGC secured route.',
                  hintStyle: TextStyle(color: AviationColors.textMuted, fontSize: 11),
                  filled: true,
                  fillColor: AviationColors.surfaceDark,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AviationColors.statusGreen,
                    side: const BorderSide(color: AviationColors.statusGreen),
                  ),
                  onPressed: () {
                    final report = _resolutionController.text.trim().isEmpty
                        ? 'Threat cleared, mission resumed safely.'
                        : _resolutionController.text.trim();
                    widget.onResolve(report);
                    Navigator.pop(context);
                  },
                  child: const Text('Mark Incident Resolved & Stand Down'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close Desk', style: TextStyle(color: AviationColors.textSecondary)),
        ),
      ],
    );
  }
}
