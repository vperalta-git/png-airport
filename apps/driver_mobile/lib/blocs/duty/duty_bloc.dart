import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/driver_firestore_service.dart';
import 'duty_event.dart';
import 'duty_state.dart';

class DutyBloc extends Bloc<DutyEvent, DutyState> {
  final DriverFirestoreService? firestoreService;

  DutyBloc({this.firestoreService}) : super(DutyState(shiftStartTime: DateTime.now())) {
    on<ToggleDutyStatus>((event, emit) {
      final newStatus = !state.isOnDuty;
      firestoreService?.setDutyStatus(isOnDuty: newStatus, callsign: state.callsign);
      emit(state.copyWith(isOnDuty: newStatus));
    });
    on<VehicleAssigned>((event, emit) {
      emit(state.copyWith(assignedVehicle: event.vehicleName));
    });
  }
}
