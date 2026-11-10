import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'package:png_transfer_client/blocs/flight_radar/flight_radar_bloc.dart';
import 'package:png_transfer_client/blocs/flight_radar/flight_radar_event.dart';
import 'package:png_transfer_client/blocs/flight_radar/flight_radar_state.dart';
import 'package:png_transfer_client/blocs/booking_wizard/booking_wizard_bloc.dart';
import 'package:png_transfer_client/blocs/booking_wizard/booking_wizard_event.dart';
import 'package:png_transfer_client/ui/widgets/tactical_app_bar.dart';
import 'package:png_transfer_client/ui/widgets/status_pill.dart';

class FlightRadarScreen extends StatelessWidget {
  final VoidCallback onNavigateToBook;

  const FlightRadarScreen({
    super.key,
    required this.onNavigateToBook,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TacticalAppBar(
        title: 'Nadzab Airspace Radar',
        subtitle: 'AYNZ / LAE • Live Flight Telemetry',
        trailing: IconButton(
          icon: const Icon(Icons.refresh, color: AviationColors.gold500),
          tooltip: 'Refresh Radar',
          onPressed: () {
            context.read<FlightRadarBloc>().add(const LoadFlightRadar(forceRefresh: true));
          },
        ),
      ),
      body: BlocBuilder<FlightRadarBloc, FlightRadarState>(
        builder: (context, state) {
          if (state is FlightRadarLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AviationColors.gold500),
                  SizedBox(height: 16),
                  Text(
                    'Sweeping Airspace Telemetry...',
                    style: TextStyle(color: AviationColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          if (state is FlightRadarError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: AviationColors.statusIncident),
                    const SizedBox(height: 12),
                    Text(
                      'Radar Telemetry Offline',
                      style: const TextStyle(color: AviationColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AviationColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<FlightRadarBloc>().add(const LoadFlightRadar(forceRefresh: true)),
                      child: const Text('RETRY RADAR SWEEP'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is FlightRadarLoaded) {
            return RefreshIndicator(
              color: AviationColors.gold500,
              backgroundColor: AviationColors.cardDark,
              onRefresh: () async {
                context.read<FlightRadarBloc>().add(const LoadFlightRadar(forceRefresh: true));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // METAR Weather Banner
                  _buildMetarWeatherBanner(state.weather),
                  const SizedBox(height: 16),

                  // Search & Filter controls
                  _buildSearchAndFilters(context, state),
                  const SizedBox(height: 16),

                  // Direction Tabs (Arrivals / Departures)
                  _buildDirectionTabs(context, state),
                  const SizedBox(height: 16),

                  // Flights Count Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${state.filteredFlights.length} TRACKED FLIGHTS',
                        style: const TextStyle(
                          color: AviationColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AviationColors.statusCompleted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'RADAR ACTIVE',
                            style: TextStyle(
                              color: AviationColors.statusCompleted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Flight List
                  if (state.filteredFlights.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AviationColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AviationColors.cardBorder),
                      ),
                      child: const Text(
                        'No flights match the current filter or search criteria.',
                        style: TextStyle(color: AviationColors.textMuted),
                      ),
                    )
                  else
                    ...state.filteredFlights.map((flight) => _buildFlightCard(context, flight)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMetarWeatherBanner(MetarWeather weather) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AviationColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AviationColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AviationColors.gold500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.air, color: AviationColors.gold500, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'METAR: ${weather.temperature}',
                      style: const TextStyle(
                        color: AviationColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AviationColors.statusCompleted.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        weather.category,
                        style: const TextStyle(
                          color: AviationColors.statusCompleted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${weather.condition} • Wind ${weather.wind} • QNH ${weather.qnh}',
                  style: const TextStyle(
                    color: AviationColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, FlightRadarLoaded state) {
    return Column(
      children: [
        // Search Input
        TextField(
          onChanged: (val) {
            context.read<FlightRadarBloc>().add(SearchQueryChanged(val));
          },
          decoration: const InputDecoration(
            hintText: 'Search flight (e.g. PX102, CG852, POM)...',
            prefixIcon: Icon(Icons.search, color: AviationColors.textSecondary, size: 20),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),

        // Carrier Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(context, label: 'All Airlines', selected: state.activeCarrier == 'all', onSelected: () {
                context.read<FlightRadarBloc>().add(const CarrierFilterChanged('all'));
              }),
              const SizedBox(width: 8),
              _buildFilterChip(context, label: 'Air Niugini', selected: state.activeCarrier == 'Air Niugini', onSelected: () {
                context.read<FlightRadarBloc>().add(const CarrierFilterChanged('Air Niugini'));
              }),
              const SizedBox(width: 8),
              _buildFilterChip(context, label: 'PNG Air', selected: state.activeCarrier == 'PNG Air', onSelected: () {
                context.read<FlightRadarBloc>().add(const CarrierFilterChanged('PNG Air'));
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AviationColors.gold500 : AviationColors.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AviationColors.gold500 : AviationColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AviationColors.navy900 : AviationColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionTabs(BuildContext context, FlightRadarLoaded state) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AviationColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AviationColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDirectionTabItem(
              context,
              label: 'ARRIVALS (INBOUND)',
              isActive: state.activeDirection == 'arrival',
              onTap: () {
                context.read<FlightRadarBloc>().add(const FilterDirectionChanged('arrival'));
              },
            ),
          ),
          Expanded(
            child: _buildDirectionTabItem(
              context,
              label: 'DEPARTURES (OUTBOUND)',
              isActive: state.activeDirection == 'departure',
              onTap: () {
                context.read<FlightRadarBloc>().add(const FilterDirectionChanged('departure'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionTabItem(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AviationColors.cardDark : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: AviationColors.gold500.withValues(alpha: 0.5)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AviationColors.gold400 : AviationColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildFlightCard(BuildContext context, FlightRadarFlight flight) {
    final isNiugini = flight.carrier.toLowerCase().contains('niugini');
    final carrierBadgeColor = isNiugini ? const Color(0xFFB91C1C) : const Color(0xFF0369A1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Row: Code, Carrier & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: carrierBadgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: carrierBadgeColor),
                      ),
                      child: Text(
                        flight.carrier,
                        style: TextStyle(
                          color: isNiugini ? const Color(0xFFFCA5A5) : const Color(0xFF7DD3FC),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      flight.code,
                      style: const TextStyle(
                        color: AviationColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                StatusPill(
                  status: flight.isDelayed ? 'delayed' : 'confirmed',
                  customLabel: flight.status,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Route Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight.originCode,
                      style: const TextStyle(
                        color: AviationColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      flight.originCity,
                      style: const TextStyle(color: AviationColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sched: ${flight.scheduledTime}',
                      style: const TextStyle(color: AviationColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.flight_takeoff, color: AviationColors.gold500, size: 22),
                    const SizedBox(height: 2),
                    Container(
                      width: 60,
                      height: 1,
                      color: AviationColors.cardBorder,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      flight.aircraft,
                      style: const TextStyle(color: AviationColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      flight.destCode,
                      style: const TextStyle(
                        color: AviationColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      flight.destCity,
                      style: const TextStyle(color: AviationColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Est: ${flight.estimatedTime}',
                      style: TextStyle(
                        color: flight.isDelayed ? AviationColors.textDanger : AviationColors.gold400,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom Action: Quick Book Transfer Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_road, size: 16, color: AviationColors.gold500),
                label: Text(
                  'BOOK GROUND TRANSFER FOR ${flight.code}',
                  style: const TextStyle(
                    color: AviationColors.gold500,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AviationColors.gold500, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Pre-fill booking wizard with this flight
                  context.read<BookingWizardBloc>().add(
                        FlightInfoChanged(
                          flightNumber: flight.code,
                          flightTime: flight.estimatedTime,
                          airline: flight.carrier,
                        ),
                      );
                  context.read<BookingWizardBloc>().add(
                        TransferDirectionChanged(flight.isArrival ? 'arrival' : 'departure'),
                      );
                  onNavigateToBook();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
