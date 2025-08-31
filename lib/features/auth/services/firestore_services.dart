import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spot_share2/features/auth/services/base_services.dart';
import 'package:spot_share2/features/auth/services/driver_services.dart';
import 'package:spot_share2/features/auth/services/land_owner_services.dart';
import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final BaseFirestoreService _baseService = BaseFirestoreService();
  final LandownerFirestoreService _landownerService = LandownerFirestoreService();
  final DriverFirestoreService _driverService = DriverFirestoreService();

  // Base service methods
  Future<void> ensureFirebaseInitialized() => _baseService.ensureFirebaseInitialized();
  
  Future<Map<String, dynamic>?> getUserByEmail(String email) => 
      _baseService.getUserByEmail(email);

  Future<void> saveRegistrationAnalytics({
    required String uid,
    required String email,
    required UserType userType,
    required bool isGoogleSignIn,
  }) => _baseService.saveRegistrationAnalytics(
        uid: uid,
        email: email,
        userType: userType,
        isGoogleSignIn: isGoogleSignIn,
      );

  Future<void> saveLoginAnalytics({
    required String uid,
    required String email,
    required UserType userType,
    required bool isGoogleSignIn,
  }) => _baseService.saveLoginAnalytics(
        uid: uid,
        email: email,
        userType: userType,
        isGoogleSignIn: isGoogleSignIn,
      );

  Future<QuerySnapshot> getUsersByType(UserType userType) => 
      _baseService.getUsersByType(userType);

  Future<void> initializeDefaultData() => _baseService.initializeDefaultData();

  bool isFirebaseInitialized() => _baseService.isFirebaseInitialized();

  Future<bool> testConnection() => _baseService.testConnection();

  Future<DocumentSnapshot?> getUserData(String uid) => _baseService.getUserData(uid);

  Future<UserType?> getUserType(String uid) => _baseService.getUserType(uid);

  Future<void> updateLastLogin(String uid, UserType userType) => 
      _baseService.updateLastLogin(uid, userType);

  Future<void> updateUserData(String uid, UserType userType, Map<String, dynamic> updates) => 
      _baseService.updateUserData(uid, userType, updates);

  Future<void> deleteUserData(String uid, UserType userType) => 
      _baseService.deleteUserData(uid, userType);

  // Combined save user data method
  Future<void> saveUserData({
    required String uid,
    required String email,
    required String name,
    required UserType userType,
    String? phoneNumber,
    String? photoUrl,
    bool isGoogleSignIn = false,
    bool emailVerified = false,
  }) async {
    if (userType == UserType.landOwner) {
      return _landownerService.saveLandownerData(
        uid: uid,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
        isGoogleSignIn: isGoogleSignIn,
        emailVerified: emailVerified,
      );
    } else {
      return _driverService.saveDriverData(
        uid: uid,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
        isGoogleSignIn: isGoogleSignIn,
        emailVerified: emailVerified,
      );
    }
  }

  // Landowner service methods
  Future<QuerySnapshot> getAllLandOwners() => _landownerService.getAllLandOwners();

  Future<void> addLocationToLandowner({
    required String landOwnerUid,
    required LocationModel location,
  }) => _landownerService.addLocationToLandowner(
        landOwnerUid: landOwnerUid,
        location: location,
      );

  Future<List<LocationModel>> getLandownerLocations(String landOwnerUid) => 
      _landownerService.getLandownerLocations(landOwnerUid);

  Future<void> updateLandownerLocation({
    required String landOwnerUid,
    required LocationModel location,
  }) => _landownerService.updateLandownerLocation(
        landOwnerUid: landOwnerUid,
        location: location,
      );

  Future<void> updateVehicleCount({
    required String landOwnerUid,
    required String locationId,
    required VehicleCount newVehicleCount,
  }) => _landownerService.updateVehicleCount(
        landOwnerUid: landOwnerUid,
        locationId: locationId,
        newVehicleCount: newVehicleCount,
      );

  Future<void> deleteLandownerLocation({
    required String landOwnerUid,
    required String locationId,
  }) => _landownerService.deleteLandownerLocation(
        landOwnerUid: landOwnerUid,
        locationId: locationId,
      );

  Future<bool> hasLandownerLocations(String landOwnerUid) => 
      _landownerService.hasLandownerLocations(landOwnerUid);

  Future<Map<String, dynamic>> getLandownerLocationStats(String landOwnerUid) => 
      _landownerService.getLandownerLocationStats(landOwnerUid);

  Future<LocationModel?> getLocationById({
    required String landOwnerUid,
    required String locationId,
  }) => _landownerService.getLocationById(
        landOwnerUid: landOwnerUid,
        locationId: locationId,
      );

  Future<void> addVehicleToParking({
    required String landOwnerUid,
    required String locationId,
    required String vehicleType,
  }) => _landownerService.addVehicleToParking(
        landOwnerUid: landOwnerUid,
        locationId: locationId,
        vehicleType: vehicleType,
      );

  Future<void> removeVehicleFromParking({
    required String landOwnerUid,
    required String locationId,
    required String vehicleType,
  }) => _landownerService.removeVehicleFromParking(
        landOwnerUid: landOwnerUid,
        locationId: locationId,
        vehicleType: vehicleType,
      );

  Stream<LocationModel?> getLocationStream({
    required String landOwnerUid,
    required String locationId,
  }) => _landownerService.getLocationStream(
        landOwnerUid: landOwnerUid,
        locationId: locationId,
      );

  Stream<List<LocationModel>> getLandownerLocationsStream(String landOwnerUid) => 
      _landownerService.getLandownerLocationsStream(landOwnerUid);

  // NEW OPTIMIZED METHOD FOR MAP SCREEN
  /// Gets all parking locations within a specified radius from a center point
  /// This is optimized for the map screen to reduce data transfer and improve performance
  Future<List<LocationModel>> getNearbyParkingLocations({
    required double centerLatitude,
    required double centerLongitude,
    double radiusInKm = 5.0,
    bool activeOnly = false,
    bool availableOnly = false,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      // Get all land owners
      final landOwnersSnapshot = await getAllLandOwners();
      List<LocationModel> nearbyLocations = [];

      // Process each landowner's locations
      for (var landOwnerDoc in landOwnersSnapshot.docs) {
        final landOwnerUid = landOwnerDoc.id;
        
        // Get locations for this landowner
        QuerySnapshot locationsSnapshot;
        if (activeOnly) {
          locationsSnapshot = await FirebaseFirestore.instance
              .collection('land_owners')
              .doc(landOwnerUid)
              .collection('landlocations')
              .where('isActive', isEqualTo: true)
              .get();
        } else {
          locationsSnapshot = await FirebaseFirestore.instance
              .collection('land_owners')
              .doc(landOwnerUid)
              .collection('landlocations')
              .get();
        }

        for (var locationDoc in locationsSnapshot.docs) {
          try {
            final locationData = locationDoc.data() as Map<String, dynamic>;
            final location = LocationModel.fromMap(locationData);

            // Calculate distance
            final distance = Geolocator.distanceBetween(
              centerLatitude,
              centerLongitude,
              location.latitude,
              location.longitude,
            ) / 1000; // Convert to km

            // Check if within radius
            if (distance <= radiusInKm) {
              // Check availability filter
              if (availableOnly && location.capacityEmpty <= 0) {
                continue; // Skip locations with no available spots
              }

              // Add landowner info to location for context
              locationData['landOwnerUid'] = landOwnerUid;
              locationData['distance'] = distance;
              
              final enrichedLocation = LocationModel.fromMap(locationData);
              nearbyLocations.add(enrichedLocation);
            }
          } catch (e) {
            print('Error processing location ${locationDoc.id}: $e');
            continue; // Skip this location and continue with others
          }
        }
      }

      // Sort by distance (closest first)
      nearbyLocations.sort((a, b) {
        final aDistance = Geolocator.distanceBetween(
          centerLatitude, centerLongitude, a.latitude, a.longitude,
        );
        final bDistance = Geolocator.distanceBetween(
          centerLatitude, centerLongitude, b.latitude, b.longitude,
        );
        return aDistance.compareTo(bDistance);
      });

      return nearbyLocations;
    } catch (e) {
      print('Error getting nearby parking locations: $e');
      return [];
    }
  }

  /// Stream version for real-time updates of nearby locations
  Stream<List<LocationModel>> getNearbyParkingLocationsStream({
    required double centerLatitude,
    required double centerLongitude,
    double radiusInKm = 5.0,
    bool activeOnly = false,
  }) async* {
    await ensureFirebaseInitialized();
    
    // Get all landowners first
    final landOwnersSnapshot = await getAllLandOwners();
    
    // Create a combined stream from all landowner location streams
    final List<Stream<QuerySnapshot>> locationStreams = [];
    
    for (var landOwnerDoc in landOwnersSnapshot.docs) {
      final landOwnerUid = landOwnerDoc.id;
      
      Query query = FirebaseFirestore.instance
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations');
      
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      locationStreams.add(query.snapshots());
    }

    // For now, we'll use a periodic approach since combining multiple streams is complex
    // You could implement a more sophisticated stream combination if needed
    yield* Stream.periodic(const Duration(seconds: 10), (_) async {
      return await getNearbyParkingLocations(
        centerLatitude: centerLatitude,
        centerLongitude: centerLongitude,
        radiusInKm: radiusInKm,
        activeOnly: activeOnly,
      );
    }).asyncMap((future) => future);
  }

  /// Get nearby locations with additional filtering options
  Future<List<LocationModel>> getFilteredNearbyLocations({
    required double centerLatitude,
    required double centerLongitude,
    double radiusInKm = 5.0,
    String? vehicleType, // Filter by vehicle type availability
    double? maxOccupancyPercentage, // Filter by occupancy
    double? minRating, // Filter by rating if available
    int? limit, // Limit results
  }) async {
    var locations = await getNearbyParkingLocations(
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      radiusInKm: radiusInKm,
      activeOnly: true,
      availableOnly: true,
    );

    // Apply additional filters
    if (vehicleType != null) {
      locations = locations.where((location) {
        switch (vehicleType.toLowerCase()) {
          case 'car':
            return location.vehicleCount.car < (location.totalSpots * 0.8); // Assume cars can use 80% of spots
          case 'bike':
            return location.vehicleCount.bike < (location.totalSpots * 0.5); // Bikes use less space
          case 'auto':
            return location.vehicleCount.auto < (location.totalSpots * 0.3);
          case 'lorry':
            return location.vehicleCount.lorry < (location.totalSpots * 0.2); // Lorries need more space
          default:
            return true;
        }
      }).toList();
    }

    if (maxOccupancyPercentage != null) {
      locations = locations.where((location) => 
          location.occupancyPercentage <= maxOccupancyPercentage).toList();
    }

    // Apply limit if specified
    if (limit != null && locations.length > limit) {
      locations = locations.take(limit).toList();
    }

    return locations;
  }

  // Driver service methods
  Future<QuerySnapshot> getAllDrivers() => _driverService.getAllDrivers();

  Future<void> updateVehicleInfo({
    required String driverUid,
    required Map<String, dynamic> vehicleInfo,
  }) => _driverService.updateVehicleInfo(
        driverUid: driverUid,
        vehicleInfo: vehicleInfo,
      );

  Future<void> updatePreferredVehicleType({
    required String driverUid,
    required String vehicleType,
  }) => _driverService.updatePreferredVehicleType(
        driverUid: driverUid,
        vehicleType: vehicleType,
      );

  Future<void> addPaymentMethod({
    required String driverUid,
    required Map<String, dynamic> paymentMethod,
  }) => _driverService.addPaymentMethod(
        driverUid: driverUid,
        paymentMethod: paymentMethod,
      );

  Future<void> removePaymentMethod({
    required String driverUid,
    required Map<String, dynamic> paymentMethod,
  }) => _driverService.removePaymentMethod(
        driverUid: driverUid,
        paymentMethod: paymentMethod,
      );

  Future<void> updateDocumentVerification({
    required String driverUid,
    required String documentType,
    required bool isVerified,
  }) => _driverService.updateDocumentVerification(
        driverUid: driverUid,
        documentType: documentType,
        isVerified: isVerified,
      );

  Future<void> incrementTotalRides(String driverUid) => 
      _driverService.incrementTotalRides(driverUid);

  Future<void> updateTotalSpent({
    required String driverUid,
    required double amount,
  }) => _driverService.updateTotalSpent(
        driverUid: driverUid,
        amount: amount,
      );

  Future<void> updateDriverRating({
    required String driverUid,
    required double rating,
  }) => _driverService.updateDriverRating(
        driverUid: driverUid,
        rating: rating,
      );

  Future<DocumentSnapshot?> getDriverData(String driverUid) => 
      _driverService.getDriverData(driverUid);

  Future<List<DocumentSnapshot>> getDriversByVehicleType(String vehicleType) => 
      _driverService.getDriversByVehicleType(vehicleType);

  Future<List<DocumentSnapshot>> getTopRatedDrivers({int limit = 10}) => 
      _driverService.getTopRatedDrivers(limit: limit);

  Future<List<DocumentSnapshot>> getVerifiedDrivers() => 
      _driverService.getVerifiedDrivers();

  Future<Map<String, dynamic>> getDriverStats(String driverUid) => 
      _driverService.getDriverStats(driverUid);

  Stream<DocumentSnapshot> getDriverDataStream(String driverUid) => 
      _driverService.getDriverDataStream(driverUid);

  Future<List<DocumentSnapshot>> searchDrivers(String searchQuery) => 
      _driverService.searchDrivers(searchQuery);
}