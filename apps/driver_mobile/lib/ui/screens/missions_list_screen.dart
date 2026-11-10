import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/driver_mission.dart';
import '../../blocs/missions/missions_bloc.dart';
import '../../blocs/missions/missions_event.dart';
import '../../blocs/missions/missions_state.dart';
import '../../blocs/incident/incident_bloc.dart';
import '../../blocs/incident/incident_state.dart';
import '../widgets/tactical_driver_header.dart';
import '../widgets/workflow_progress_bar.dart';
import '../widgets/verify_modal.dart';
import '../widgets/epod_certificate_modal.dart';
import 'mission_detail_screen.dart';
import 'epod_screen.dart';

class MissionsListScreen extends StatelessWidget {
  const MissionsListScreen({super.key});

  String _getNextStageLabel(String currentStage) {
    switch (currentStage) {
      case 'assigned':
        return 'DEPART BASE: EN ROUTE TO AIRPORT';
      case 'driver_en_route':
        return 'ARRIVED & STAGED AT AIRPORT';
      case 'at_airport':
        return 'PASSENGER MET AT GATE';
      case 'passenger_located':
        return 'VERIFY PASSENGER (QR / OTP)';
      case 'passenger_verified':
        return 'PASSENGER & LUGGAGE ONBOARD';
      case 'passenger_onboard':
        return 'DEPART TERMINAL: CONVOY TRANSIT';
      case 'transfer_in_progress':
        return 'ARRIVED AT DESTINATION';
      case 'arrived_destination':
        return 'COLLECT e-POD DIGITAL SIGNATURE';
      case 'completed':
        return 'MISSION COMPLETED (e-POD SEALED)';
      default:
        return 'NEXT STAGE';
    }
  }

  void _handleStageAction(BuildContext context, DriverMission mission) {
    switch (mission.stage) {
      case 'assigned':
        context.read<MissionsBloc>().add(
              AdvanceMissionStage(missionId: mission.id, targetStage: 'driver_en_route'),
            );
        break;
      case 'driver_en_route':
        context.read<MissionsBloc>().add(
              AdvanceMissionStage(missionId: mission.id, targetStage: 'at_airport'),
            );
        break;
      case 'at_airport':
        context.read<MissionsBloc>().add(
              AdvanceMissionStage(missionId: mission.id, targetStage: 'passenger_located'),
            );
        break;
      case 'passenger_located':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => VerifyModal(
            mission: mission,
            onVerified: () {
              context.read<MissionsBloc>().add(
                    AdvanceMissionStage(missionId: mission.id, targetStage: 'passenger_verified'),
                  );
            },
          ),
        );
        break;
      case 'passenger_verified':
        context.read<MissionsBloc>().add(
              AdvanceMissionStage(missionId: mission.id, targetStage: 'passenger_onboard'),
            );
        break;
      case 'passenger_onboard':
        context.read<MissionsBloc>().add(
              AdvanceMissionStage(missionId: mission.id, targetStage: 'transfer_in_progress'),
            );
        break;
      case 'transfer_in_progress':
        context.read<MissionsBloc>().add(
              AdvanceMissionStage(missionId: mission.id, targetStage: 'arrived_destination'),
            );
        break;
      case 'arrived_destination':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EpodScreen(mission: mission)),
        );
        break;
      case 'completed':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EpodCertificateModal(mission: mission),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TacticalDriverHeader(activeMissionId: 'TRF-00108'),
      body: BlocConsumer<MissionsBloc, MissionsState>(
        listener: (context, state) {
          if (state is MissionsLoaded && state.lastActionToast != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AviationColors.gold500,
                content: Text(
                  state.lastActionToast!,
                  style: const TextStyle(color: AviationColors.navy900, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MissionsLoading) {
            return const Center(child: CircularProgressIndicator(color: AviationColors.gold500));
          }

          if (state is MissionsLoaded) {
            if (state.missions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 54, color: AviationColors.gold400),
                      const SizedBox(height: 16),
                      const Text(
                        'NO ACTIVE ASSIGNMENTS',
                        style: TextStyle(
                          color: AviationColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You currently have no dispatched transfers assigned from Control Room.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AviationColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('REFRESH DISPATCH INBOX'),
                        onPressed: () => context.read<MissionsBloc>().add(const LoadDriverMissions()),
                      ),
                    ],
                  ),
                ),
              );
            }

            final activeMission = state.activeMission ?? state.missions.first;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Incident Alert Banner (if SOS or incident triggered)
                BlocBuilder<IncidentBloc, IncidentState>(
                  builder: (context, incidentState) {
                    if (incidentState is IncidentAlertActive) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AviationColors.statusIncident.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AviationColors.statusIncident),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: AviationColors.statusIncident, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    incidentState.summary,
                                    style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('Control Room dispatched alert acknowledgment.', style: TextStyle(color: AviationColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Offline Monotonic Queue Control Bar
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: state.isOffline ? AviationColors.statusEnRoute.withValues(alpha: 0.15) : AviationColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: state.isOffline ? AviationColors.statusEnRoute : AviationColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.isOffline ? Icons.wifi_off : Icons.wifi,
                        color: state.isOffline ? AviationColors.statusEnRoute : AviationColors.textSuccess,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.isOffline ? 'OFFLINE OPERATION (Remote PNG Corridor)' : 'ONLINE SYNCHRONIZED',
                              style: TextStyle(
                                color: state.isOffline ? AviationColors.statusEnRoute : AviationColors.textSuccess,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Queue: ${state.pendingOfflineEventsCount} pending | ${state.syncedEventsCount} synced (Idempotent)',
                              style: const TextStyle(color: AviationColors.textSecondary, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<MissionsBloc>().add(ToggleOfflineMode(!state.isOffline));
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          backgroundColor: AviationColors.surfaceDark,
                        ),
                        child: Text(
                          state.isOffline ? 'GO ONLINE' : 'SIMULATE OFFLINE',
                          style: const TextStyle(color: AviationColors.gold400, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (state.pendingOfflineEventsCount > 0) ...[
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () {
                            context.read<MissionsBloc>().add(const SyncOfflineEvents());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AviationColors.gold500,
                            foregroundColor: AviationColors.navy900,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          child: const Text('SYNC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),

                // Active Mission Spotlight Card
                const Text(
                  'CURRENT OPERATIONAL MISSION',
                  style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                _buildActiveMissionCard(context, activeMission, state),
                const SizedBox(height: 24),

                // Other Assigned Missions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DAILY ROSTER MISSIONS',
                      style: TextStyle(color: AviationColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${state.missions.length} ASSIGNED',
                      style: const TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...state.missions.map((mission) {
                  final isCurrentActive = mission.id == activeMission.id;
                  return _buildRosterCard(context, mission, isSelected: isCurrentActive);
                }),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildActiveMissionCard(BuildContext context, DriverMission mission, MissionsLoaded state) {
    final nextLabel = _getNextStageLabel(mission.stage);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID, Flight & Stage Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AviationColors.surfaceDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AviationColors.cardBorder),
                      ),
                      child: Text(
                        mission.id,
                        style: const TextStyle(color: AviationColors.gold500, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mission.flight,
                      style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AviationColors.getStatusColor(mission.stage).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AviationColors.getStatusColor(mission.stage)),
                  ),
                  child: Text(
                    mission.stage.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: AviationColors.getStatusColor(mission.stage),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AviationColors.cardBorder, height: 22),

            // Passenger Name & Escort Tag
            Text(
              mission.passengerName,
              style: const TextStyle(color: AviationColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AviationColors.statusEnRoute, size: 14),
                const SizedBox(width: 4),
                Text(
                  mission.securityLevel,
                  style: const TextStyle(color: AviationColors.statusEnRoute, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route Points
            Row(
              children: [
                const Icon(Icons.radio_button_checked, size: 14, color: AviationColors.gold500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mission.pickup,
                    style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: SizedBox(
                height: 10,
                child: VerticalDivider(color: AviationColors.cardBorder, thickness: 1.5),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AviationColors.statusCompleted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mission.dropoff,
                    style: const TextStyle(color: AviationColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Staging & No-Show Waiting Protocol Box (if at airport)
            if (mission.stage == 'at_airport') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AviationColors.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AviationColors.goldTrim.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PASSENGER WAITING & CONTACT PROTOCOL',
                          style: TextStyle(color: AviationColors.gold400, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Contacts Logged: ${state.contactAttempts}',
                          style: const TextStyle(color: AviationColors.textSuccess, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.phone, size: 14),
                            label: const Text('LOG CALL / SMS', style: TextStyle(fontSize: 10)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AviationColors.gold400,
                              side: const BorderSide(color: AviationColors.gold400),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () {
                              context.read<MissionsBloc>().add(
                                RecordPassengerContact(
                                  missionId: mission.id,
                                  channel: 'phone',
                                  notes: 'Driver attempted phone call at arrival hall gate',
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.person_off, size: 14),
                            label: const Text('SUBMIT NO-SHOW', style: TextStyle(fontSize: 10)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AviationColors.statusIncident,
                              side: const BorderSide(color: AviationColors.statusIncident),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () {
                              context.read<MissionsBloc>().add(
                                RequestPassengerNoShow(
                                  missionId: mission.id,
                                  reason: 'Passenger unlocated after mandatory 45m waiting window',
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
              const SizedBox(height: 12),
            ],

            // Progression Bar
            WorkflowProgressBar(stage: mission.stage),
            const SizedBox(height: 18),

            // Primary Big Tactile Action CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mission.isCompleted ? AviationColors.surfaceDark : AviationColors.primaryNavy,
                  foregroundColor: mission.isCompleted ? AviationColors.textSecondary : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _handleStageAction(context, mission),
                child: Text(
                  nextLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Mechanical Breakdown Emergency Continuity Button
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.build_circle_outlined, size: 14, color: AviationColors.statusIncident),
                    label: Text(
                      state.isBreakdownReported ? 'BREAKDOWN RECORDED (REPLACEMENT EN ROUTE)' : 'REPORT VEHICLE BREAKDOWN',
                      style: TextStyle(
                        color: state.isBreakdownReported ? AviationColors.textSecondary : AviationColors.statusIncident,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: state.isBreakdownReported ? null : () {
                      context.read<MissionsBloc>().add(
                        ReportMissionBreakdown(
                          missionId: mission.id,
                          description: 'Mechanical engine coolant failure on Markham corridor.',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // View Details link
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.info_outline, size: 14, color: AviationColors.textSecondary),
                label: const Text('OPEN FULL MISSION BRIEFING & CONTACTS', style: TextStyle(color: AviationColors.textSecondary, fontSize: 11)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MissionDetailScreen(
                        mission: mission,
                        onTriggerNextStage: () => _handleStageAction(context, mission),
                        nextActionLabel: nextLabel,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterCard(BuildContext context, DriverMission mission, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        context.read<MissionsBloc>().add(SelectMission(mission));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AviationColors.gold500.withValues(alpha: 0.1) : AviationColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AviationColors.gold500 : AviationColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AviationColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                mission.isCompleted ? Icons.check_circle : Icons.navigation,
                color: mission.isCompleted ? AviationColors.statusCompleted : AviationColors.gold500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mission.id,
                        style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        mission.stage.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: AviationColors.getStatusColor(mission.stage),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mission.passengerName,
                    style: const TextStyle(color: AviationColors.textSecondary, fontSize: 12),
                  ),
                  Text(
                    '${mission.pickup} ➔ ${mission.dropoff}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AviationColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
