import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/convoy_unit.dart';
import 'convoy_event.dart';
import 'convoy_state.dart';

class ConvoyBloc extends Bloc<ConvoyEvent, ConvoyState> {
  ConvoyBloc() : super(const ConvoyState()) {
    on<LoadConvoyFleet>(_onLoadConvoyFleet);
    on<UpdateUnitStatus>(_onUpdateUnitStatus);
    on<PingUnitRadio>(_onPingUnitRadio);
    on<FilterConvoyByStatus>(_onFilterConvoyByStatus);
  }

  void _onLoadConvoyFleet(
    LoadConvoyFleet event,
    Emitter<ConvoyState> emit,
  ) {
    emit(state.copyWith(status: ConvoyFleetStatus.loading));

    final sampleFleet = [
      ConvoyUnit(
        id: 'unit_1',
        callsign: 'Alpha-1 (Lead Armored)',
        vehicleName: 'Toyota LandCruiser 200 B6 Armored',
        plateNumber: 'PNG-784-B6',
        driverName: 'Ezekiel Morauta',
        leadSecurityOfficer: 'Sgt. John Kaupa (Armed)',
        hasArmedEscort: true,
        status: ConvoyStatus.inTransit,
        currentZone: 'Poreporena Freeway, Port Moresby',
        destination: 'The Stanley Hotel & Suites, Waigani',
        activeBookingRef: 'BK-POM-2026-0891',
        passengerName: 'Markus Henderson (Chevron VP)',
        currentSpeedKmh: 58.0,
        fuelPercent: 88,
        lastPing: DateTime.now().subtract(const Duration(seconds: 12)),
      ),
      ConvoyUnit(
        id: 'unit_2',
        callsign: 'Bravo-2 (VIP Escort)',
        vehicleName: 'Nissan Patrol Ti 5.6 V8 Armored',
        plateNumber: 'PNG-902-B7',
        driverName: 'Lucas Kua',
        leadSecurityOfficer: 'Cpl. Paul Doma (Armed)',
        hasArmedEscort: true,
        status: ConvoyStatus.stagedAtAirport,
        currentZone: "Jackson's Intl T1 VIP Apron",
        destination: 'Airways Hotel, Jackson\'s Parade',
        activeBookingRef: 'BK-POM-2026-0894',
        passengerName: 'Dr. Sarah Jenkins (ExxonMobil Mining)',
        currentSpeedKmh: 0.0,
        fuelPercent: 95,
        lastPing: DateTime.now().subtract(const Duration(seconds: 4)),
      ),
      ConvoyUnit(
        id: 'unit_3',
        callsign: 'Delta-Armored-3 (Heavy)',
        vehicleName: 'Toyota Hilux 4x4 Double Cab Security Escort',
        plateNumber: 'PNG-331-ESC',
        driverName: 'Simon Temu',
        leadSecurityOfficer: 'Officer David Kila (Armed)',
        hasArmedEscort: true,
        status: ConvoyStatus.atDestination,
        currentZone: 'Koki Point Compound, POM',
        destination: 'Grand Papua Hotel, Mary Street',
        activeBookingRef: 'BK-POM-2026-0888',
        passengerName: 'Hiroshi Tanaka (JICA Director)',
        currentSpeedKmh: 0.0,
        fuelPercent: 72,
        lastPing: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      ConvoyUnit(
        id: 'unit_4',
        callsign: 'Sierra-Lae-1 (Nadzab Shuttle)',
        vehicleName: 'Toyota Prado TXL Armed Escort',
        plateNumber: 'LAE-551-SEC',
        driverName: 'Mathew Gawi',
        leadSecurityOfficer: 'Guard Peter Mondo (Armed)',
        hasArmedEscort: true,
        status: ConvoyStatus.inTransit,
        currentZone: 'Highlands Highway (Miles 14)',
        destination: 'Lae International Hotel, Morobe',
        activeBookingRef: 'BK-LAE-2026-0042',
        passengerName: 'Geoffrey Vance (Newcrest Mining)',
        currentSpeedKmh: 72.0,
        fuelPercent: 64,
        lastPing: DateTime.now().subtract(const Duration(seconds: 25)),
      ),
      ConvoyUnit(
        id: 'unit_5',
        callsign: 'Echo-Reserve (Standby Base)',
        vehicleName: 'Toyota LandCruiser Troopy QRF',
        plateNumber: 'PNG-001-QRF',
        driverName: 'Bartholomew Pora',
        leadSecurityOfficer: 'Commander Alex Nali',
        hasArmedEscort: true,
        status: ConvoyStatus.idleAtBase,
        currentZone: 'Hap Kas HQ Base, 7 Mile POM',
        destination: 'Base Readiness',
        activeBookingRef: null,
        passengerName: null,
        currentSpeedKmh: 0.0,
        fuelPercent: 100,
        lastPing: DateTime.now().subtract(const Duration(seconds: 35)),
      ),
    ];

    emit(state.copyWith(
      status: ConvoyFleetStatus.loaded,
      allUnits: sampleFleet,
    ));
  }

  void _onUpdateUnitStatus(
    UpdateUnitStatus event,
    Emitter<ConvoyState> emit,
  ) {
    final updatedList = state.allUnits.map((unit) {
      if (unit.id == event.unitId) {
        return unit.copyWith(
          status: event.newStatus,
          lastPing: DateTime.now(),
        );
      }
      return unit;
    }).toList();

    emit(state.copyWith(
      allUnits: updatedList,
      message: 'Unit ${event.unitId} updated to ${event.newStatus.name}',
    ));
  }

  void _onPingUnitRadio(
    PingUnitRadio event,
    Emitter<ConvoyState> emit,
  ) {
    final target = state.allUnits.firstWhere(
      (u) => u.id == event.unitId,
      orElse: () => state.allUnits.first,
    );

    emit(state.copyWith(
      lastPingedUnitCallsign: target.callsign,
      message: 'Radio telemetry ping sent to ${target.callsign} on HF Channel 4',
    ));
  }

  void _onFilterConvoyByStatus(
    FilterConvoyByStatus event,
    Emitter<ConvoyState> emit,
  ) {
    if (event.statusFilter == null) {
      emit(state.copyWith(clearFilter: true));
    } else {
      emit(state.copyWith(activeFilter: event.statusFilter));
    }
  }
}
