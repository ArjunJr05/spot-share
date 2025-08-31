import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';

abstract class LocationEvent {}

class LoadLocationsEvent extends LocationEvent {}

class AddLocationEvent extends LocationEvent {
  final LocationModel location;
  AddLocationEvent(this.location);
}

class SelectLocationEvent extends LocationEvent {
  final LocationModel location;
  SelectLocationEvent(this.location);
}

class UpdateLocationEvent extends LocationEvent {
  final LocationModel location;
  UpdateLocationEvent(this.location);
}

class DeleteLocationEvent extends LocationEvent {
  final String locationId;
  DeleteLocationEvent(this.locationId);
}

class GenerateCoordinatesEvent extends LocationEvent {
  final String address;
  GenerateCoordinatesEvent(this.address);
}

// New events for vehicle management
class AddVehicleEvent extends LocationEvent {
  final String locationId;
  final String vehicleType; // 'bike', 'car', 'auto', 'lorry'
  
  AddVehicleEvent({
    required this.locationId,
    required this.vehicleType,
  });
}

class RemoveVehicleEvent extends LocationEvent {
  final String locationId;
  final String vehicleType; // 'bike', 'car', 'auto', 'lorry'
  
  RemoveVehicleEvent({
    required this.locationId,
    required this.vehicleType,
  });
}

class UpdateVehicleCountEvent extends LocationEvent {
  final String locationId;
  final VehicleCount vehicleCount;
  
  UpdateVehicleCountEvent({
    required this.locationId,
    required this.vehicleCount,
  });
}

// New event for loading statistics
class LoadLocationStatsEvent extends LocationEvent {}

// Event for refreshing specific location data
class RefreshLocationEvent extends LocationEvent {
  final String locationId;
  RefreshLocationEvent(this.locationId);
}

// Event for toggling location active status
class ToggleLocationStatusEvent extends LocationEvent {
  final String locationId;
  ToggleLocationStatusEvent(this.locationId);
}