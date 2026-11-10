import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'package:png_transfer_client/blocs/airports/airports_bloc.dart';
import 'package:png_transfer_client/blocs/airports/airports_state.dart';
import 'package:png_transfer_client/blocs/booking_wizard/booking_wizard_bloc.dart';
import 'package:png_transfer_client/blocs/booking_wizard/booking_wizard_event.dart';
import 'package:png_transfer_client/blocs/booking_wizard/booking_wizard_state.dart';
import 'package:png_transfer_client/blocs/my_bookings/my_bookings_bloc.dart';
import 'package:png_transfer_client/blocs/my_bookings/my_bookings_event.dart';
import 'package:png_transfer_client/ui/widgets/tactical_app_bar.dart';

class BookingWizardScreen extends StatelessWidget {
  final VoidCallback onBookingSuccess;

  const BookingWizardScreen({
    super.key,
    required this.onBookingSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TacticalAppBar(
        title: 'Transfer Dispatch Wizard',
        subtitle: 'Multi-Airport Ground Movement Engine',
        trailing: IconButton(
          icon: const Icon(Icons.refresh, color: AviationColors.gold500),
          tooltip: 'Reset Form',
          onPressed: () {
            context.read<BookingWizardBloc>().add(ResetBookingWizard());
          },
        ),
      ),
      body: BlocConsumer<BookingWizardBloc, BookingWizardState>(
        listener: (context, state) {
          if (state.createdBooking != null) {
            context.read<MyBookingsBloc>().add(BookingCreatedNotification(state.createdBooking!));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AviationColors.statusCompleted,
                content: Text(
                  'Booking ${state.createdBooking!.name} confirmed! Dispatched to Control Room.',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            );
            onBookingSuccess();
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AviationColors.statusIncident,
                content: Text(state.errorMessage!),
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Stepper Indicator Bar
              _buildStepIndicator(context, state.currentStep),

              // Step Content Area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.currentStep == 0) _buildStep0Route(context, state),
                    if (state.currentStep == 1) _buildStep1Flight(context, state),
                    if (state.currentStep == 2) _buildStep2Vehicle(context, state),
                    if (state.currentStep == 3) _buildStep3Review(context, state),
                  ],
                ),
              ),

              // Bottom Navigation Controls
              _buildBottomControls(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, int currentStep) {
    final steps = ['Route & Airport', 'Flight & ETA', 'Vehicle & Security', 'Quote & Confirm'];

    return Container(
      decoration: const BoxDecoration(
        color: AviationColors.cardBackground,
        border: Border(bottom: BorderSide(color: AviationColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isDone = index < currentStep;
          final isCurrent = index == currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AviationColors.statusCompleted
                              : isCurrent
                                  ? AviationColors.gold500
                                  : AviationColors.surfaceDark,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrent ? Colors.white : AviationColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? AviationColors.gold400 : AviationColors.textMuted,
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 14,
                    height: 2,
                    color: isDone ? AviationColors.statusCompleted : AviationColors.cardBorder,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // STEP 0: Route & Airport
  Widget _buildStep0Route(BuildContext context, BookingWizardState state) {
    return BlocBuilder<AirportsBloc, AirportsState>(
      builder: (context, airportState) {
        final airports = airportState is AirportsLoaded ? airportState.airports : <Airport>[];
        final selectedAirport = state.airport ??
            (airports.isNotEmpty
                ? airports.first
                : const Airport(
                    id: 1,
                    name: "Nadzab Tomodachi Int'l Airport",
                    iataCode: "LAE",
                    icaoCode: "AYNZ",
                    city: "Lae",
                    latitude: -6.5698,
                    longitude: 146.7262,
                    serviceRadiusKm: 60,
                  ));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SELECT COMMERCIAL AIRPORT',
              style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Airport>(
              initialValue: selectedAirport,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.flight_takeoff, color: AviationColors.gold500),
              ),
              dropdownColor: AviationColors.cardDark,
              items: airports.map((a) {
                return DropdownMenuItem<Airport>(
                  value: a,
                  child: Text(
                    '${a.name} (${a.iataCode})',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newAirport) {
                if (newAirport != null) {
                  context.read<BookingWizardBloc>().add(
                        AirportLocationSelected(
                          airport: newAirport,
                          zone: newAirport.zones.isNotEmpty ? newAirport.zones.first : null,
                        ),
                      );
                }
              },
            ),
            const SizedBox(height: 20),

            // Direction Selector
            const Text(
              'TRANSFER DIRECTION',
              style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDirectionSelectorCard(
                    title: 'Airport Inbound',
                    subtitle: 'Airport ➔ Hotel / Base',
                    icon: Icons.flight_land,
                    isSelected: state.transferDirection == 'arrival',
                    onTap: () {
                      context.read<BookingWizardBloc>().add(const TransferDirectionChanged('arrival'));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDirectionSelectorCard(
                    title: 'Airport Outbound',
                    subtitle: 'Hotel / Office ➔ Airport',
                    icon: Icons.flight_takeoff,
                    isSelected: state.transferDirection == 'departure',
                    onTap: () {
                      context.read<BookingWizardBloc>().add(const TransferDirectionChanged('departure'));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pickup & Dropoff Inputs
            TextFormField(
              initialValue: state.pickupLocation,
              decoration: const InputDecoration(
                labelText: 'Pick-up Location / Terminal Bay',
                prefixIcon: Icon(Icons.my_location, color: AviationColors.gold500, size: 20),
              ),
              onChanged: (val) {
                context.read<BookingWizardBloc>().add(
                      LocationsChanged(pickupLocation: val, dropoffLocation: state.dropoffLocation),
                    );
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: state.dropoffLocation,
              decoration: const InputDecoration(
                labelText: 'Drop-off Destination Address',
                prefixIcon: Icon(Icons.location_on, color: AviationColors.gold500, size: 20),
              ),
              onChanged: (val) {
                context.read<BookingWizardBloc>().add(
                      LocationsChanged(pickupLocation: state.pickupLocation, dropoffLocation: val),
                    );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDirectionSelectorCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AviationColors.gold500.withValues(alpha: 0.12) : AviationColors.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AviationColors.gold500 : AviationColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AviationColors.gold500 : AviationColors.textSecondary, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AviationColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AviationColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Flight & Schedule
  Widget _buildStep1Flight(BuildContext context, BookingWizardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FLIGHT TELEMETRY LINK',
          style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: state.flightNumber,
          decoration: const InputDecoration(
            labelText: 'Flight Number (e.g. PX102, CG850)',
            prefixIcon: Icon(Icons.flight, color: AviationColors.gold500, size: 20),
          ),
          onChanged: (val) {
            context.read<BookingWizardBloc>().add(
                  FlightInfoChanged(flightNumber: val, flightTime: state.flightTime, airline: state.flightAirline),
                );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: state.flightAirline,
                decoration: const InputDecoration(
                  labelText: 'Airline Carrier',
                  prefixIcon: Icon(Icons.airlines, color: AviationColors.gold500, size: 20),
                ),
                onChanged: (val) {
                  context.read<BookingWizardBloc>().add(
                        FlightInfoChanged(flightNumber: state.flightNumber, flightTime: state.flightTime, airline: val),
                      );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: state.flightTime,
                decoration: const InputDecoration(
                  labelText: 'Scheduled Time (24h)',
                  prefixIcon: Icon(Icons.access_time, color: AviationColors.gold500, size: 20),
                ),
                onChanged: (val) {
                  context.read<BookingWizardBloc>().add(
                        FlightInfoChanged(flightNumber: state.flightNumber, flightTime: val, airline: state.flightAirline),
                      );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Meet & Greet Toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AviationColors.gold500,
          title: const Text('Terminal Meet & Greet Protocol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: const Text('Escort awaits passenger holding digital signboard at gate exit', style: TextStyle(color: AviationColors.textSecondary, fontSize: 12)),
          value: state.meetGreetRequired,
          onChanged: (val) {
            context.read<BookingWizardBloc>().add(
                  VehicleAndSecuritySelected(
                    vehicleCategory: state.vehicleCategory ?? const VehicleCategory(
                      id: 2,
                      name: "Armored Land Cruiser",
                      code: "ARMORED_LC",
                      passengerCapacity: 4,
                      baggageCapacity: 4,
                      securityRated: true,
                      basePriceMultiplier: 1.75,
                    ),
                    securityRequired: state.securityRequired,
                    meetGreetRequired: val,
                  ),
                );
          },
        ),
      ],
    );
  }

  // STEP 2: Vehicle & Security
  Widget _buildStep2Vehicle(BuildContext context, BookingWizardState state) {
    return BlocBuilder<AirportsBloc, AirportsState>(
      builder: (context, airportState) {
        final categories = airportState is AirportsLoaded ? airportState.vehicleCategories : <VehicleCategory>[];
        final selectedCat = state.vehicleCategory ?? (categories.isNotEmpty ? categories[1] : null);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SELECT VEHICLE POOL',
              style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            // Vehicle Category Cards
            ...categories.map((cat) {
              final isSelected = selectedCat?.id == cat.id;
              return GestureDetector(
                onTap: () {
                  context.read<BookingWizardBloc>().add(
                        VehicleAndSecuritySelected(
                          vehicleCategory: cat,
                          securityRequired: cat.securityRated ? true : state.securityRequired,
                          meetGreetRequired: state.meetGreetRequired,
                        ),
                      );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? AviationColors.gold500.withValues(alpha: 0.12) : AviationColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AviationColors.gold500 : AviationColors.cardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AviationColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          cat.securityRated ? Icons.shield : Icons.directions_car,
                          color: cat.securityRated ? AviationColors.statusEnRoute : AviationColors.gold500,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  cat.name,
                                  style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                if (cat.securityRated) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AviationColors.statusEnRoute.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('ARMORED', style: TextStyle(color: AviationColors.statusEnRoute, fontSize: 9, fontWeight: FontWeight.w800)),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Capacity: ${cat.passengerCapacity} Pax • ${cat.baggageCapacity} Bags',
                              style: const TextStyle(color: AviationColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? AviationColors.gold500 : AviationColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // High-Risk Armed Escort Protocol Switch
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AviationColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AviationColors.statusIncident.withValues(alpha: 0.4)),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AviationColors.gold500,
                title: const Row(
                  children: [
                    Icon(Icons.security, color: AviationColors.statusIncident, size: 20),
                    SizedBox(width: 8),
                    Text('Armed Escort Close Protection', style: TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
                subtitle: const Text(
                  'Recommended for Markham Valley, Highlands Corridor, and VIP night movements (+PGK 350)',
                  style: TextStyle(color: AviationColors.textSecondary, fontSize: 11),
                ),
                value: state.securityRequired,
                onChanged: (val) {
                  context.read<BookingWizardBloc>().add(
                        VehicleAndSecuritySelected(
                          vehicleCategory: selectedCat ?? categories.first,
                          securityRequired: val,
                          meetGreetRequired: state.meetGreetRequired,
                        ),
                      );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // STEP 3: Review, Quotation & Passenger Manifest
  Widget _buildStep3Review(BuildContext context, BookingWizardState state) {
    final quote = state.quote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRIMARY PASSENGER MANIFEST',
          style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: state.passengerFirstName,
                decoration: const InputDecoration(labelText: 'First Name'),
                onChanged: (val) {
                  context.read<BookingWizardBloc>().add(
                        PassengerManifestChanged(
                          firstName: val,
                          lastName: state.passengerLastName,
                          phone: state.passengerPhone,
                          email: state.passengerEmail,
                          specialInstructions: state.specialInstructions,
                        ),
                      );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: state.passengerLastName,
                decoration: const InputDecoration(labelText: 'Last Name'),
                onChanged: (val) {
                  context.read<BookingWizardBloc>().add(
                        PassengerManifestChanged(
                          firstName: state.passengerFirstName,
                          lastName: val,
                          phone: state.passengerPhone,
                          email: state.passengerEmail,
                          specialInstructions: state.specialInstructions,
                        ),
                      );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: state.passengerPhone,
          decoration: const InputDecoration(labelText: 'Mobile Phone (+675)'),
          onChanged: (val) {
            context.read<BookingWizardBloc>().add(
                  PassengerManifestChanged(
                    firstName: state.passengerFirstName,
                    lastName: state.passengerLastName,
                    phone: val,
                    email: state.passengerEmail,
                    specialInstructions: state.specialInstructions,
                  ),
                );
          },
        ),
        const SizedBox(height: 20),

        // Quotation Breakdown Card
        const Text(
          'ITEMIZED QUOTATION BREAKDOWN (PGK)',
          style: TextStyle(color: AviationColors.gold400, fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AviationColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AviationColors.gold500.withValues(alpha: 0.6)),
          ),
          child: state.isQuoting
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: AviationColors.gold500),
                  ),
                )
              : Column(
                  children: [
                    _buildQuoteLine('Base Pickup Charge', 'PGK ${quote?.baseFare.toStringAsFixed(2) ?? '150.00'}'),
                    _buildQuoteLine('Distance Charge (~18 km)', 'PGK ${quote?.distanceCharge.toStringAsFixed(2) ?? '117.00'}'),
                    _buildQuoteLine('Airport Toll / Concession', 'PGK ${quote?.airportFee.toStringAsFixed(2) ?? '20.00'}'),
                    if (state.meetGreetRequired)
                      _buildQuoteLine('Meet & Greet Protocol', 'PGK ${quote?.meetGreetFee.toStringAsFixed(2) ?? '50.00'}'),
                    if (state.securityRequired)
                      _buildQuoteLine('Armed Security Escort Team', 'PGK ${quote?.securityEscortFee.toStringAsFixed(2) ?? '350.00'}'),
                    _buildQuoteLine('Goods & Services Tax (GST 10%)', 'PGK ${quote?.taxAmount.toStringAsFixed(2) ?? '68.70'}'),
                    const Divider(color: AviationColors.cardBorder, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL FARE (PGK)',
                          style: TextStyle(color: AviationColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'PGK ${quote?.total.toStringAsFixed(2) ?? '755.70'}',
                          style: const TextStyle(
                            color: AviationColors.gold500,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildQuoteLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AviationColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, BookingWizardState state) {
    final isLastStep = state.currentStep == 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AviationColors.cardBackground,
        border: Border(top: BorderSide(color: AviationColors.cardBorder)),
      ),
      child: Row(
        children: [
          if (state.currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AviationColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  context.read<BookingWizardBloc>().add(StepChanged(state.currentStep - 1));
                },
                child: const Text('BACK', style: TextStyle(color: AviationColors.textSecondary)),
              ),
            ),
          if (state.currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: state.isSubmitting
                  ? null
                  : () {
                      if (!isLastStep) {
                        context.read<BookingWizardBloc>().add(StepChanged(state.currentStep + 1));
                      } else {
                        context.read<BookingWizardBloc>().add(SubmitBookingRequest());
                      }
                    },
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isLastStep ? 'CONFIRM & DISPATCH TRANSFER' : 'CONTINUE NEXT STEP'),
            ),
          ),
        ],
      ),
    );
  }
}
