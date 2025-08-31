import 'package:spot_share2/features/users/home/presentation/bloc/home_event.dart';
import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';

abstract class ClientHomeState {}

class HomeInitial extends ClientHomeState {}

class HomeLoading extends ClientHomeState {}

class HomeLoaded extends ClientHomeState {
  final int currentVehicleIndex;
  final List<VehicleType> availableVehicles;
  final bool isPermissionGranted;
  final List<LocationModel> parkingLocations;
  final Map<String, dynamic> overallStats;
  final LocationModel? selectedLocation;

  VehicleType get selectedVehicleType => availableVehicles[currentVehicleIndex];
  String get modelPath => selectedVehicleType.modelPath;

  // Helper getters for easy access to stats
  int get totalLocations => overallStats['totalLocations'] ?? 0;
  int get totalSpots => overallStats['totalSpots'] ?? 0;
  int get totalCapacityFilled => overallStats['totalCapacityFilled'] ?? 0;
  int get totalCapacityEmpty => overallStats['totalCapacityEmpty'] ?? 0;
  double get overallOccupancyPercentage => (overallStats['overallOccupancyPercentage'] ?? 0.0).toDouble();
  double get totalEarnings => (overallStats['totalEarnings'] ?? 0.0).toDouble();
  
  // Get vehicle count for selected vehicle type at selected location
  int get selectedVehicleCount {
    if (selectedLocation == null) return 0;
    
    switch (selectedVehicleType.displayName.toLowerCase()) {
      case 'car':
        return selectedLocation!.vehicleCount.car;
      case 'bike':
        return selectedLocation!.vehicleCount.bike;
      case 'truck':
        return selectedLocation!.vehicleCount.lorry;
      case 'scooter':
        return selectedLocation!.vehicleCount.auto;
      default:
        return 0;
    }
  }

  HomeLoaded({
    required this.currentVehicleIndex,
    required this.availableVehicles,
    required this.isPermissionGranted,
    this.parkingLocations = const [],
    this.overallStats = const {},
    this.selectedLocation,
  });

  HomeLoaded copyWith({
    int? currentVehicleIndex,
    List<VehicleType>? availableVehicles,
    bool? isPermissionGranted,
    List<LocationModel>? parkingLocations,
    Map<String, dynamic>? overallStats,
    LocationModel? selectedLocation,
  }) {
    return HomeLoaded(
      currentVehicleIndex: currentVehicleIndex ?? this.currentVehicleIndex,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      parkingLocations: parkingLocations ?? this.parkingLocations,
      overallStats: overallStats ?? this.overallStats,
      selectedLocation: selectedLocation ?? this.selectedLocation,
    );
  }
}

class HomeError extends ClientHomeState {
  final String message;
  HomeError(this.message);
}