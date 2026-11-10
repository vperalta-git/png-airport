import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/corporate_bloc.dart';
import '../../blocs/corporate_event.dart';
import '../../blocs/corporate_state.dart';
import '../../models/corporate_booking.dart';
import '../widgets/overview_tab.dart';
import '../widgets/bookings_tab.dart';
import '../widgets/new_transfer_wizard_tab.dart';
import '../widgets/travelers_tab.dart';
import '../widgets/invoices_tab.dart';
import '../widgets/contracted_rates_tab.dart';
import '../widgets/booking_details_dialog.dart';

class CorporatePortalScreen extends StatefulWidget {
  const CorporatePortalScreen({super.key});

  @override
  State<CorporatePortalScreen> createState() => _CorporatePortalScreenState();
}

class _CorporatePortalScreenState extends State<CorporatePortalScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CorporateBloc, CorporateState>(
      listener: (context, state) {
        if (state.lastNotification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.tealAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.lastNotification!)),
                ],
              ),
              backgroundColor: const Color(0xFF1E2D4A),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.errorMessage!)),
                ],
              ),
              backgroundColor: const Color(0xFF3E1E26),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0F1D),
          appBar: _buildTopAppBar(context, state),
          body: Row(
            children: [
              _buildNavigationRail(state),
              const VerticalDivider(width: 1, color: Colors.white12),
              Expanded(
                child: state.status == CorporateLoadingStatus.loading && state.bookings.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                    : _buildCurrentTab(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context, CorporateState state) {
    return AppBar(
      backgroundColor: const Color(0xFF151E32),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield, color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PNG SECURE ESCORT • CORPORATE CLIENT PORTAL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Nadzab Tomodachi (AYNZ) & Jacksons (POM) Flight Logistics & Armored Convoy Desk',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          // Authenticated Corporate Account Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1524),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.business, color: Colors.tealAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  state.companyName,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Operations Room Hotline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.phone_in_talk, color: Colors.redAccent, size: 14),
                SizedBox(width: 6),
                Text(
                  '24/7 OPS: +675 7000 9999',
                  style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(CorporateState state) {
    return NavigationRail(
      backgroundColor: const Color(0xFF151E32),
      selectedIndex: _selectedTab,
      onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
      unselectedIconTheme: const IconThemeData(color: Colors.white54),
      selectedLabelTextStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white54, fontSize: 11),
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Overview'),
        ),
        NavigationRailDestination(
          icon: Badge(
            isLabelVisible: state.pendingApprovalsCount > 0,
            label: Text('${state.pendingApprovalsCount}'),
            backgroundColor: Colors.orangeAccent,
            child: const Icon(Icons.commute_outlined),
          ),
          selectedIcon: const Icon(Icons.commute),
          label: const Text('Transfers'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: Text('Book Transfer'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: Text('Travelers'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('Invoices'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.local_offer_outlined),
          selectedIcon: Icon(Icons.local_offer),
          label: Text('Tariffs & SLA'),
        ),
      ],
    );
  }

  Widget _buildCurrentTab(BuildContext context, CorporateState state) {
    switch (_selectedTab) {
      case 0:
        return OverviewTab(
          state: state,
          onSelectBooking: (booking) => _openBookingDetails(context, booking),
          onApprovalDecision: (bookingId, isApproved) {
            context.read<CorporateBloc>().add(
                  ApproveCorporateBooking(
                    bookingId: bookingId,
                    isApproved: isApproved,
                    approverName: 'H. Abal (Travel Mgr)',
                  ),
                );
          },
          onNavigateToNewBooking: () => setState(() => _selectedTab = 2),
        );
      case 1:
        return BookingsTab(
          state: state,
          onSelectBooking: (booking) => _openBookingDetails(context, booking),
          onApprovalDecision: (bookingId, isApproved) {
            context.read<CorporateBloc>().add(
                  ApproveCorporateBooking(
                    bookingId: bookingId,
                    isApproved: isApproved,
                    approverName: 'H. Abal (Travel Mgr)',
                  ),
                );
          },
          onNavigateToNewBooking: () => setState(() => _selectedTab = 2),
        );
      case 2:
        return NewTransferWizardTab(
          state: state,
          onCancel: () => setState(() => _selectedTab = 0),
          onSubmitTransfer: ({
            required String leadPassenger,
            required int passengerCount,
            required String flightNumber,
            required String airportName,
            required String pickupLocation,
            required String destination,
            required DateTime scheduledPickup,
            required String vehicleType,
            required String escortLevel,
            required String poNumber,
            required String costCenter,
            required double farePgk,
            required String notes,
          }) {
            context.read<CorporateBloc>().add(
                  CreateCorporateTransfer(
                    leadPassenger: leadPassenger,
                    passengerCount: passengerCount,
                    flightNumber: flightNumber,
                    airportName: airportName,
                    pickupLocation: pickupLocation,
                    destination: destination,
                    scheduledPickup: scheduledPickup,
                    vehicleType: vehicleType,
                    escortLevel: escortLevel,
                    poNumber: poNumber,
                    costCenter: costCenter,
                    farePgk: farePgk,
                    notes: notes,
                  ),
                );
            setState(() => _selectedTab = 1);
          },
        );
      case 3:
        return TravelersTab(
          state: state,
          onAddTraveler: (pax) {
            context.read<CorporateBloc>().add(RegisterNewPassenger(pax));
          },
          onBookForTraveler: (pax) {
            setState(() => _selectedTab = 2);
          },
        );
      case 4:
        return InvoicesTab(state: state);
      case 5:
        return ContractedRatesTab(state: state);
      default:
        return const SizedBox.shrink();
    }
  }

  void _openBookingDetails(BuildContext context, CorporateBooking booking) {
    showDialog(
      context: context,
      builder: (ctx) => BookingDetailsDialog(
        booking: booking,
        onApprovalDecision: (isApproved) {
          context.read<CorporateBloc>().add(
                ApproveCorporateBooking(
                  bookingId: booking.id,
                  isApproved: isApproved,
                  approverName: 'H. Abal (Travel Mgr)',
                ),
              );
        },
      ),
    );
  }
}

