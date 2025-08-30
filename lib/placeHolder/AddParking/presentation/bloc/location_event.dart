import 'package:spot_share2/placeHolder/AddParking/domain/location_model.dart';

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

class GenerateCoordinatesEvent extends LocationEvent {
  final String address;
  GenerateCoordinatesEvent(this.address);
}