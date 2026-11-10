import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/dispatch_job.dart';

class DispatchAssignmentDialog extends StatefulWidget {
  final DispatchJob job;
  final Function(String driverId, String driverName, String vehicleCallsign) onConfirm;

  const DispatchAssignmentDialog({
    super.key,
    required this.job,
    required this.onConfirm,
  });

  @override
  State<DispatchAssignmentDialog> createState() => _DispatchAssignmentDialogState();
}

class _DispatchAssignmentDialogState extends State<DispatchAssignmentDialog> {
  final List<Map<String, String>> _availableDrivers = [
    {'id': 'drv_01', 'name': 'Ezekiel Morauta (Tactical B6 Qualified)'},
    {'id': 'drv_02', 'name': 'Lucas Kua (Convoy Lead)'},
    {'id': 'drv_03', 'name': 'Simon Temu (Highlands Route Expert)'},
    {'id': 'drv_04', 'name': 'Mathew Gawi (VIP Chauffeur)'},
  ];

  final List<String> _availableVehicles = [
    'Alpha-1 [Toyota LandCruiser 200 B6]',
    'Bravo-2 [Nissan Patrol Ti Armored]',
    'Delta-3 [Toyota Hilux Armed Escort]',
    'Echo-4 [Toyota Prado TXL]',
  ];

  late String _selectedDriverId;
  late String _selectedDriverName;
  late String _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _selectedDriverId = _availableDrivers.first['id']!;
    _selectedDriverName = _availableDrivers.first['name']!;
    _selectedVehicle = _availableVehicles.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AviationColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AviationColors.goldTrim),
      ),
      title: Row(
        children: [
          const Icon(Icons.assignment_ind, color: AviationColors.goldTrim, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Assign Escort Detail: ${widget.job.bookingRef}',
              style: const TextStyle(
                color: AviationColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleContext(
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
                    'Passenger: ${widget.job.passengerName} (${widget.job.passengerOrganization})',
                    style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Route: ${widget.job.pickupZone} ➔ ${widget.job.dropoffZone}',
                    style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (widget.job.requiresArmored)
                        _badge('B6 ARMORED REQUIRED', AviationColors.goldTrim),
                      const SizedBox(width: 6),
                      if (widget.job.requiresArmedEscort)
                        _badge('ARMED ESCORT REQUIRED', AviationColors.statusOrange),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'SELECT DRIVER / SECURITY OFFICER',
              style: TextStyle(
                color: AviationColors.goldTrim,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedDriverId,
              dropdownColor: AviationColors.cardBackground,
              style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12),
              decoration: const InputDecoration(
                filled: true,
                fillColor: AviationColors.surfaceDark,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: _availableDrivers.map((d) {
                return DropdownMenuItem<String>(
                  value: d['id'],
                  child: Text(d['name']!, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDriverId = val;
                    _selectedDriverName =
                        _availableDrivers.firstWhere((d) => d['id'] == val)['name']!;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'SELECT CONVOY VEHICLE CALLSIGN',
              style: TextStyle(
                color: AviationColors.goldTrim,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedVehicle,
              dropdownColor: AviationColors.cardBackground,
              style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12),
              decoration: const InputDecoration(
                filled: true,
                fillColor: AviationColors.surfaceDark,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: _availableVehicles.map((v) {
                return DropdownMenuItem<String>(
                  value: v,
                  child: Text(v, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedVehicle = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AviationColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AviationColors.goldTrim,
            foregroundColor: AviationColors.darkBackground,
          ),
          onPressed: () {
            widget.onConfirm(_selectedDriverId, _selectedDriverName, _selectedVehicle);
            Navigator.pop(context);
          },
          child: const Text('Confirm & Transmit Roster'),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class SingleContext extends StatelessWidget {
  final Widget child;
  const SingleContext({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(child: child),
    );
  }
}
