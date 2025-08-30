import 'package:spot_share2/placeHolder/AddParking/domain/location_model.dart';

abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final List<LocationModel> locations;
  final LocationModel? selectedLocation;
  
  LocationLoaded({required this.locations, this.selectedLocation});
}

class LocationError extends LocationState {
  final String message;
  LocationError(this.message);
}

class LocationDetailState extends LocationState {
  final LocationModel location;
  final Map<String, int> vehicleCounts;
  final double totalEarnings;
  final double occupancy;
  final int availableSpots;
  
  LocationDetailState({
    required this.location,
    required this.vehicleCounts,
    required this.totalEarnings,
    required this.occupancy,
    required this.availableSpots,
  });
}

class CoordinatesGenerated extends LocationState {
  final double latitude;
  final double longitude;
  
  CoordinatesGenerated({required this.latitude, required this.longitude});
}