import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

Future<void> main() => runLocalFoundation('Operator');

// Preserved implementation for Batch B. Not a launch entrypoint.
void legacyMain() {
  runApp(const OperatorWebPortal());
}

class OperatorWebPortal extends StatelessWidget {
  const OperatorWebPortal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PNG Secure Transfer — Partner Operator Portal',
      debugShowCheckedModeBanner: false,
      theme: AviationTheme.lightTheme,
      home: const OperatorDashboardScreen(),
    );
  }
}

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.directions_bus_filled_outlined, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text('PARTNER OPERATOR PORTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(width: 16),
            Text('• Morobe Coaches & Transport Ltd (Lae)', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            backgroundColor: const Color(0xFF1E293B),
            selectedIndex: _selectedTab,
            onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Overview')),
              NavigationRailDestination(icon: Icon(Icons.assignment_outlined), label: Text('Assignments')),
              NavigationRailDestination(icon: Icon(Icons.directions_car_outlined), label: Text('My Fleet')),
              NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: Text('Settlements')),
            ],
          ),
          const VerticalDivider(width: 1, color: Colors.white12),

          // Main View
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FLEET SETTLEMENT & OPERATIONAL SUMMARY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // KPI Cards
                  Row(
                    children: [
                      _buildKpiCard('Total Payout Due (80%)', '4,880 PGK', Colors.greenAccent),
                      const SizedBox(width: 16),
                      _buildKpiCard('Active Partner Vehicles', '6 Vehicles', Colors.cyanAccent),
                      const SizedBox(width: 16),
                      _buildKpiCard('Trips Completed (Month)', '48 Transfers', Colors.amberAccent),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Incoming Transfer Assignments
                  const Text('INCOMING TRANSFER ASSIGNMENTS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.airport_shuttle, color: Colors.cyanAccent, size: 36),
                            title: const Text('Nadzab Airport Inbound Charter (22 Passengers)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Flight PX 104 • Requires: Toyota Coaster Bus (LAE-3342) • Gross Fare: 715 PGK (Net Payout: 572 PGK)', style: TextStyle(color: Colors.white70)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Assignment accepted by Morobe Coaches! Dispatched to roster.')),
                                );
                              },
                              child: const Text('ACCEPT ASSIGNMENT'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Recent Settlement Statements (80/20)
                  const Text('RECENT SETTLEMENT STATEMENTS (80% PARTNER SHARE)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Settlement Ref', style: TextStyle(color: Colors.white70))),
                        DataColumn(label: Text('Booking', style: TextStyle(color: Colors.white70))),
                        DataColumn(label: Text('Gross Fare', style: TextStyle(color: Colors.white70))),
                        DataColumn(label: Text('Platform Fee (20%)', style: TextStyle(color: Colors.white70))),
                        DataColumn(label: Text('Net Partner Payout', style: TextStyle(color: Colors.greenAccent))),
                        DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70))),
                      ],
                      rows: const [
                        DataRow(cells: [
                          DataCell(Text('ST-20261114-01', style: TextStyle(color: Colors.white))),
                          DataCell(Text('PNG-TR-20261114-10291', style: TextStyle(color: Colors.white70))),
                          DataCell(Text('650 PGK', style: TextStyle(color: Colors.white))),
                          DataCell(Text('130 PGK', style: TextStyle(color: Colors.white70))),
                          DataCell(Text('520 PGK', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                          DataCell(Text('DISBURSED', style: TextStyle(color: Colors.green))),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('ST-20261115-02', style: TextStyle(color: Colors.white))),
                          DataCell(Text('PNG-TR-20261115-38192', style: TextStyle(color: Colors.white70))),
                          DataCell(Text('715 PGK', style: TextStyle(color: Colors.white))),
                          DataCell(Text('143 PGK', style: TextStyle(color: Colors.white70))),
                          DataCell(Text('572 PGK', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                          DataCell(Text('PENDING_APPROVAL', style: TextStyle(color: Colors.amber))),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
