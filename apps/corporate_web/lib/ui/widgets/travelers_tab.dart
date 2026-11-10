import 'package:flutter/material.dart';
import '../../blocs/corporate_state.dart';
import '../../models/corporate_passenger.dart';
import 'add_traveler_dialog.dart';

class TravelersTab extends StatefulWidget {
  final CorporateState state;
  final Function(CorporatePassenger) onAddTraveler;
  final Function(CorporatePassenger)? onBookForTraveler;

  const TravelersTab({
    super.key,
    required this.state,
    required this.onAddTraveler,
    this.onBookForTraveler,
  });

  @override
  State<TravelersTab> createState() => _TravelersTabState();
}

class _TravelersTabState extends State<TravelersTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredPassengers = widget.state.passengers.where((p) {
      final q = _searchQuery.toLowerCase();
      return _searchQuery.isEmpty ||
          p.fullName.toLowerCase().contains(q) ||
          p.department.toLowerCase().contains(q) ||
          p.title.toLowerCase().contains(q) ||
          p.idNumber.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXECUTIVE TRAVELERS DIRECTORY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage authorized executive personnel, diplomatic delegates, and field engineers.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Register Executive Traveler'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AddTravelerDialog(
                      onTravelerAdded: widget.onAddTraveler,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search travelers by name, department, passport, or title...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
              filled: true,
              fillColor: const Color(0xFF151E32),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Travelers Grid / Table
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF151E32),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: filteredPassengers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, color: Colors.white.withValues(alpha: 0.3), size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'No travelers found matching your criteria.',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFF1C2742)),
                        columns: const [
                          DataColumn(label: Text('TRAVELER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('TITLE & DEPARTMENT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('PASSPORT / ID', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('CONTACT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('EMERGENCY CONTACT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('VIP STATUS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('ACTION', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                        rows: filteredPassengers.map((pax) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: pax.isVip
                                          ? Colors.amberAccent.withValues(alpha: 0.2)
                                          : Colors.blueAccent.withValues(alpha: 0.2),
                                      child: Text(
                                        pax.fullName.isNotEmpty ? pax.fullName[0] : '?',
                                        style: TextStyle(
                                          color: pax.isVip ? Colors.amberAccent : Colors.blueAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      pax.fullName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(pax.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    Text(pax.department, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  pax.idNumber,
                                  style: const TextStyle(color: Colors.amberAccent, fontFamily: 'monospace', fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(pax.phone, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    Text(pax.email, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  pax.emergencyContact,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: pax.isVip
                                        ? Colors.amber.withValues(alpha: 0.15)
                                        : Colors.blueGrey.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: pax.isVip
                                          ? Colors.amber.withValues(alpha: 0.5)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    pax.isVip ? 'VIP PRIORITY' : 'STANDARD',
                                    style: TextStyle(
                                      color: pax.isVip ? Colors.amberAccent : Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                                  icon: const Icon(Icons.arrow_forward, size: 14),
                                  label: const Text('Book Transfer', style: TextStyle(fontSize: 12)),
                                  onPressed: widget.onBookForTraveler != null
                                      ? () => widget.onBookForTraveler!(pax)
                                      : null,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

