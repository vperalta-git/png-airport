import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../blocs/analytics/analytics_bloc.dart';
import '../../blocs/analytics/analytics_event.dart';
import '../../blocs/analytics/analytics_state.dart';
import '../../blocs/approvals/approvals_bloc.dart';
import '../../blocs/approvals/approvals_event.dart';
import '../../blocs/approvals/approvals_state.dart';
import '../../blocs/incidents/incident_bloc.dart';
import '../../blocs/incidents/incident_event.dart';
import '../../blocs/incidents/incident_state.dart';
import '../../blocs/cloud_sync/cloud_sync_bloc.dart';
import '../../blocs/cloud_sync/cloud_sync_event.dart';
import '../../blocs/cloud_sync/cloud_sync_state.dart';
import '../../models/incident_case.dart';
import '../widgets/approval_card.dart';
import '../widgets/incident_review_modal.dart';
import '../widgets/kpi_metric_card.dart';
import '../widgets/cloud_service_tile.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<AnalyticsBloc>().add(const LoadSupervisorMetrics());
    context.read<ApprovalsBloc>().add(const LoadEscortApprovals());
    context.read<SupervisorIncidentBloc>().add(const LoadSupervisorIncidents());
    context.read<CloudSyncBloc>().add(const LoadCloudSyncStatus());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ApprovalsBloc, ApprovalsState>(
          listenWhen: (prev, curr) =>
              curr.notificationMessage != null &&
              curr.notificationMessage != prev.notificationMessage,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.notificationMessage!),
                backgroundColor: AviationColors.goldTrim,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        BlocListener<SupervisorIncidentBloc, SupervisorIncidentState>(
          listenWhen: (prev, curr) =>
              curr.notificationMessage != null &&
              curr.notificationMessage != prev.notificationMessage,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.notificationMessage!),
                backgroundColor: AviationColors.statusBlue,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        BlocListener<CloudSyncBloc, CloudSyncState>(
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
      ],
      child: Scaffold(
        backgroundColor: AviationColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AviationColors.cardBackground,
          elevation: 0,
          leading: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Icon(Icons.stars, color: AviationColors.goldTrim, size: 26),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EXECUTIVE SUPERVISOR CONSOLE',
                style: TextStyle(
                  color: AviationColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                'Ground Fleet & Armed Escort Directorate • Papua New Guinea',
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
                final approvalsState = ctx.watch<ApprovalsBloc>().state;
                final pendingCount = approvalsState.pendingQueue.length;
                return pendingCount > 0
                    ? Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.gavel, size: 13, color: Colors.black),
                          label: Text('$pendingCount PENDING',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AviationColors.goldTrim,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () {
                            setState(() => _selectedTabIndex = 1);
                          },
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedTabIndex,
          children: [
            _buildAnalyticsTab(),
            _buildApprovalsTab(),
            _buildIncidentsTab(),
            _buildCloudSyncTab(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: AviationColors.cardBackground,
          selectedItemColor: AviationColors.primaryNavy,
          unselectedItemColor: AviationColors.textSecondary,
          currentIndex: _selectedTabIndex,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          onTap: (idx) => setState(() => _selectedTabIndex = idx),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'KPIs & Revenue',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.security),
              label: 'Approvals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check),
              label: 'Incidents',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sync_alt),
              label: 'Cloud Platform',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state.status == AnalyticsStatus.loading || state.metrics == null) {
          return const Center(
            child: CircularProgressIndicator(color: AviationColors.goldTrim),
          );
        }

        final m = state.metrics!;

        return RefreshIndicator(
          color: AviationColors.goldTrim,
          backgroundColor: AviationColors.cardBackground,
          onRefresh: () async {
            context.read<AnalyticsBloc>().add(const RefreshMetrics());
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: KpiMetricCard(
                      title: 'TODAY REVENUE',
                      value: 'PGK ${m.dailyRevenuePgk.toStringAsFixed(0)}',
                      subtext: '${m.completedMissionsToday} transfers completed',
                      icon: Icons.payments,
                      accentColor: AviationColors.goldTrim,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiMetricCard(
                      title: 'MTD REVENUE',
                      value: 'PGK ${(m.mtdRevenuePgk / 1000).toStringAsFixed(1)}k',
                      subtext: 'Month-to-date total',
                      icon: Icons.account_balance,
                      accentColor: AviationColors.statusGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KpiMetricCard(
                      title: 'ON-TIME PERFORMANCE',
                      value: '${m.onTimePerformanceRate.toStringAsFixed(1)}%',
                      subtext: 'Target > 95.0%',
                      icon: Icons.timer,
                      accentColor: AviationColors.statusBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiMetricCard(
                      title: 'ARMED FLEET FIELD',
                      value: '${m.armoredVehiclesInField} / ${m.totalFleet}',
                      subtext: '${m.activeVehicles} active units deployed',
                      icon: Icons.shield,
                      accentColor: AviationColors.statusOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'REGIONAL HUBS PERFORMANCE BREAKDOWN',
                style: TextStyle(
                  color: AviationColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              ...m.regionalMetrics.map((reg) => _buildRegionalRow(reg)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegionalRow(dynamic reg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AviationColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AviationColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AviationColors.goldTrim, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reg.hubName,
                  style: const TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Active Missions: ${reg.activeMissions}  |  On-Time: ${reg.onTimeRate.toStringAsFixed(1)}%',
                  style: const TextStyle(color: AviationColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            'PGK ${reg.revenuePgk.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AviationColors.goldTrim,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsTab() {
    return BlocBuilder<ApprovalsBloc, ApprovalsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, color: AviationColors.goldTrim, size: 18),
                const SizedBox(width: 8),
                Text(
                  'HIGH-RISK ESCORT AUTHORIZATION QUEUE (${state.pendingQueue.length})',
                  style: const TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (state.pendingQueue.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No pending high-risk requests awaiting supervisor sign-off.',
                      style: TextStyle(color: AviationColors.textSecondary)),
                ),
              )
            else
              ...state.pendingQueue.map(
                (req) => ApprovalCard(
                  request: req,
                  onApprove: (notes) {
                    context.read<ApprovalsBloc>().add(
                          ApproveEscortRequest(approvalId: req.id, supervisorNotes: notes),
                        );
                  },
                  onReject: (reason) {
                    context.read<ApprovalsBloc>().add(
                          RejectEscortRequest(approvalId: req.id, rejectionReason: reason),
                        );
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'HISTORICAL SUPERVISOR DECISIONS',
              style: TextStyle(
                color: AviationColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            ...state.historyQueue.map(
              (req) => ApprovalCard(
                request: req,
                onApprove: (_) {},
                onReject: (_) {},
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIncidentsTab() {
    return BlocBuilder<SupervisorIncidentBloc, SupervisorIncidentState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check, color: AviationColors.goldTrim, size: 18),
                const SizedBox(width: 8),
                Text(
                  'INCIDENT COMPLIANCE & LEGAL REVIEW (${state.cases.length})',
                  style: const TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...state.cases.map((c) => _buildIncidentCard(c)),
          ],
        );
      },
    );
  }

  Widget _buildIncidentCard(IncidentCase c) {
    final isClosed = c.status == IncidentStatus.closed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AviationColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isClosed ? AviationColors.surfaceBorder : AviationColors.alertRed,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                c.id,
                style: const TextStyle(
                  color: AviationColors.goldTrim,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.incidentType,
                  style: const TextStyle(
                    color: AviationColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isClosed ? AviationColors.statusGreen : AviationColors.alertRed)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c.status.name.toUpperCase(),
                  style: TextStyle(
                    color: isClosed ? AviationColors.statusGreen : AviationColors.alertRed,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Location: ${c.location} • Unit: ${c.unitCallsign} (${c.driverName})',
            style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            'Report: "${c.initialSummary}"',
            style: const TextStyle(color: AviationColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
          if (c.policeReportNumber != null) ...[
            const SizedBox(height: 4),
            Text(
              'RPNGC Police Ref: ${c.policeReportNumber}',
              style: const TextStyle(color: AviationColors.goldTrim, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
          const Divider(height: 16, color: AviationColors.surfaceBorder),
          Row(
            children: [
              Text(
                DateFormat('dd MMM • HH:mm').format(c.occurrenceTime),
                style: const TextStyle(color: AviationColors.textSecondary, fontSize: 10),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_note, size: 14),
                label: Text(isClosed ? 'View Audit Case' : 'Review & Sign Off',
                    style: const TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClosed ? AviationColors.surfaceBorder : AviationColors.goldTrim,
                  foregroundColor: isClosed ? AviationColors.textPrimary : Colors.black,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => IncidentReviewModal(
                      incidentCase: c,
                      onUpdateInvestigation: (police, findings, corrective) {
                        context.read<SupervisorIncidentBloc>().add(
                              UpdateIncidentInvestigation(
                                caseId: c.id,
                                policeReportNumber: police,
                                supervisorFindings: findings,
                                correctiveAction: corrective,
                              ),
                            );
                      },
                      onCloseCase: () {
                        context.read<SupervisorIncidentBloc>().add(CloseIncidentCaseEvent(c.id));
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

  Widget _buildCloudSyncTab() {
    return BlocBuilder<CloudSyncBloc, CloudSyncState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AviationColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AviationColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns, color: AviationColors.goldTrim, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'GOOGLE CLOUD RUN & FIRESTORE PLATFORM',
                        style: TextStyle(
                          color: AviationColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AviationColors.statusGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          state.status.name.toUpperCase(),
                          style: const TextStyle(
                            color: AviationColors.statusGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Host: ${state.cloudRunEndpoint}  |  Latency: ${state.latencyMs}ms',
                    style: const TextStyle(
                      color: AviationColors.textSecondary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('Verify Full Cloud Health Sweep'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AviationColors.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        context.read<CloudSyncBloc>().add(const TriggerFullCloudHealthSweep());
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'CLOUD PLATFORM CORE SERVICES',
              style: TextStyle(
                color: AviationColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ...state.services.map(
              (service) => CloudServiceTile(
                model: service,
                onSync: () {
                  context.read<CloudSyncBloc>().add(TriggerManualSyncService(service.serviceName));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
