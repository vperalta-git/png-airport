import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/convoy_unit.dart';

class ConvoyUnitCard extends StatelessWidget {
  final ConvoyUnit unit;
  final VoidCallback onPingRadio;
  final ValueChanged<ConvoyStatus> onStatusChange;

  const ConvoyUnitCard({
    super.key,
    required this.unit,
    required this.onPingRadio,
    required this.onStatusChange,
  });

  Color _getStatusColor(ConvoyStatus status) {
    switch (status) {
      case ConvoyStatus.idleAtBase:
        return AviationColors.textSecondary;
      case ConvoyStatus.stagedAtAirport:
        return AviationColors.goldTrim;
      case ConvoyStatus.passengerBoarded:
        return AviationColors.statusBlue;
      case ConvoyStatus.inTransit:
        return AviationColors.statusGreen;
      case ConvoyStatus.atDestination:
        return Colors.tealAccent;
      case ConvoyStatus.distress:
        return AviationColors.alertRed;
    }
  }

  String _getStatusLabel(ConvoyStatus status) {
    switch (status) {
      case ConvoyStatus.idleAtBase:
        return 'IDLE AT BASE';
      case ConvoyStatus.stagedAtAirport:
        return 'STAGED AT AIRPORT';
      case ConvoyStatus.passengerBoarded:
        return 'PAX ON BOARD';
      case ConvoyStatus.inTransit:
        return 'IN TRANSIT';
      case ConvoyStatus.atDestination:
        return 'DESTINATION REACHED';
      case ConvoyStatus.distress:
        return 'DISTRESS / SOS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(unit.status);
    final lastPingStr = DateFormat('HH:mm:ss').format(unit.lastPing);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AviationColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: unit.status == ConvoyStatus.distress
              ? AviationColors.alertRed
              : AviationColors.surfaceBorder,
          width: unit.status == ConvoyStatus.distress ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unit.callsign,
                  style: const TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusLabel(unit.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${unit.vehicleName} [${unit.plateNumber}]',
            style: const TextStyle(color: AviationColors.goldTrim, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person, size: 13, color: AviationColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Driver: ${unit.driverName}',
                style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(width: 10),
              if (unit.hasArmedEscort) ...[
                const Icon(Icons.shield, size: 13, color: AviationColors.goldTrim),
                const SizedBox(width: 4),
                Text(
                  unit.leadSecurityOfficer,
                  style: const TextStyle(color: AviationColors.goldTrim, fontSize: 11),
                ),
              ],
            ],
          ),
          if (unit.passengerName != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AviationColors.surfaceDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge, size: 13, color: AviationColors.goldTrim),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pax: ${unit.passengerName} (Ref: ${unit.activeBookingRef})',
                      style: const TextStyle(
                        color: AviationColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 13, color: AviationColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${unit.currentZone} ➔ ${unit.destination}',
                  style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: AviationColors.surfaceBorder),
          Row(
            children: [
              Text(
                'Spd: ${unit.currentSpeedKmh.toStringAsFixed(0)} km/h | Fuel: ${unit.fuelPercent}% | Ping: $lastPingStr',
                style: const TextStyle(
                  color: AviationColors.textSecondary,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.podcasts, size: 13),
                label: const Text('Ping HF', style: TextStyle(fontSize: 10)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AviationColors.goldTrim,
                  side: const BorderSide(color: AviationColors.goldTrim),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: const Size(0, 26),
                ),
                onPressed: onPingRadio,
              ),
              const SizedBox(width: 6),
              PopupMenuButton<ConvoyStatus>(
                tooltip: 'Change Stage',
                icon: const Icon(Icons.more_vert, size: 18, color: AviationColors.textSecondary),
                onSelected: onStatusChange,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ConvoyStatus.stagedAtAirport,
                    child: Text('Staged at Airport'),
                  ),
                  const PopupMenuItem(
                    value: ConvoyStatus.passengerBoarded,
                    child: Text('Passenger Boarded'),
                  ),
                  const PopupMenuItem(
                    value: ConvoyStatus.inTransit,
                    child: Text('In Transit (High Risk)'),
                  ),
                  const PopupMenuItem(
                    value: ConvoyStatus.atDestination,
                    child: Text('Safe Arrival at Destination'),
                  ),
                  const PopupMenuItem(
                    value: ConvoyStatus.idleAtBase,
                    child: Text('Returned to Base'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
