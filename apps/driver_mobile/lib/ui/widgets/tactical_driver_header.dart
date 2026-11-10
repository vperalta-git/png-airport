import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../blocs/duty/duty_bloc.dart';
import '../../blocs/duty/duty_event.dart';
import '../../blocs/duty/duty_state.dart';
import 'incident_modal.dart';

class TacticalDriverHeader extends StatelessWidget implements PreferredSizeWidget {
  final String activeMissionId;

  const TacticalDriverHeader({
    super.key,
    this.activeMissionId = 'DISPATCH-STANDBY',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AviationColors.cardBackground,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AviationColors.cardBorder, width: 1)),
          ),
          child: BlocBuilder<DutyBloc, DutyState>(
            builder: (context, state) {
              return Row(
                children: [
                  // Unit Icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: state.isOnDuty
                          ? AviationColors.statusVerified.withValues(alpha: 0.15)
                          : AviationColors.cardBorder,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: state.isOnDuty ? AviationColors.statusVerified : AviationColors.cardBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        state.isOnDuty ? '🛡️' : '⏸️',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Call sign & Driver info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              state.callsign,
                              style: const TextStyle(
                                color: AviationColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: state.isOnDuty
                                    ? AviationColors.statusCompleted.withValues(alpha: 0.2)
                                    : AviationColors.textMuted.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                state.isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                                style: TextStyle(
                                  color: state.isOnDuty ? AviationColors.statusCompleted : AviationColors.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.assignedVehicle,
                          style: const TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Duty Toggle Button
                  IconButton(
                    tooltip: state.isOnDuty ? 'Go Off Duty' : 'Go On Duty',
                    icon: Icon(
                      state.isOnDuty ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      color: state.isOnDuty ? AviationColors.gold500 : AviationColors.textMuted,
                      size: 26,
                    ),
                    onPressed: () {
                      context.read<DutyBloc>().add(ToggleDutyStatus());
                    },
                  ),

                  // SOS Button
                  IconButton(
                    tooltip: 'Emergency Distress Ping',
                    style: IconButton.styleFrom(
                      backgroundColor: AviationColors.statusIncident.withValues(alpha: 0.15),
                      side: const BorderSide(color: AviationColors.statusIncident, width: 1.5),
                    ),
                    icon: const Icon(Icons.emergency, color: AviationColors.statusIncident, size: 22),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => IncidentModal(missionId: activeMissionId),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
