import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spot_share2/features/home/presentation/bloc/home_event.dart';
import 'package:spot_share2/features/home/presentation/bloc/home_state.dart';
import 'package:permission_handler/permission_handler.dart';

class ClientHomeBloc extends Bloc<HomeEvent, HomeState> {
  ClientHomeBloc() : super(HomeInitial()) {
    on<LoadInitialDataEvent>(_onLoadInitialData);
    on<CycleVehicleEvent>(_onCycleVehicle);
    on<RequestPermissionEvent>(_onRequestPermission);
  }

  void _onLoadInitialData(
      LoadInitialDataEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final availableVehicles = VehicleType.values;
      final status = await Permission.camera.status;

      emit(HomeLoaded(
        currentVehicleIndex: 0,
        availableVehicles: availableVehicles,
        isPermissionGranted: status.isGranted,
      ));
    } catch (e) {
      emit(HomeError('Failed to load initial data'));
    }
  }

  void _onCycleVehicle(
      CycleVehicleEvent event, Emitter<HomeState> emit) {
    final currentState = state;
    if (currentState is HomeLoaded) {
      int newIndex = currentState.currentVehicleIndex;
      if (event.isNext) {
        newIndex = (newIndex + 1) % currentState.availableVehicles.length;
      } else {
        newIndex = (newIndex - 1 + currentState.availableVehicles.length) %
            currentState.availableVehicles.length;
      }
      emit(currentState.copyWith(currentVehicleIndex: newIndex));
    }
  }

  void _onRequestPermission(
      RequestPermissionEvent event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      var status = await Permission.camera.request();
      emit(currentState.copyWith(isPermissionGranted: status.isGranted));
    }
  }
}