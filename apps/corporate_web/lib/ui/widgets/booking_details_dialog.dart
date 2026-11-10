import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/corporate_booking.dart';

class BookingDetailsDialog extends StatelessWidget {
  final CorporateBooking booking;
  final Function(bool isApproved)? onApprovalDecision;

  const BookingDetailsDialog({
    super.key,
    required this.booking,
    this.onApprovalDecision,
  });

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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final statusColor = _getStatusColor(booking.status);

    return Dialog(
      backgroundColor: const Color(0xFF151E32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.shield_outlined, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.refNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Corporate Booking Voucher • ${booking.id}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      booking.status.name.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 20),

              // Detail Grid
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Passenger & Flight Info
                      _buildSectionTitle('PASSENGER & FLIGHT SCHEDULE'),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        'Lead Traveler',
                        '${booking.leadPassenger} (${booking.passengerCount} pax)',
                        'Flight & Airport',
                        '${booking.flightNumber} • ${booking.airportName}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Pickup Schedule',
                        dateFormat.format(booking.scheduledPickup),
                        'Pickup Gate / Terminal',
                        booking.pickupLocation,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Destination',
                        booking.destination,
                        'Security Corridor',
                        booking.airportName.contains('LAE') || booking.airportName.contains('Nadzab')
                            ? 'Markham Highway High-Security Corridor'
                            : 'Poreporena Freeway / Capital District Corridor',
                      ),
                      const SizedBox(height: 20),

                      // Vehicle & Security Escort
                      _buildSectionTitle('VEHICLE & TACTICAL PROTOCOL'),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        'Vehicle Specification',
                        booking.vehicleType,
                        'Escort Protocol',
                        booking.escortLevel,
                      ),
                      const SizedBox(height: 20),

                      // Procurement & Billing
                      _buildSectionTitle('CORPORATE PROCUREMENT & BILLING'),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        'PO Number',
                        booking.poNumber,
                        'Cost Center',
                        booking.costCenter,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Contracted Fare',
                        '${booking.farePgk.toStringAsFixed(2)} PGK (10% GST Included)',
                        'Approval Status',
                        booking.approvedBy != null
                            ? 'Approved by ${booking.approvedBy}'
                            : 'Pending Corporate Travel Authorizer',
                      ),
                      if (booking.notes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionTitle('SPECIAL MISSION INSTRUCTIONS'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            booking.notes,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              // Actions Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Export Voucher PDF'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Voucher ${booking.refNumber} generated & downloaded successfully.'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      if (booking.status == CorporateBookingStatus.pendingApproval &&
                          onApprovalDecision != null) ...[
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onApprovalDecision!(false);
                          },
                          child: const Text('Reject Request'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Approve Transfer'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onApprovalDecision!(true);
                          },
                        ),
                        const SizedBox(width: 12),
                      ],
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.tealAccent,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildInfoRow(String label1, String value1, String label2, String value2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 3),
              Text(
                value1,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 3),
              Text(
                value2,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

