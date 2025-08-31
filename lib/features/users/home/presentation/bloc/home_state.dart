import 'package:spot_share2/features/users/home/presentation/bloc/home_event.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final int currentVehicleIndex;
  final List<VehicleType> availableVehicles;
  final bool isPermissionGranted;
  final DriverParkingData parkingData;

  VehicleType get selectedVehicleType => availableVehicles[currentVehicleIndex];
  String get modelPath => selectedVehicleType.modelPath;

  HomeLoaded({
    required this.currentVehicleIndex,
    required this.availableVehicles,
    required this.isPermissionGranted,
    required this.parkingData,
  });

  HomeLoaded copyWith({
    int? currentVehicleIndex,
    List<VehicleType>? availableVehicles,
    bool? isPermissionGranted,
    DriverParkingData? parkingData,
  }) {
    return HomeLoaded(
      currentVehicleIndex: currentVehicleIndex ?? this.currentVehicleIndex,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      parkingData: parkingData ?? this.parkingData,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

class DriverParkingData {
  final bool isCurrentlyParked;
  final String? currentLocation;
  final DateTime? parkedSince;
  final double currentCost;
  final int totalRides;
  final double totalSpent;
  final String driverName;
  final double rating;

  DriverParkingData({
    required this.isCurrentlyParked,
    this.currentLocation,
    this.parkedSince,
    required this.currentCost,
    required this.totalRides,
    required this.totalSpent,
    required this.driverName,
    required this.rating,
  });

  factory DriverParkingData.empty() {
    return DriverParkingData(
      isCurrentlyParked: false,
      currentCost: 0.0,
      totalRides: 0,
      totalSpent: 0.0,
      driverName: 'User',
      rating: 0.0,
    );
  }

  String get displayTime {
    if (!isCurrentlyParked || parkedSince == null) return 'Not Parked';
    
    final duration = DateTime.now().difference(parkedSince!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get displayCost {
    if (!isCurrentlyParked) {
      return '₹ ${totalSpent.toStringAsFixed(0)}';
    }
    return '₹ ${currentCost.toStringAsFixed(0)}';
  }

  String get displayLocation {
    return currentLocation ?? (isCurrentlyParked ? 'Unknown' : 'No Location');
  }
}