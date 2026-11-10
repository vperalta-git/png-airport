import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'package:png_transfer_client/blocs/my_bookings/my_bookings_bloc.dart';
import 'package:png_transfer_client/blocs/my_bookings/my_bookings_event.dart';
import 'package:png_transfer_client/blocs/my_bookings/my_bookings_state.dart';
import 'package:png_transfer_client/ui/widgets/tactical_app_bar.dart';
import 'package:png_transfer_client/ui/widgets/status_pill.dart';
import 'package:png_transfer_client/ui/widgets/qr_boarding_pass_modal.dart';

class MyTripsScreen extends StatefulWidget {
  final VoidCallback onNewBooking;

  const MyTripsScreen({
    super.key,
    required this.onNewBooking,
  });

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TacticalAppBar(
        title: 'My Transfers & Passes',
        subtitle: 'Active Missions & Clearance Tokens',
        trailing: IconButton(
          icon: const Icon(Icons.add, color: AviationColors.gold500),
          tooltip: 'Book New Transfer',
          onPressed: widget.onNewBooking,
        ),
      ),
      body: BlocBuilder<MyBookingsBloc, MyBookingsState>(
        builder: (context, state) {
          if (state is MyBookingsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AviationColors.gold500),
            );
          }

          if (state is MyBookingsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: AviationColors.statusIncident),
                  const SizedBox(height: 8),
                  Text(state.message, style: const TextStyle(color: AviationColors.textSecondary)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<MyBookingsBloc>().add(const LoadMyBookings(forceRefresh: true)),
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            );
          }

          if (state is MyBookingsLoaded) {
            return Column(
              children: [
                // Top Tab Bar
                Container(
                  color: AviationColors.navy800,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AviationColors.gold500,
                    labelColor: AviationColors.gold500,
                    unselectedLabelColor: AviationColors.textMuted,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    tabs: [
                      Tab(text: 'ACTIVE MISSIONS (${state.activeBookings.length})'),
                      Tab(text: 'COMPLETED HISTORY (${state.pastBookings.length})'),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList(context, state.activeBookings, isActiveTab: true),
                      _buildBookingsList(context, state.pastBookings, isActiveTab: false),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context, List<Booking> list, {required bool isActiveTab}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActiveTab ? Icons.airport_shuttle : Icons.history,
                size: 48,
                color: AviationColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                isActiveTab ? 'No Active Transfers In Progress' : 'No Completed Transfer History',
                style: const TextStyle(color: AviationColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Book a new ground movement to Nadzab or Port Moresby commercial airports.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AviationColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (isActiveTab)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('BOOK NEW TRANSFER'),
                  onPressed: widget.onNewBooking,
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AviationColors.gold500,
      backgroundColor: AviationColors.cardDark,
      onRefresh: () async {
        context.read<MyBookingsBloc>().add(const LoadMyBookings(forceRefresh: true));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final booking = list[index];
          return _buildBookingCard(context, booking, isActive: isActiveTab);
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, {required bool isActive}) {
    final passenger = booking.passengers.isNotEmpty
        ? booking.passengers.first
        : const Passenger(firstName: 'Lead', lastName: 'Passenger');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Ref & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.name,
                      style: const TextStyle(
                        color: AviationColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.airportName,
                      style: const TextStyle(color: AviationColors.gold400, fontSize: 11),
                    ),
                  ],
                ),
                StatusPill(status: booking.state),
              ],
            ),
            const Divider(color: AviationColors.cardBorder, height: 22),

            // Flight Delay Advisory Alert Banner
            if (booking.isDelayed) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AviationColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AviationColors.gold500),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: AviationColors.gold500, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FLIGHT DELAY DETECTED (+${booking.flightDelayMinutes}m)',
                            style: const TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Recommended pickup adjusted to ${booking.recommendedPickupDatetime ?? booking.pickupDatetime}. Control Room and driver notified.',
                            style: const TextStyle(color: AviationColors.textPrimary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Active SOS Incident Alert Banner
            if (booking.hasActiveSos) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AviationColors.statusIncident.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AviationColors.statusIncident),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: AviationColors.statusIncident, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INCIDENT RESPONSE IN PROGRESS',
                            style: TextStyle(color: AviationColors.statusIncident, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Control Room & armed response unit tracking this convoy on live radar.',
                            style: TextStyle(color: AviationColors.textPrimary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Pickup & Destination
            Row(
              children: [
                const Icon(Icons.radio_button_checked, size: 16, color: AviationColors.gold500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.pickupLocation,
                    style: const TextStyle(color: AviationColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 7),
              child: SizedBox(
                height: 12,
                child: VerticalDivider(color: AviationColors.cardBorder, thickness: 2),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AviationColors.statusEnRoute),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.destination,
                    style: const TextStyle(color: AviationColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Live Trip Tracking Progress Bar (for active trips)
            if (booking.isInProgress) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AviationColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AviationColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LIVE MISSION TRACKING',
                          style: TextStyle(color: AviationColors.gold400, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          booking.state.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(color: AviationColors.textSuccess, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: booking.state == 'dispatched'
                            ? 0.2
                            : booking.state == 'driver_en_route'
                                ? 0.35
                                : booking.state == 'at_airport'
                                    ? 0.55
                                    : booking.state == 'passenger_verified'
                                        ? 0.75
                                        : 0.9,
                        backgroundColor: AviationColors.surfaceDark,
                        color: AviationColors.gold500,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Metadata row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AviationColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIME / ETA', style: TextStyle(color: AviationColors.textMuted, fontSize: 10)),
                      Text(booking.pickupDatetime, style: const TextStyle(color: AviationColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (booking.flightNumber != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('FLIGHT', style: TextStyle(color: AviationColors.textMuted, fontSize: 10)),
                        Text(booking.flightNumber!, style: const TextStyle(color: AviationColors.gold400, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('TOTAL FARE', style: TextStyle(color: AviationColors.textMuted, fontSize: 10)),
                      Text('PGK ${booking.totalFare.toStringAsFixed(2)}', style: const TextStyle(color: AviationColors.textSuccess, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('PRESENT QR / OTP PASS', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AviationColors.gold500,
                      foregroundColor: AviationColors.navy900,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => QrBoardingPassModal(
                          booking: booking,
                          passenger: passenger,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Emergency Hotline',
                  style: IconButton.styleFrom(
                    backgroundColor: AviationColors.statusIncident.withValues(alpha: 0.15),
                    side: const BorderSide(color: AviationColors.statusIncident),
                  ),
                  icon: const Icon(Icons.phone_in_talk, color: AviationColors.statusIncident, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AviationColors.statusIncident,
                        content: Text('Connecting to 24/7 PNG Operations & Armed Response Desk (+675 7123 4567)...'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
