import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

class TacticalStatusTicker extends StatelessWidget {
  final int activeConvoysCount;
  final int pendingDispatchCount;
  final int activeSosCount;
  final VoidCallback onRefreshAirspace;

  const TacticalStatusTicker({
    super.key,
    required this.activeConvoysCount,
    required this.pendingDispatchCount,
    required this.activeSosCount,
    required this.onRefreshAirspace,
  });

  @override
  Widget build(BuildContext context) {
    final hasDistress = activeSosCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: hasDistress ? AviationColors.alertRed.withValues(alpha: 0.18) : AviationColors.surfaceDark,
        border: Border(
          bottom: BorderSide(
            color: hasDistress ? AviationColors.alertRed : AviationColors.goldTrim.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasDistress ? AviationColors.alertRed : AviationColors.statusGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasDistress ? Icons.warning_amber_rounded : Icons.radio,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  hasDistress ? 'DEFCON 2' : 'RADAR LIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _tickerMetric('CONVOYS', '$activeConvoysCount UNITS', AviationColors.goldTrim),
          const SizedBox(width: 12),
          _tickerMetric('PENDING', '$pendingDispatchCount JOBS', AviationColors.statusOrange),
          const SizedBox(width: 12),
          _tickerMetric(
            'DISTRESS',
            '$activeSosCount SOS',
            hasDistress ? AviationColors.alertRed : AviationColors.textSecondary,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: AviationColors.goldTrim),
            tooltip: 'Sync Airspace Telemetry',
            onPressed: onRefreshAirspace,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _tickerMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AviationColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
