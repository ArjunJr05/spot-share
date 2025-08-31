import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spot_share2/features/auth/services/base_services.dart';
import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';

class LandownerFirestoreService extends BaseFirestoreService {
  static final LandownerFirestoreService _instance = LandownerFirestoreService._internal();
  factory LandownerFirestoreService() => _instance;
  LandownerFirestoreService._internal();

  Future<void> saveLandownerData({
    required String uid,
    required String email,
    required String name,
    String? phoneNumber,
    String? photoUrl,
    bool isGoogleSignIn = false,
    bool emailVerified = false,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      final landOwnerData = {
        'uid': uid,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber ?? '',
        'photoUrl': photoUrl ?? '',
        'isGoogleSignIn': isGoogleSignIn,
        'emailVerified': emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'properties': [],
        'totalSpots': 0,
        'totalBookings': 0,
        'totalEarnings': 0.0,
        'rating': 0.0,
        'reviewCount': 0,
        'bankDetails': {},
        'documents': {
          'propertyVerification': false,
          'identityVerification': false,
        },
        'totalLocations': 0,
      };
      
      await firestore.collection('land_owners').doc(uid).set(landOwnerData);
      print('✅ Land owner data saved successfully to Firestore');
    } catch (e) {
      print('❌ Error saving landowner data: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot> getAllLandOwners() async {
    try {
      await ensureFirebaseInitialized();
      return await firestore.collection('land_owners').get();
    } catch (e) {
      print('❌ Error getting all land owners: $e');
      rethrow;
    }
  }

  // Add location to landowner's landlocations subcollection
  Future<void> addLocationToLandowner({
    required String landOwnerUid,
    required LocationModel location,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      // Convert LocationModel to Map for Firestore
      final locationData = {
        'id': location.id,
        'name': location.name,
        'area': location.area,
        'address': location.address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'capacity': location.capacity,
        'totalSpots': location.totalSpots,
        'vehicleCount': location.vehicleCount.toMap(),
        'capacityFilled': location.capacityFilled,
        'capacityEmpty': location.capacityEmpty,
        'occupancyPercentage': location.occupancyPercentage,
        'isActive': location.isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'totalEarnings': 0.0,
        'todayBookings': 0,
        'thisMonthBookings': 0,
      };
      
      // Add location to subcollection
      await firestore
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations')
          .doc(location.id)
          .set(locationData);
      
      // Update landowner's total locations count and spots
      await firestore.collection('land_owners').doc(landOwnerUid).update({
        'totalLocations': FieldValue.increment(1),
        'totalSpots': FieldValue.increment(location.totalSpots),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Location added to landowner successfully');
    } catch (e) {
      print('❌ Error adding location to landowner: $e');
      rethrow;
    }
  }

  // Get all locations for a specific landowner
  Future<List<LocationModel>> getLandownerLocations(String landOwnerUid) async {
    try {
      await ensureFirebaseInitialized();
      
      final querySnapshot = await firestore
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations')
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return LocationModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting landowner locations: $e');
      rethrow;
    }
  }

  // Update location for a landowner
  Future<void> updateLandownerLocation({
    required String landOwnerUid,
    required LocationModel location,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      final updateData = {
        'name': location.name,
        'area': location.area,
        'address': location.address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'capacity': location.capacity,
        'totalSpots': location.totalSpots,
        'vehicleCount': location.vehicleCount.toMap(),
        'capacityFilled': location.capacityFilled,
        'capacityEmpty': location.capacityEmpty,
        'occupancyPercentage': location.occupancyPercentage,
        'isActive': location.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await firestore
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations')
          .doc(location.id)
          .update(updateData);
      
      print('✅ Location updated successfully');
    } catch (e) {
      print('❌ Error updating location: $e');
      rethrow;
    }
  }

  // Update vehicle count for a specific location
  Future<void> updateVehicleCount({
    required String landOwnerUid,
    required String locationId,
    required VehicleCount newVehicleCount,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      final locationRef = firestore
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations')
          .doc(locationId);
      
      // Get current location data to calculate new values
      final locationDoc = await locationRef.get();
      if (!locationDoc.exists) {
        throw Exception('Location not found');
      }
      
      final currentData = locationDoc.data()!;
      final totalSpots = currentData['totalSpots'] ?? 0;
      final capacityFilled = newVehicleCount.total;
      final capacityEmpty = totalSpots - capacityFilled;
      final occupancyPercentage = totalSpots > 0 ? (capacityFilled / totalSpots) * 100 : 0.0;
      
      await locationRef.update({
        'vehicleCount': newVehicleCount.toMap(),
        'capacityFilled': capacityFilled,
        'capacityEmpty': capacityEmpty,
        'occupancyPercentage': occupancyPercentage,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Vehicle count updated successfully');
    } catch (e) {
      print('❌ Error updating vehicle count: $e');
      rethrow;
    }
  }

  // Delete location from landowner
  Future<void> deleteLandownerLocation({
    required String landOwnerUid,
    required String locationId,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      // Get location data before deletion to update totals
      final locationDoc = await firestore
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations')
          .doc(locationId)
          .get();
      
      if (locationDoc.exists) {
        final locationData = locationDoc.data()!;
        final totalSpots = locationData['totalSpots'] ?? 0;
        
        // Delete the location
        await locationDoc.reference.delete();
        
        // Update landowner's total locations and spots count
        await firestore.collection('land_owners').doc(landOwnerUid).update({
          'totalLocations': FieldValue.increment(-1),
          'totalSpots': FieldValue.increment(-totalSpots),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      print('✅ Location deleted successfully');
    } catch (e) {
      print('❌ Error deleting location: $e');
      rethrow;
    }
  }

  // Check if landowner has any locations
  Future<bool> hasLandownerLocations(String landOwnerUid) async {
    try {
      await ensureFirebaseInitialized();
      
      final querySnapshot = await firestore
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations')
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking landowner locations: $e');
      return false;
    }
  }

  // Get location statistics for a landowner
  Future<Map<String, dynamic>> getLandownerLocationStats(String landOwnerUid) async {
    try {
      await ensureFirebaseInitialized();
      
      final querySnapshot = await firestore
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations')
          .get();
      
      int totalLocations = querySnapshot.docs.length;
      int activeLocations = querySnapshot.docs.where((doc) => doc.data()['isActive'] == true).length;
      int inactiveLocations = totalLocations - activeLocations;
      
      double totalEarnings = 0.0;
      int totalSpots = 0;
      int totalCapacityFilled = 0;
      VehicleCount totalVehicleCount = VehicleCount();
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalEarnings += (data['totalEarnings'] ?? 0.0).toDouble();
        totalSpots += (data['totalSpots'] ?? 0) as int;
        totalCapacityFilled += (data['capacityFilled'] ?? 0) as int;
        
        final vehicleCountData = data['vehicleCount'] as Map<String, dynamic>? ?? {};
        final vehicleCount = VehicleCount.fromMap(vehicleCountData);
        totalVehicleCount = totalVehicleCount + vehicleCount;
      }
      
      return {
        'totalLocations': totalLocations,
        'activeLocations': activeLocations,
        'inactiveLocations': inactiveLocations,
        'totalEarnings': totalEarnings,
        'totalSpots': totalSpots,
        'totalCapacityFilled': totalCapacityFilled,
        'totalCapacityEmpty': totalSpots - totalCapacityFilled,
        'overallOccupancyPercentage': totalSpots > 0 ? (totalCapacityFilled / totalSpots) * 100 : 0.0,
        'totalVehicleCount': totalVehicleCount.toMap(),
      };
    } catch (e) {
      print('❌ Error getting location stats: $e');
      return {
        'totalLocations': 0,
        'activeLocations': 0,
        'inactiveLocations': 0,
        'totalEarnings': 0.0,
        'totalSpots': 0,
        'totalCapacityFilled': 0,
        'totalCapacityEmpty': 0,
        'overallOccupancyPercentage': 0.0,
        'totalVehicleCount': VehicleCount().toMap(),
      };
    }
  }

  // Get a specific location by ID
  Future<LocationModel?> getLocationById({
    required String landOwnerUid,
    required String locationId,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      final doc = await firestore
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations')
          .doc(locationId)
          .get();
      
      if (doc.exists) {
        return LocationModel.fromMap(doc.data()!);
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting location by ID: $e');
      rethrow;
    }
  }

  // Add vehicle to parking (increment count)
  Future<void> addVehicleToParking({
    required String landOwnerUid,
    required String locationId,
    required String vehicleType, // 'bike', 'car', 'auto', 'lorry'
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      final locationRef = firestore
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations')
          .doc(locationId);
      
      await firestore.runTransaction((transaction) async {
        final locationDoc = await transaction.get(locationRef);
        
        if (!locationDoc.exists) {
          throw Exception('Location not found');
        }
        
        final data = locationDoc.data()!;
        final vehicleCountData = data['vehicleCount'] as Map<String, dynamic>? ?? {};
        final currentVehicleCount = VehicleCount.fromMap(vehicleCountData);
        final totalSpots = data['totalSpots'] ?? 0;
        
        // Check if adding this vehicle would exceed capacity
        if (currentVehicleCount.total >= totalSpots) {
          throw Exception('Parking is full. Cannot add more vehicles.');
        }
        
        // Increment the specific vehicle type count
        VehicleCount newVehicleCount;
        switch (vehicleType.toLowerCase()) {
          case 'bike':
            newVehicleCount = currentVehicleCount.copyWith(bike: currentVehicleCount.bike + 1);
            break;
          case 'car':
            newVehicleCount = currentVehicleCount.copyWith(car: currentVehicleCount.car + 1);
            break;
          case 'auto':
            newVehicleCount = currentVehicleCount.copyWith(auto: currentVehicleCount.auto + 1);
            break;
          case 'lorry':
            newVehicleCount = currentVehicleCount.copyWith(lorry: currentVehicleCount.lorry + 1);
            break;
          default:
            throw Exception('Invalid vehicle type: $vehicleType');
        }
        
        final capacityFilled = newVehicleCount.total;
        final capacityEmpty = totalSpots - capacityFilled;
        final occupancyPercentage = totalSpots > 0 ? (capacityFilled / totalSpots) * 100 : 0.0;
        
        transaction.update(locationRef, {
          'vehicleCount': newVehicleCount.toMap(),
          'capacityFilled': capacityFilled,
          'capacityEmpty': capacityEmpty,
          'occupancyPercentage': occupancyPercentage,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      print('✅ Vehicle added to parking successfully');
    } catch (e) {
      print('❌ Error adding vehicle to parking: $e');
      rethrow;
    }
  }

  // Remove vehicle from parking (decrement count)
  Future<void> removeVehicleFromParking({
    required String landOwnerUid,
    required String locationId,
    required String vehicleType, // 'bike', 'car', 'auto', 'lorry'
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      final locationRef = firestore
          .collection('land_owners')
          .doc(landOwnerUid)
          .collection('landlocations')
          .doc(locationId);
      
      await firestore.runTransaction((transaction) async {
        final locationDoc = await transaction.get(locationRef);
        
        if (!locationDoc.exists) {
          throw Exception('Location not found');
        }
        
        final data = locationDoc.data()!;
        final vehicleCountData = data['vehicleCount'] as Map<String, dynamic>? ?? {};
        final currentVehicleCount = VehicleCount.fromMap(vehicleCountData);
        final totalSpots = data['totalSpots'] ?? 0;
        
        // Decrement the specific vehicle type count
        VehicleCount newVehicleCount;
        switch (vehicleType.toLowerCase()) {
          case 'bike':
            if (currentVehicleCount.bike <= 0) {
              throw Exception('No bikes to remove');
            }
            newVehicleCount = currentVehicleCount.copyWith(bike: currentVehicleCount.bike - 1);
            break;
          case 'car':
            if (currentVehicleCount.car <= 0) {
              throw Exception('No cars to remove');
            }
            newVehicleCount = currentVehicleCount.copyWith(car: currentVehicleCount.car - 1);
            break;
          case 'auto':
            if (currentVehicleCount.auto <= 0) {
              throw Exception('No autos to remove');
            }
            newVehicleCount = currentVehicleCount.copyWith(auto: currentVehicleCount.auto - 1);
            break;
          case 'lorry':
            if (currentVehicleCount.lorry <= 0) {
              throw Exception('No lorries to remove');
            }
            newVehicleCount = currentVehicleCount.copyWith(lorry: currentVehicleCount.lorry - 1);
            break;
          default:
            throw Exception('Invalid vehicle type: $vehicleType');
        }
        
        final capacityFilled = newVehicleCount.total;
        final capacityEmpty = totalSpots - capacityFilled;
        final occupancyPercentage = totalSpots > 0 ? (capacityFilled / totalSpots) * 100 : 0.0;
        
        transaction.update(locationRef, {
          'vehicleCount': newVehicleCount.toMap(),
          'capacityFilled': capacityFilled,
          'capacityEmpty': capacityEmpty,
          'occupancyPercentage': occupancyPercentage,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      print('✅ Vehicle removed from parking successfully');
    } catch (e) {
      print('❌ Error removing vehicle from parking: $e');
      rethrow;
    }
  }

  // Get real-time location updates stream
  Stream<LocationModel?> getLocationStream({
    required String landOwnerUid,
    required String locationId,
  }) {
    return firestore
        .collection('land_owners')
        .doc(landOwnerUid)
        .collection('landlocations')
        .doc(locationId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return LocationModel.fromMap(doc.data()!);
          }
          return null;
        });
  }

  // Get all locations stream for real-time updates
  Stream<List<LocationModel>> getLandownerLocationsStream(String landOwnerUid) {
    return firestore
        .collection('land_owners')
        .doc(landOwnerUid)
        .collection('landlocations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((querySnapshot) {
          return querySnapshot.docs.map((doc) {
            return LocationModel.fromMap(doc.data());
          }).toList();
        });
  }
}