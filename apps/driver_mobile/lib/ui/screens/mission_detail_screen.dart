import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/driver_mission.dart';
import '../widgets/workflow_progress_bar.dart';

class MissionDetailScreen extends StatelessWidget {
  final DriverMission mission;
  final VoidCallback onTriggerNextStage;
  final String nextActionLabel;

  const MissionDetailScreen({
    super.key,
    required this.mission,
    required this.onTriggerNextStage,
    required this.nextActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MISSION ${mission.id} BRIEFING'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tactical Security Level Alert Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AviationColors.statusIncident.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AviationColors.statusIncident, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: AviationColors.statusIncident, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.securityLevel.toUpperCase(),
                        style: const TextStyle(
                          color: AviationColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Mandatory tactical escort. Maintain visual armed perimeter at tarmac & highway transit.',
                        style: TextStyle(color: AviationColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar
          WorkflowProgressBar(stage: mission.stage),
          const SizedBox(height: 16),

          // Route Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AviationColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AviationColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TRANSIT CORRIDOR', style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked, size: 18, color: AviationColors.gold500),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PICKUP POINT', style: TextStyle(color: AviationColors.textMuted, fontSize: 10)),
                          Text(mission.pickup, style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    height: 16,
                    child: VerticalDivider(color: AviationColors.cardBorder, thickness: 2),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: AviationColors.statusCompleted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DROP-OFF DESTINATION', style: TextStyle(color: AviationColors.textMuted, fontSize: 10)),
                          Text(mission.dropoff, style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Passenger Contacts & Flight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AviationColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AviationColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PASSENGER CONTACT DETAILS', style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(
                  mission.passengerName,
                  style: const TextStyle(color: AviationColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Flight: ${mission.flight} • ETA: ${mission.eta}',
                  style: const TextStyle(color: AviationColors.gold400, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.phone, size: 16, color: AviationColors.statusCompleted),
                        label: Text(mission.passengerPhone, style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AviationColors.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AviationColors.primaryNavy,
                              content: Text('Dialing ${mission.passengerPhone}...'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Special Instructions
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AviationColors.inputBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AviationColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TACTICAL INSTRUCTIONS & RULES OF ENGAGEMENT', style: TextStyle(color: AviationColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  mission.specialNotes,
                  style: const TextStyle(color: AviationColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Next Stage Button
          if (!mission.isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AviationColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onTriggerNextStage();
                },
                child: Text(
                  nextActionLabel,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
