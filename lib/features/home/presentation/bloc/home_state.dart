import 'package:spot_share2/features/home/presentation/bloc/home_event.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
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

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}