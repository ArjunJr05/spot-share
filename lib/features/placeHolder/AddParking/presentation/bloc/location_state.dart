import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';

abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final List<LocationModel> locations;
  final bool isEmpty;
  final Map<String, dynamic>? stats;
  final String? message;
  final LocationModel? selectedLocation;
  
  LocationLoaded({
    required this.locations,
    this.isEmpty = false,
    this.stats,
    this.message,
    this.selectedLocation,
  });

  // Helper getters for easy access to stats
  int get totalLocations => stats?['totalLocations'] ?? 0;
  int get activeLocations => stats?['activeLocations'] ?? 0;
  int get inactiveLocations => stats?['inactiveLocations'] ?? 0;
  double get totalEarnings => stats?['totalEarnings'] ?? 0.0;
  int get totalSpots => stats?['totalSpots'] ?? 0;
  int get totalCapacityFilled => stats?['totalCapacityFilled'] ?? 0;
  int get totalCapacityEmpty => stats?['totalCapacityEmpty'] ?? 0;
  double get overallOccupancyPercentage => stats?['overallOccupancyPercentage'] ?? 0.0;
  
  Map<String, dynamic> get totalVehicleCount => 
      stats?['totalVehicleCount'] ?? {
        'bike': 0,
        'car': 0,
        'auto': 0,
        'lorry': 0,
      };
}

class LocationError extends LocationState {
  final String message;
  final String? errorCode;
  final dynamic originalError;
  
  LocationError(
    this.message, {
    this.errorCode,
    this.originalError,
  });
}

class LocationDetailState extends LocationState {
  final LocationModel location;
  final Map<String, int> vehicleCounts;
  final double totalEarnings;
  final double occupancy;
  final int availableSpots;
  final int totalSpots;
  final String address;
  final String area;
  final double capacity;
  
  LocationDetailState({
    required this.location,
    required this.vehicleCounts,
    required this.totalEarnings,
    required this.occupancy,
    required this.availableSpots,
    required this.totalSpots,
    required this.address,
    required this.area,
    required this.capacity,
  });

  // Helper getters
  int get totalVehicles => vehicleCounts.values.fold(0, (sum, count) => sum + count);
  bool get isFull => availableSpots <= 0;
  bool get isNearlyFull => occupancy >= 90;
  String get occupancyStatus {
    if (occupancy >= 95) return 'Full';
    if (occupancy >= 80) return 'Nearly Full';
    if (occupancy >= 50) return 'Moderate';
    if (occupancy >= 20) return 'Low Usage';
    return 'Empty';
  }
}

class CoordinatesGenerated extends LocationState {
  final double latitude;
  final double longitude;
  final String address;
  
  CoordinatesGenerated({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationStatsLoaded extends LocationState {
  final Map<String, dynamic> stats;
  
  LocationStatsLoaded({required this.stats});
  
  // Helper getters for easy access
  int get totalLocations => stats['totalLocations'] ?? 0;
  int get activeLocations => stats['activeLocations'] ?? 0;
  int get inactiveLocations => stats['inactiveLocations'] ?? 0;
  double get totalEarnings => stats['totalEarnings'] ?? 0.0;
  int get totalSpots => stats['totalSpots'] ?? 0;
  int get totalCapacityFilled => stats['totalCapacityFilled'] ?? 0;
  int get totalCapacityEmpty => stats['totalCapacityEmpty'] ?? 0;
  double get overallOccupancyPercentage => stats['overallOccupancyPercentage'] ?? 0.0;
  
  VehicleCount get totalVehicleCount {
    final vehicleData = stats['totalVehicleCount'] as Map<String, dynamic>? ?? {};
    return VehicleCount.fromMap(vehicleData);
  }
}

// State for when a vehicle operation is in progress
class VehicleOperationInProgress extends LocationState {
  final String locationId;
  final String vehicleType;
  final String operation; // 'adding' or 'removing'
  
  VehicleOperationInProgress({
    required this.locationId,
    required this.vehicleType,
    required this.operation,
  });
}

// State for location updates in progress
class LocationUpdateInProgress extends LocationState {
  final String locationId;
  final String updateType; // 'status', 'details', 'vehicles'
  
  LocationUpdateInProgress({
    required this.locationId,
    required this.updateType,
  });
}

// State for when coordinates are being generated
class CoordinatesGenerating extends LocationState {
  final String address;
  
  CoordinatesGenerating(this.address);
}