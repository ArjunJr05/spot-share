import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spot_share2/features/auth/services/auth_services.dart';
import 'package:spot_share2/features/auth/services/base_services.dart';
import 'package:spot_share2/features/auth/services/land_owner_services.dart';
import 'package:spot_share2/features/placeHolder/AddParking/presentation/bloc/location_event.dart';
import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';
import 'package:spot_share2/features/placeHolder/AddParking/presentation/bloc/location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LandownerFirestoreService _firestoreService = LandownerFirestoreService();
  final AuthService _authService = AuthService();
  
  LocationBloc() : super(LocationInitial()) {
    on<LoadLocationsEvent>(_onLoadLocations);
    on<AddLocationEvent>(_onAddLocation);
    on<SelectLocationEvent>(_onSelectLocation);
    on<UpdateLocationEvent>(_onUpdateLocation);
    on<GenerateCoordinatesEvent>(_onGenerateCoordinates);
    on<DeleteLocationEvent>(_onDeleteLocation);
    on<AddVehicleEvent>(_onAddVehicle);
    on<RemoveVehicleEvent>(_onRemoveVehicle);
    on<UpdateVehicleCountEvent>(_onUpdateVehicleCount);
    on<LoadLocationStatsEvent>(_onLoadLocationStats);
  }
  
  List<LocationModel> _locations = [];
  LocationModel? _selectedLocation;
  Map<String, dynamic> _locationStats = {};
  
  void _onLoadLocations(LoadLocationsEvent event, Emitter<LocationState> emit) async {
    emit(LocationLoading());
    
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(LocationError('User not authenticated. Please sign in to continue.'));
        return;
      }

      final userType = await _authService.getCurrentUserType();
      if (userType != UserType.landOwner) {
        emit(LocationError('Access denied. Only land owners can manage locations.'));
        return;
      }

      // Check if user has any locations
      final hasLocations = await _firestoreService.hasLandownerLocations(currentUser.uid);
      
      if (!hasLocations) {
        _locations = [];
        emit(LocationLoaded(locations: _locations, isEmpty: true));
        return;
      }

      // Load locations from Firestore
      _locations = await _firestoreService.getLandownerLocations(currentUser.uid);
      
      // Load statistics
      _locationStats = await _firestoreService.getLandownerLocationStats(currentUser.uid);
      
      emit(LocationLoaded(
        locations: _locations,
        isEmpty: false,
        stats: _locationStats,
      ));
      
    } catch (e) {
      print('Error loading locations: $e');
      emit(LocationError('Failed to load locations: ${e.toString()}'));
    }
  }
  
  void _onAddLocation(AddLocationEvent event, Emitter<LocationState> emit) async {
    emit(LocationLoading());
    
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(LocationError('User not authenticated. Please sign in to continue.'));
        return;
      }

      final userType = await _authService.getCurrentUserType();
      if (userType != UserType.landOwner) {
        emit(LocationError('Access denied. Only land owners can add locations.'));
        return;
      }

      // Validate location data
      if (!_validateLocationData(event.location)) {
        emit(LocationError('Invalid location data. Please check all fields.'));
        return;
      }

      // Add timestamps
      final locationWithTimestamps = event.location.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add location to Firestore
      await _firestoreService.addLocationToLandowner(
        landOwnerUid: currentUser.uid,
        location: locationWithTimestamps,
      );
      
      // Reload locations to show updated list
      _locations = await _firestoreService.getLandownerLocations(currentUser.uid);
      _locationStats = await _firestoreService.getLandownerLocationStats(currentUser.uid);
      
      emit(LocationLoaded(
        locations: List.from(_locations),
        isEmpty: false,
        stats: _locationStats,
        message: 'Location "${event.location.name}" added successfully!',
      ));
      
    } catch (e) {
      print('Error adding location: $e');
      emit(LocationError('Failed to add location: ${e.toString()}'));
    }
  }
  
  void _onUpdateLocation(UpdateLocationEvent event, Emitter<LocationState> emit) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(LocationError('User not authenticated'));
        return;
      }

      final userType = await _authService.getCurrentUserType();
      if (userType != UserType.landOwner) {
        emit(LocationError('Access denied. Only land owners can update locations.'));
        return;
      }

      // Add updated timestamp
      final updatedLocation = event.location.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update location in Firestore
      await _firestoreService.updateLandownerLocation(
        landOwnerUid: currentUser.uid,
        location: updatedLocation,
      );

      // Update local list
      final index = _locations.indexWhere((loc) => loc.id == event.location.id);
      if (index != -1) {
        _locations[index] = updatedLocation;
        
        // Reload stats
        _locationStats = await _firestoreService.getLandownerLocationStats(currentUser.uid);
        
        emit(LocationLoaded(
          locations: List.from(_locations),
          isEmpty: false,
          stats: _locationStats,
          message: 'Location updated successfully',
        ));
      } else {
        // Reload from Firestore if not found locally
        _locations = await _firestoreService.getLandownerLocations(currentUser.uid);
        _locationStats = await _firestoreService.getLandownerLocationStats(currentUser.uid);
        emit(LocationLoaded(
          locations: List.from(_locations),
          isEmpty: false,
          stats: _locationStats,
        ));
      }
      
    } catch (e) {
      print('Error updating location: $e');
      emit(LocationError('Failed to update location: ${e.toString()}'));
    }
  }

  void _onDeleteLocation(DeleteLocationEvent event, Emitter<LocationState> emit) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(LocationError('User not authenticated'));
        return;
      }

      final userType = await _authService.getCurrentUserType();
      if (userType != UserType.landOwner) {
        emit(LocationError('Access denied. Only land owners can delete locations.'));
        return;
      }

      // Get location name for success message
      final locationToDelete = _locations.firstWhere(
        (loc) => loc.id == event.locationId,
        orElse: () => LocationModel(
          id: '', name: 'Unknown Location', area: '', address: '', 
          latitude: 0, longitude: 0, capacity: 0, totalSpots: 0, 
          vehicleCount: VehicleCount(),
        ),
      );

      // Delete location from Firestore
      await _firestoreService.deleteLandownerLocation(
        landOwnerUid: currentUser.uid,
        locationId: event.locationId,
      );

      // Remove from local list
      _locations.removeWhere((loc) => loc.id == event.locationId);
      
      // Update stats
      if (_locations.isNotEmpty) {
        _locationStats = await _firestoreService.getLandownerLocationStats(currentUser.uid);
      } else {
        _locationStats = {};
      }
      
      emit(LocationLoaded(
        locations: List.from(_locations),
        isEmpty: _locations.isEmpty,
        stats: _locationStats,
        message: '"${locationToDelete.name}" deleted successfully',
      ));
      
    } catch (e) {
      print('Error deleting location: $e');
      emit(LocationError('Failed to delete location: ${e.toString()}'));
    }
  }
  
  void _onSelectLocation(SelectLocationEvent event, Emitter<LocationState> emit) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(LocationError('User not authenticated'));
        return;
      }

      // Get fresh location data from Firestore
      final freshLocation = await _firestoreService.getLocationById(
        landOwnerUid: currentUser.uid,
        locationId: event.location.id,
      );

      if (freshLocation == null) {
        emit(LocationError('Location not found'));
        return;
      }

      _selectedLocation = freshLocation;
      
      emit(LocationDetailState(
        location: freshLocation,
        vehicleCounts: {
          'Bikes': freshLocation.vehicleCount.bike,
          'Cars': freshLocation.vehicleCount.car,
          'Autos': freshLocation.vehicleCount.auto,
          'Lorries': freshLocation.vehicleCount.lorry,
        },
        totalEarnings: 0.0, // You can enhance this with actual earnings data
        occupancy: freshLocation.occupancyPercentage,
        availableSpots: freshLocation.capacityEmpty,
        totalSpots: freshLocation.totalSpots,
        address: freshLocation.address,
        area: freshLocation.area,
        capacity: freshLocation.capacity,
      ));
      
    } catch (e) {
      print('Error selecting location: $e');
      emit(LocationError('Failed to load location details: ${e.toString()}'));
    }
  }
  
  void _onGenerateCoordinates(GenerateCoordinatesEvent event, Emitter<LocationState> emit) async {
    emit(LocationLoading());
    
    try {
      // Simulate coordinate generation based on address
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Generate coordinates around Mumbai/Airoli area since user is in Maharashtra
      final random = math.Random();
      final latitude = 19.1568 + (random.nextDouble() - 0.5) * 0.05; // Airoli area
      final longitude = 72.9972 + (random.nextDouble() - 0.5) * 0.05;
      
      emit(CoordinatesGenerated(
        latitude: latitude,
        longitude: longitude,
        address: event.address,
      ));
    } catch (e) {
      emit(LocationError('Failed to generate coordinates: ${e.toString()}'));
    }
  }

  void _onAddVehicle(AddVehicleEvent event, Emitter<LocationState> emit) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(LocationError('User not authenticated'));
        return;
      }

      await _firestoreService.addVehicleToParking(
        landOwnerUid: currentUser.uid,
        locationId: event.locationId,
        vehicleType: event.vehicleType,
      );

      // Reload locations to reflect changes
      _locations = await _firestoreService.getLandownerLocations(currentUser.uid);
      _locationStats = await _firestoreService.getLandownerLocationStats(currentUser.uid);
      
      emit(LocationLoaded(
        locations: List.from(_locations),
        isEmpty: false,
        stats: _locationStats,
        message: '${event.vehicleType.toUpperCase()} added to parking',
      ));
      
    } catch (e) {
      print('Error adding vehicle: $e');
      emit(LocationError('Failed to add vehicle: ${e.toString()}'));
    }
  }

  void _onRemoveVehicle(RemoveVehicleEvent event, Emitter<LocationState> emit) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(LocationError('User not authenticated'));
        return;
      }

      await _firestoreService.removeVehicleFromParking(
        landOwnerUid: currentUser.uid,
        locationId: event.locationId,
        vehicleType: event.vehicleType,
      );

      // Reload locations to reflect changes
      _locations = await _firestoreService.getLandownerLocations(currentUser.uid);
      _locationStats = await _firestoreService.getLandownerLocationStats(currentUser.uid);
      
      emit(LocationLoaded(
        locations: List.from(_locations),
        isEmpty: false,
        stats: _locationStats,
        message: '${event.vehicleType.toUpperCase()} removed from parking',
      ));
      
    } catch (e) {
      print('Error removing vehicle: $e');
      emit(LocationError('Failed to remove vehicle: ${e.toString()}'));
    }
  }

  void _onUpdateVehicleCount(UpdateVehicleCountEvent event, Emitter<LocationState> emit) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(LocationError('User not authenticated'));
        return;
      }

      await _firestoreService.updateVehicleCount(
        landOwnerUid: currentUser.uid,
        locationId: event.locationId,
        newVehicleCount: event.vehicleCount,
      );

      // Reload locations to reflect changes
      _locations = await _firestoreService.getLandownerLocations(currentUser.uid);
      _locationStats = await _firestoreService.getLandownerLocationStats(currentUser.uid);
      
      emit(LocationLoaded(
        locations: List.from(_locations),
        isEmpty: false,
        stats: _locationStats,
        message: 'Vehicle count updated successfully',
      ));
      
    } catch (e) {
      print('Error updating vehicle count: $e');
      emit(LocationError('Failed to update vehicle count: ${e.toString()}'));
    }
  }

  void _onLoadLocationStats(LoadLocationStatsEvent event, Emitter<LocationState> emit) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(LocationError('User not authenticated'));
        return;
      }

      _locationStats = await _firestoreService.getLandownerLocationStats(currentUser.uid);
      
      emit(LocationStatsLoaded(stats: _locationStats));
      
    } catch (e) {
      print('Error loading location stats: $e');
      emit(LocationError('Failed to load statistics: ${e.toString()}'));
    }
  }

  // Helper method to validate location data
  bool _validateLocationData(LocationModel location) {
    return location.name.isNotEmpty &&
           location.area.isNotEmpty &&
           location.address.isNotEmpty &&
           location.latitude != 0 &&
           location.longitude != 0 &&
           location.capacity > 0 &&
           location.totalSpots > 0 &&
           location.vehicleCount.total <= location.totalSpots;
  }

  // Get current location statistics
  Map<String, dynamic> get locationStats => Map.from(_locationStats);
  
  // Get locations list
  List<LocationModel> get locations => List.from(_locations);
  
  // Get selected location
  LocationModel? get selectedLocation => _selectedLocation;

  // Helper method to get location by ID
  LocationModel? getLocationById(String locationId) {
    try {
      return _locations.firstWhere((loc) => loc.id == locationId);
    } catch (e) {
      return null;
    }
  }

  // Helper method to check if location exists
  bool hasLocation(String locationId) {
    return _locations.any((loc) => loc.id == locationId);
  }

  // Get locations stream for real-time updates
  Stream<List<LocationModel>>? getLocationsStream() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;
    
    return _firestoreService.getLandownerLocationsStream(currentUser.uid);
  }

  // Get specific location stream
  Stream<LocationModel?>? getLocationStream(String locationId) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;
    
    return _firestoreService.getLocationStream(
      landOwnerUid: currentUser.uid,
      locationId: locationId,
    );
  }

  @override
  Future<void> close() {
    return super.close();
  }
}