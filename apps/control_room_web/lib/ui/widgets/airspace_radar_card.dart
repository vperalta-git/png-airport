import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

class AirspaceRadarCard extends StatelessWidget {
  final FlightRadarFlight flight;
  final VoidCallback onAssignEscort;

  const AirspaceRadarCard({
    super.key,
    required this.flight,
    required this.onAssignEscort,
  });

  @override
  Widget build(BuildContext context) {
    final etaStr = flight.estimatedTime.isNotEmpty
        ? flight.estimatedTime
        : flight.scheduledTime;
    final isDelayed = flight.delayMinutes > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AviationColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDelayed ? AviationColors.alertRed : AviationColors.surfaceBorder,
          width: isDelayed ? 1.5 : 1.0,
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
                  border: Border.all(
                    color: AviationColors.goldTrim.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  flight.code,
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
                  flight.carrier,
                  style: const TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDelayed
                      ? AviationColors.alertRed.withValues(alpha: 0.2)
                      : AviationColors.statusGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  flight.status.toUpperCase(),
                  style: TextStyle(
                    color: isDelayed ? AviationColors.alertRed : AviationColors.statusGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ROUTE',
                        style: TextStyle(color: AviationColors.textSecondary, fontSize: 9)),
                    Text(
                      '${flight.originCode} ➔ ${flight.destCode}',
                      style: const TextStyle(
                        color: AviationColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${flight.originCity} to ${flight.destCity}',
                      style: const TextStyle(color: AviationColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('ETA / TIME',
                      style: TextStyle(color: AviationColors.textSecondary, fontSize: 9)),
                  Text(
                    etaStr,
                    style: const TextStyle(
                      color: AviationColors.goldTrim,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 18, color: AviationColors.surfaceBorder),
          Row(
            children: [
              const Icon(Icons.flight, size: 14, color: AviationColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Aircraft: ${flight.aircraft}${flight.gate != null ? ' | Gate ${flight.gate}' : ''}',
                  style: const TextStyle(
                    color: AviationColors.textSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.shield, size: 13),
                label: const Text('Dispatch Escort', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AviationColors.goldTrim,
                  foregroundColor: AviationColors.darkBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 28),
                ),
                onPressed: onAssignEscort,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
