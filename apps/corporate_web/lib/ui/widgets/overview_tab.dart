import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../blocs/corporate_state.dart';
import '../../models/corporate_booking.dart';
import 'kpi_metric_tile.dart';
import 'booking_details_dialog.dart';

class OverviewTab extends StatelessWidget {
  final CorporateState state;
  final Function(CorporateBooking) onSelectBooking;
  final Function(String bookingId, bool isApproved) onApprovalDecision;
  final VoidCallback onNavigateToNewBooking;

  const OverviewTab({
    super.key,
    required this.state,
    required this.onSelectBooking,
    required this.onApprovalDecision,
    required this.onNavigateToNewBooking,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');
    final usedRatio = (state.billedThisMonthPgk / state.creditLimitPgk).clamp(0.0, 1.0);
    final availableCredit = state.creditLimitPgk - state.billedThisMonthPgk;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome & Quick Action Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'EXECUTIVE TRAVEL & CONVOY DESK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user, color: Colors.tealAccent, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'CONTRACT ACTIVE • TIER 1',
                              style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.companyName} • Authorized Procurement & Flight Logistics Portal',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Book Corporate Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: onNavigateToNewBooking,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Corporate Credit Line Progress Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF152238), Color(0xFF101826)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.amberAccent, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'CORPORATE CREDIT LINE & PO BUDGET UTILIZATION',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    Text(
                      '${(usedRatio * 100).toStringAsFixed(1)}% Used',
                      style: TextStyle(
                        color: usedRatio > 0.8 ? Colors.orangeAccent : Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: usedRatio,
                    minHeight: 10,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usedRatio > 0.8 ? Colors.orangeAccent : Colors.tealAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Billed MTD: ${currencyFormat.format(state.billedThisMonthPgk)} PGK',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      'Available Credit: ${currencyFormat.format(availableCredit)} PGK',
                      style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Credit Cap: ${currencyFormat.format(state.creditLimitPgk)} PGK',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // KPI Metric Tiles Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Row(
                children: [
                  Expanded(
                    child: KpiMetricTile(
                      title: 'Active Missions',
                      value: '${state.activeTransfersCount}',
                      subtitle: 'Transfers en route or scheduled today',
                      icon: Icons.directions_car_filled_outlined,
                      accentColor: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KpiMetricTile(
                      title: 'Pending Approvals',
                      value: '${state.pendingApprovalsCount}',
                      subtitle: state.pendingApprovalsCount > 0 ? 'Action required by Travel Manager' : 'All requests cleared',
                      icon: Icons.approval_outlined,
                      accentColor: state.pendingApprovalsCount > 0 ? Colors.orangeAccent : Colors.tealAccent,
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiMetricTile(
                        title: 'Executive Travelers',
                        value: '${state.passengers.length}',
                        subtitle: 'Authorized corporate personnel',
                        icon: Icons.badge_outlined,
                        accentColor: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiMetricTile(
                        title: 'Billed This Month',
                        value: '${currencyFormat.format(state.billedThisMonthPgk)} PGK',
                        subtitle: 'Inclusive of 10% PNG GST',
                        icon: Icons.receipt_long_outlined,
                        accentColor: Colors.amberAccent,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Duty-of-care corridor advisory
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2638),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: Colors.blueAccent, size: 22),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DUTY-OF-CARE & SECURITY PROTOCOL ACTIVE (MOROBE / CAPITAL PROVINCES)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'All Nadzab Airport (AYNZ) to Lae City transfers maintain continuous GPS satellite tracking and RPNGC armed escort across the Markham Highway corridor.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Active Corporate Bookings Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE & UPCOMING CORPORATE TRANSFERS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Showing ${state.bookings.length} registered transfers',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bookings Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF151E32),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF1C2742)),
                columns: const [
                  DataColumn(label: Text('REF NUMBER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('LEAD TRAVELER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('FLIGHT / AIRPORT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('PICKUP & DESTINATION', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('ESCORT LEVEL', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('PO NUMBER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('FARE (PGK)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('STATUS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('ACTION', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: state.bookings.map((booking) {
                  final statusColor = _getStatusColor(booking.status);
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          booking.refNumber,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 6),
                            Text(booking.leadPassenger, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(booking.flightNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(booking.airportName, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          '${booking.pickupLocation} ➔ ${booking.destination}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            booking.escortLevel,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(booking.poNumber, style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontFamily: 'monospace')),
                      ),
                      DataCell(
                        Text(
                          '${booking.farePgk.toStringAsFixed(0)} PGK',
                          style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            booking.status.name.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.blueAccent, size: 18),
                              tooltip: 'View Transfer Details',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => BookingDetailsDialog(
                                    booking: booking,
                                    onApprovalDecision: (approved) => onApprovalDecision(booking.id, approved),
                                  ),
                                );
                              },
                            ),
                            if (booking.status == CorporateBookingStatus.pendingApproval)
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Colors.tealAccent, size: 18),
                                tooltip: 'Quick Approve',
                                onPressed: () => onApprovalDecision(booking.id, true),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CorporateBookingStatus status) {
    switch (status) {
      case CorporateBookingStatus.pendingApproval:
        return Colors.orangeAccent;
      case CorporateBookingStatus.approved:
        return Colors.blueAccent;
      case CorporateBookingStatus.dispatched:
        return Colors.cyanAccent;
      case CorporateBookingStatus.inTransit:
        return Colors.purpleAccent;
      case CorporateBookingStatus.completed:
        return Colors.tealAccent;
      case CorporateBookingStatus.cancelled:
        return Colors.redAccent;
    }
  }
}

