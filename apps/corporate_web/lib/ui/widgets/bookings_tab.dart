import 'package:flutter/material.dart';
import '../../blocs/corporate_state.dart';
import '../../models/corporate_booking.dart';
import 'booking_details_dialog.dart';

class BookingsTab extends StatefulWidget {
  final CorporateState state;
  final Function(CorporateBooking) onSelectBooking;
  final Function(String bookingId, bool isApproved) onApprovalDecision;
  final VoidCallback onNavigateToNewBooking;

  const BookingsTab({
    super.key,
    required this.state,
    required this.onSelectBooking,
    required this.onApprovalDecision,
    required this.onNavigateToNewBooking,
  });

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  String _searchQuery = '';
  CorporateBookingStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final filteredBookings = widget.state.bookings.where((b) {
      final matchesQuery = _searchQuery.isEmpty ||
          b.refNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.leadPassenger.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.flightNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.poNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.destination.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.airportName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == null || b.status == _selectedStatus;

      return matchesQuery && matchesStatus;
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
                    'CORPORATE TRANSFERS DIRECTORY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search and monitor all corporate transfers, PO allocations, and convoy details.',
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
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Transfer'),
                onPressed: widget.onNavigateToNewBooking,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search and Filters Bar
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by PO Number, Passenger, Flight, Route, or Ref...',
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
              ),
              const SizedBox(width: 14),
              // Status Filter Chips
              _buildFilterChip('All', null),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', CorporateBookingStatus.pendingApproval),
              const SizedBox(width: 8),
              _buildFilterChip('Approved', CorporateBookingStatus.approved),
              const SizedBox(width: 8),
              _buildFilterChip('Dispatched', CorporateBookingStatus.dispatched),
              const SizedBox(width: 8),
              _buildFilterChip('Completed', CorporateBookingStatus.completed),
            ],
          ),
          const SizedBox(height: 20),

          // Results Table
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF151E32),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: filteredBookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_outlined, color: Colors.white.withValues(alpha: 0.3), size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'No corporate transfers match your search criteria.',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFF1C2742)),
                        columns: const [
                          DataColumn(label: Text('REFERENCE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('TRAVELER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('FLIGHT / AIRPORT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('ROUTE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('PO / COST CENTER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('VEHICLE & ESCORT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('FARE (PGK)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('STATUS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('ACTIONS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                        rows: filteredBookings.map((booking) {
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(booking.leadPassenger, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('${booking.passengerCount} passenger(s)', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(booking.flightNumber, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(booking.poNumber, style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontFamily: 'monospace')),
                                    Text(booking.costCenter, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(booking.vehicleType, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
                                    Text(booking.escortLevel, style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.w500)),
                                  ],
                                ),
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
                                      icon: const Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
                                      tooltip: 'View Booking Voucher',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => BookingDetailsDialog(
                                            booking: booking,
                                            onApprovalDecision: (approved) => widget.onApprovalDecision(booking.id, approved),
                                          ),
                                        );
                                      },
                                    ),
                                    if (booking.status == CorporateBookingStatus.pendingApproval) ...[
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.tealAccent, size: 18),
                                        tooltip: 'Approve Request',
                                        onPressed: () => widget.onApprovalDecision(booking.id, true),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                        tooltip: 'Reject Request',
                                        onPressed: () => widget.onApprovalDecision(booking.id, false),
                                      ),
                                    ],
                                  ],
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

  Widget _buildFilterChip(String label, CorporateBookingStatus? status) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blueAccent.withValues(alpha: 0.25),
      backgroundColor: const Color(0xFF151E32),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blueAccent : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? Colors.blueAccent : Colors.white12,
      ),
      onSelected: (_) => setState(() => _selectedStatus = status),
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

