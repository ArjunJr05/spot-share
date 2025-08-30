

import 'package:spot_share2/features/home/presentation/bloc/home_event.dart';

abstract class ClientHomeState {}

class HomeInitial extends ClientHomeState {}

class HomeLoading extends ClientHomeState {}

class HomeLoaded extends ClientHomeState {
  final int currentVehicleIndex;
  final List<VehicleType> availableVehicles;
  final bool isPermissionGranted;

  VehicleType get selectedVehicleType => availableVehicles[currentVehicleIndex];
  String get modelPath => selectedVehicleType.modelPath;

  HomeLoaded({
    required this.currentVehicleIndex,
    required this.availableVehicles,
    required this.isPermissionGranted,
  });

  HomeLoaded copyWith({
    int? currentVehicleIndex,
    List<VehicleType>? availableVehicles,
    bool? isPermissionGranted,
  }) {
    return HomeLoaded(
      currentVehicleIndex: currentVehicleIndex ?? this.currentVehicleIndex,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
    );
  }
}

class HomeError extends ClientHomeState {
  final String message;
  HomeError(this.message);
}