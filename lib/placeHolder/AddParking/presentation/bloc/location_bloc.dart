import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spot_share2/placeHolder/AddParking/domain/location_model.dart';
import 'package:spot_share2/placeHolder/AddParking/presentation/bloc/location_event.dart';
import 'package:spot_share2/placeHolder/AddParking/presentation/bloc/location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(LocationInitial()) {
    on<LoadLocationsEvent>(_onLoadLocations);
    on<AddLocationEvent>(_onAddLocation);
    on<SelectLocationEvent>(_onSelectLocation);
    on<UpdateLocationEvent>(_onUpdateLocation);
    on<GenerateCoordinatesEvent>(_onGenerateCoordinates);
  }
  
  List<LocationModel> _locations = [];
  
  void _onLoadLocations(LoadLocationsEvent event, Emitter<LocationState> emit) async {
    emit(LocationLoading());
    
    try {
      // Simulate loading with sample data
      await Future.delayed(const Duration(milliseconds: 500));
      
      _locations = [
        LocationModel(
          id: '1',
          name: 'Vijay Parking',
          area: 'T Nagar',
          latitude: 13.0439,
          longitude: 80.2340,
          boundaries: _generateSampleBoundaries(13.0439, 80.2340),
          isActive: true,
        ),
        LocationModel(
          id: '2',
          name: 'Raja Parking',
          area: 'Anna Nagar',
          latitude: 13.0850,
          longitude: 80.2101,
          boundaries: _generateSampleBoundaries(13.0850, 80.2101),
          isActive: true,
        ),
        LocationModel(
          id: '3',
          name: 'Siva Parking',
          area: 'Adyar',
          latitude: 13.0067,
          longitude: 80.2206,
          boundaries: _generateSampleBoundaries(13.0067, 80.2206),
          isActive: false,
        ),
      ];
      
      emit(LocationLoaded(locations: _locations));
    } catch (e) {
      emit(LocationError('Failed to load locations'));
    }
  }
  
  void _onAddLocation(AddLocationEvent event, Emitter<LocationState> emit) async {
    emit(LocationLoading());
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));
      
      _locations.add(event.location);
      emit(LocationLoaded(locations: List.from(_locations)));
    } catch (e) {
      emit(LocationError('Failed to add location'));
    }
  }
  
  void _onUpdateLocation(UpdateLocationEvent event, Emitter<LocationState> emit) async {
    try {
      // Find and update the location
      final index = _locations.indexWhere((loc) => loc.id == event.location.id);
      if (index != -1) {
        _locations[index] = event.location;
        emit(LocationLoaded(locations: List.from(_locations)));
      } else {
        emit(LocationError('Location not found'));
      }
    } catch (e) {
      emit(LocationError('Failed to update location'));
    }
  }
  
  void _onSelectLocation(SelectLocationEvent event, Emitter<LocationState> emit) {
    // Generate mock data for location details
    final vehicleCounts = _generateVehicleCounts(event.location);
    final totalEarnings = _calculateEarnings(event.location);
    final occupancy = _calculateOccupancy(vehicleCounts);
    final availableSpots = _calculateAvailableSpots(vehicleCounts);
    
    emit(LocationDetailState(
      location: event.location,
      vehicleCounts: vehicleCounts,
      totalEarnings: totalEarnings,
      occupancy: occupancy,
      availableSpots: availableSpots,
    ));
  }
  
  void _onGenerateCoordinates(GenerateCoordinatesEvent event, Emitter<LocationState> emit) async {
    emit(LocationLoading());
    
    try {
      // Simulate coordinate generation based on address
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Generate random coordinates around Chennai
      final random = math.Random();
      final latitude = 13.0827 + (random.nextDouble() - 0.5) * 0.1;
      final longitude = 80.2707 + (random.nextDouble() - 0.5) * 0.1;
      
      emit(CoordinatesGenerated(latitude: latitude, longitude: longitude));
    } catch (e) {
      emit(LocationError('Failed to generate coordinates'));
    }
  }
  
  List<PolygonPoint> _generateSampleBoundaries(double centerLat, double centerLng) {
    final offset = 0.001; // Small offset for boundaries
    
    return [
      PolygonPoint(latitude: centerLat + offset, longitude: centerLng - offset),
      PolygonPoint(latitude: centerLat + offset, longitude: centerLng + offset),
      PolygonPoint(latitude: centerLat - offset, longitude: centerLng + offset),
      PolygonPoint(latitude: centerLat - offset, longitude: centerLng - offset),
    ];
  }
  
  Map<String, int> _generateVehicleCounts(LocationModel location) {
    final random = math.Random();
    return {
      'Cars': 8 + random.nextInt(15),
      'Bikes': 15 + random.nextInt(20),
      'Trucks': 2 + random.nextInt(5),
      'Buses': 1 + random.nextInt(3),
      'Bicycles': 10 + random.nextInt(15),
      'SUVs': 4 + random.nextInt(8),
    };
  }
  
  double _calculateEarnings(LocationModel location) {
    final random = math.Random();
    return 2000 + random.nextDouble() * 3000;
  }
  
  double _calculateOccupancy(Map<String, int> vehicleCounts) {
    final totalParked = vehicleCounts.values.fold(0, (a, b) => a + b);
    final totalCapacity = 80; // Assume 80 total spots
    return (totalParked / totalCapacity * 100).clamp(0, 100);
  }
  
  int _calculateAvailableSpots(Map<String, int> vehicleCounts) {
    final totalParked = vehicleCounts.values.fold(0, (a, b) => a + b);
    return math.max(0, 80 - totalParked);
  }
}