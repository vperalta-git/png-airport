import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../blocs/airspace/airspace_bloc.dart';
import '../../blocs/airspace/airspace_event.dart';
import '../../blocs/airspace/airspace_state.dart';
import '../../blocs/convoy/convoy_bloc.dart';
import '../../blocs/convoy/convoy_event.dart';
import '../../blocs/convoy/convoy_state.dart';
import '../../blocs/dispatch/dispatch_bloc.dart';
import '../../blocs/dispatch/dispatch_event.dart';
import '../../blocs/dispatch/dispatch_state.dart';
import '../../blocs/emergency/emergency_bloc.dart';
import '../../blocs/emergency/emergency_event.dart';
import '../../blocs/emergency/emergency_state.dart';
import '../../models/convoy_unit.dart';
import '../../models/dispatch_job.dart';
import '../../models/sos_alert.dart';
import '../widgets/airspace_radar_card.dart';
import '../widgets/convoy_unit_card.dart';
import '../widgets/dispatch_assignment_dialog.dart';
import '../widgets/sos_command_dialog.dart';
import '../widgets/tactical_status_ticker.dart';

class ControlRoomDashboardScreen extends StatefulWidget {
  const ControlRoomDashboardScreen({super.key});

  @override
  State<ControlRoomDashboardScreen> createState() =>
      _ControlRoomDashboardScreenState();
}

class _ControlRoomDashboardScreenState
    extends State<ControlRoomDashboardScreen> {
  int _selectedTabIndex = 0;

  final List<Map<String, String>> _airports = [
    {'iata': 'POM', 'name': "Port Moresby (Jackson's)"},
    {'iata': 'LAE', 'name': 'Lae (Nadzab)'},
    {'iata': 'HGU', 'name': 'Mt Hagen (Kagamuga)'},
    {'iata': 'GKA', 'name': 'Goroka'},
    {'iata': 'MAG', 'name': 'Madang'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<AirspaceBloc>().add(const LoadAirspaceData(airportIata: 'POM'));
    context.read<ConvoyBloc>().add(const LoadConvoyFleet());
    context.read<DispatchBloc>().add(const LoadDispatchQueue());
    context.read<EmergencyBloc>().add(const LoadEmergencyAlerts());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ConvoyBloc, ConvoyState>(
          listenWhen: (prev, curr) => curr.message != null && curr.message != prev.message,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AviationColors.goldTrim,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        ),
        BlocListener<DispatchBloc, DispatchState>(
          listenWhen: (prev, curr) =>
              curr.notificationMessage != null &&
              curr.notificationMessage != prev.notificationMessage,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.notificationMessage!),
                backgroundColor: AviationColors.statusGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        BlocListener<EmergencyBloc, EmergencyState>(
          listenWhen: (prev, curr) =>
              curr.activeBroadcastMessage != null &&
              curr.activeBroadcastMessage != prev.activeBroadcastMessage,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.activeBroadcastMessage!),
                backgroundColor: AviationColors.alertRed,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AviationColors.darkBackground,
        appBar: AppBar(
          elevation: 0,
          leading: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Icon(Icons.security, color: AviationColors.goldTrim, size: 26),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PNG AIRPORT GROUND OPS COMMAND',
                style: TextStyle(
                  color: AviationColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                'Tactical Operations Center • Port Moresby HQ',
                style: TextStyle(
                  color: AviationColors.goldTrim.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            Builder(
              builder: (ctx) {
                final emergencyState = ctx.watch<EmergencyBloc>().state;
                final sosCount = emergencyState.alerts
                    .where((a) => a.status != AlertStatus.resolved)
                    .length;
                return sosCount > 0
                    ? Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.crisis_alert, size: 14, color: Colors.white),
                          label: Text('$sosCount ACTIVE SOS', style: const TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AviationColors.alertRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () {
                            setState(() => _selectedTabIndex = 3);
                          },
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Builder(
              builder: (context) {
                final convoyState = context.watch<ConvoyBloc>().state;
                final dispatchState = context.watch<DispatchBloc>().state;
                final emergencyState = context.watch<EmergencyBloc>().state;
                final activeSos = emergencyState.alerts
                    .where((a) => a.status != AlertStatus.resolved)
                    .length;

                return TacticalStatusTicker(
                  activeConvoysCount: convoyState.allUnits.length,
                  pendingDispatchCount: dispatchState.pendingCount,
                  activeSosCount: activeSos,
                  onRefreshAirspace: () {
                    context.read<AirspaceBloc>().add(const RefreshAirspaceStream());
                  },
                );
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildAirspaceTab(),
                  _buildConvoyTab(),
                  _buildDispatchTab(),
                  _buildEmergencyTab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: AviationColors.primaryNavy,
          unselectedItemColor: AviationColors.textSecondary,
          currentIndex: _selectedTabIndex,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          onTap: (idx) => setState(() => _selectedTabIndex = idx),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.flight_takeoff),
              label: 'Airspace Radar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield),
              label: 'Convoy Fleet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Dispatch Desk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.crisis_alert),
              label: 'Emergency Desk',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirspaceTab() {
    return BlocBuilder<AirspaceBloc, AirspaceState>(
      builder: (context, state) {
        return Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: AviationColors.surfaceDark,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _airports.length,
                separatorBuilder: (c, i) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final ap = _airports[idx];
                  final isSelected = ap['iata'] == state.activeAirportIata;
                  return ChoiceChip(
                    label: Text(
                      '${ap['iata']} - ${ap['name']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AviationColors.darkBackground : Colors.white,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AviationColors.goldTrim,
                    backgroundColor: AviationColors.cardBackground,
                    onSelected: (selected) {
                      if (selected) {
                        context
                          .read<AirspaceBloc>()
                          .add(FilterAirportChanged(ap['iata']!));
                      }
                    },
                  );
                },
              ),
            ),
            if (state.weather != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AviationColors.cardBackground,
                child: Row(
                  children: [
                    const Icon(Icons.wb_cloudy, size: 16, color: AviationColors.goldTrim),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'METAR [${state.weather!.category}]: ${state.weather!.condition} | Temp: ${state.weather!.temperature} | Wind: ${state.weather!.wind}',
                        style: const TextStyle(
                          color: AviationColors.textSecondary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: state.status == AirspaceStatus.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AviationColors.goldTrim),
                    )
                  : state.flights.isEmpty
                      ? const Center(
                          child: Text(
                            'No active flights in sector buffer.',
                            style: TextStyle(color: AviationColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.flights.length,
                          itemBuilder: (context, idx) {
                            final flight = state.flights[idx];
                            return AirspaceRadarCard(
                              flight: flight,
                              onAssignEscort: () {
                                setState(() => _selectedTabIndex = 2);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Switched to Dispatch Queue for Flight ${flight.code}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConvoyTab() {
    return BlocBuilder<ConvoyBloc, ConvoyState>(
      builder: (context, state) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AviationColors.surfaceDark,
              child: Row(
                children: [
                  const Text('FILTER: ',
                      style: TextStyle(color: AviationColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  _filterButton('ALL', null, state.activeFilter == null),
                  const SizedBox(width: 6),
                  _filterButton('IN TRANSIT', ConvoyStatus.inTransit, state.activeFilter == ConvoyStatus.inTransit),
                  const SizedBox(width: 6),
                  _filterButton('AT AIRPORT', ConvoyStatus.stagedAtAirport, state.activeFilter == ConvoyStatus.stagedAtAirport),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.filteredUnits.length,
                itemBuilder: (context, idx) {
                  final unit = state.filteredUnits[idx];
                  return ConvoyUnitCard(
                    unit: unit,
                    onPingRadio: () {
                      context.read<ConvoyBloc>().add(PingUnitRadio(unit.id));
                    },
                    onStatusChange: (newStatus) {
                      context
                        .read<ConvoyBloc>()
                        .add(UpdateUnitStatus(unitId: unit.id, newStatus: newStatus));
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterButton(String label, ConvoyStatus? status, bool isSelected) {
    return InkWell(
      onTap: () {
        context.read<ConvoyBloc>().add(FilterConvoyByStatus(status));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AviationColors.goldTrim : AviationColors.cardBackground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AviationColors.darkBackground : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDispatchTab() {
    return BlocBuilder<DispatchBloc, DispatchState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions, color: AviationColors.goldTrim, size: 18),
                const SizedBox(width: 8),
                Text(
                  'UNASSIGNED VIP PICKUPS (${state.pendingJobs.length})',
                  style: const TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (state.pendingJobs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('All pending ground transfers dispatched.',
                      style: TextStyle(color: AviationColors.textSecondary)),
                ),
              )
            else
              ...state.pendingJobs.map((job) => _buildPendingJobCard(job)),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AviationColors.statusGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  'TRANSMITTED TO DRIVER ROSTER (${state.completedDispatches.length})',
                  style: const TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...state.completedDispatches.map((job) => _buildDispatchedJobCard(job)),
          ],
        );
      },
    );
  }

  Widget _buildPendingJobCard(DispatchJob job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AviationColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: job.urgency == DispatchUrgency.highVip
              ? AviationColors.goldTrim
              : AviationColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                job.bookingRef,
                style: const TextStyle(
                  color: AviationColors.goldTrim,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Flight: ${job.flightNumber}',
                style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
              ),
              const Spacer(),
              if (job.urgency == DispatchUrgency.highVip)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AviationColors.goldTrim.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HIGH VIP',
                    style: TextStyle(
                      color: AviationColors.goldTrim,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${job.passengerName} • ${job.passengerOrganization}',
            style: const TextStyle(
              color: AviationColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Route: ${job.pickupZone} ➔ ${job.dropoffZone}',
            style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
          ),
          const Divider(height: 16, color: AviationColors.surfaceBorder),
          Row(
            children: [
              Text(
                'Pickup: ${DateFormat('HH:mm').format(job.scheduledPickup)}',
                style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.send, size: 14),
                label: const Text('Assign & Transmit', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AviationColors.goldTrim,
                  foregroundColor: AviationColors.darkBackground,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => DispatchAssignmentDialog(
                      job: job,
                      onConfirm: (driverId, driverName, vehicleCallsign) {
                        context.read<DispatchBloc>().add(
                              AssignAndDispatchJob(
                                jobId: job.id,
                                driverId: driverId,
                                driverName: driverName,
                                vehicleCallsign: vehicleCallsign,
                              ),
                            );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchedJobCard(DispatchJob job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AviationColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AviationColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AviationColors.statusGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${job.bookingRef} • ${job.passengerName}',
                  style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  'Assigned: ${job.assignedDriverName} (${job.assignedVehicleCallsign})',
                  style: const TextStyle(color: AviationColors.goldTrim, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab() {
    return BlocBuilder<EmergencyBloc, EmergencyState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AviationColors.alertRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AviationColors.alertRed),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AviationColors.alertRed, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INCIDENT COMMAND CRISIS DESK',
                          style: TextStyle(
                            color: AviationColors.alertRed,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Direct hotline linked to RPNGC Ops & PNGDF Air Wing standby.',
                          style: TextStyle(color: AviationColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AviationColors.alertRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () {
                      final testAlert = SosAlert(
                        id: 'sos_sim_${DateTime.now().millisecondsSinceEpoch % 1000}',
                        unitCallsign: 'Alpha-1 (Lead Armored)',
                        driverName: 'Ezekiel Morauta',
                        locationDesc: 'Highlands Hwy landslide bypass, Markham Valley',
                        latitude: '-6.5821',
                        longitude: '146.7901',
                        severity: AlertSeverity.p1AmbushHijack,
                        status: AlertStatus.activeUnacknowledged,
                        message: 'SIMULATED DRILL: Hostile crowd blocking single-lane bridge.',
                        timestamp: DateTime.now(),
                      );
                      context.read<EmergencyBloc>().add(TriggerSimulatedDistress(testAlert));
                    },
                    child: const Text('Simulate SOS Ping', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.alerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text('All units green. No active distress signals.',
                      style: TextStyle(color: AviationColors.textSecondary)),
                ),
              )
            else
              ...state.alerts.map((alert) => _buildAlertCard(alert)),
          ],
        );
      },
    );
  }

  Widget _buildAlertCard(SosAlert alert) {
    final isResolved = alert.status == AlertStatus.resolved;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AviationColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isResolved ? AviationColors.statusGreen : AviationColors.alertRed,
          width: isResolved ? 1.0 : 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isResolved ? Icons.check_circle : Icons.error,
                color: isResolved ? AviationColors.statusGreen : AviationColors.alertRed,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${alert.unitCallsign} • ${alert.driverName}',
                  style: const TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isResolved ? AviationColors.statusGreen : AviationColors.alertRed)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alert.status.name.toUpperCase(),
                  style: TextStyle(
                    color: isResolved ? AviationColors.statusGreen : AviationColors.alertRed,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Location: ${alert.locationDesc}',
            style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
          ),
          Text(
            'GPS Coordinates: ${alert.latitude}, ${alert.longitude}',
            style: const TextStyle(
              color: AviationColors.goldTrim,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AviationColors.surfaceDark,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '"${alert.message}"',
              style: const TextStyle(
                color: AviationColors.textPrimary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (alert.responseNotes != null) ...[
            const SizedBox(height: 6),
            Text(
              'Incident Log: ${alert.responseNotes}',
              style: const TextStyle(
                color: AviationColors.goldTrim,
                fontSize: 11,
              ),
            ),
          ],
          const Divider(height: 16, color: AviationColors.surfaceBorder),
          Row(
            children: [
              Text(
                DateFormat('HH:mm:ss').format(alert.timestamp),
                style: const TextStyle(color: AviationColors.textSecondary, fontSize: 10),
              ),
              const Spacer(),
              if (!isResolved)
                ElevatedButton.icon(
                  icon: const Icon(Icons.shield, size: 14),
                  label: const Text('Incident Command', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AviationColors.alertRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => SosCommandDialog(
                        alert: alert,
                        onAcknowledge: () {
                          context.read<EmergencyBloc>().add(
                                AcknowledgeAlert(
                                  alertId: alert.id,
                                  officerName: 'Operator Chief Gibson',
                                ),
                              );
                        },
                        onDispatchQrf: (qrfUnit, instructions) {
                          context.read<EmergencyBloc>().add(
                                DispatchQrfSupport(
                                  alertId: alert.id,
                                  qrfUnitCallsign: qrfUnit,
                                  instructions: instructions,
                                ),
                              );
                        },
                        onResolve: (report) {
                          context.read<EmergencyBloc>().add(
                                ResolveAlert(
                                  alertId: alert.id,
                                  resolutionReport: report,
                                ),
                              );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
