import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

class WorkflowProgressBar extends StatelessWidget {
  final String stage;

  const WorkflowProgressBar({super.key, required this.stage});

  int _stageIndex(String s) {
    switch (s) {
      case 'assigned':
        return 0;
      case 'driver_en_route':
        return 1;
      case 'at_airport':
        return 2;
      case 'passenger_located':
        return 3;
      case 'passenger_verified':
      case 'passenger_onboard':
        return 4;
      case 'transfer_in_progress':
      case 'arrived_destination':
        return 5;
      case 'completed':
        return 6;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _stageIndex(stage);
    final labels = ['Depart', 'Airport', 'Located', 'Verified', 'Convoy', 'Dropoff'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AviationColors.navy800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AviationColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TRANSIT PROGRESSION',
                style: TextStyle(
                  color: AviationColors.gold400,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'STAGE ${currentIndex.clamp(1, 6)} OF 6',
                style: const TextStyle(
                  color: AviationColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(labels.length, (index) {
              final stepNum = index + 1;
              final isPassed = stepNum <= currentIndex;
              final isCurrent = stepNum == currentIndex;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: isPassed
                                  ? (isCurrent ? AviationColors.gold500 : AviationColors.statusCompleted)
                                  : AviationColors.cardBorder,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent
                                  ? AviationColors.gold400
                                  : isPassed
                                      ? Colors.white70
                                      : AviationColors.textMuted,
                              fontSize: 9,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < labels.length - 1) const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
