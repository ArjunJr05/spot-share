import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spot_share2/features/auth/services/base_services.dart';

class DriverFirestoreService extends BaseFirestoreService {
  static final DriverFirestoreService _instance = DriverFirestoreService._internal();
  factory DriverFirestoreService() => _instance;
  DriverFirestoreService._internal();

  Future<void> saveDriverData({
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
      
      final driverData = {
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
        'vehicleInfo': {
          'vehicleType': '',
          'vehicleNumber': '',
          'vehicleModel': '',
          'vehicleColor': '',
        },
        'totalRides': 0,
        'totalSpent': 0.0,
        'preferredVehicleType': '',
        'rating': 0.0,
        'reviewCount': 0,
        'paymentMethods': [],
        'documents': {
          'licenseVerification': false,
          'vehicleRegistration': false,
        },
      };
      
      await firestore.collection('drivers').doc(uid).set(driverData);
      print('✅ Driver data saved successfully to Firestore');
    } catch (e) {
      print('❌ Error saving driver data: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot> getAllDrivers() async {
    try {
      await ensureFirebaseInitialized();
      return await firestore.collection('drivers').get();
    } catch (e) {
      print('❌ Error getting all drivers: $e');
      rethrow;
    }
  }

  // Update driver's vehicle information
  Future<void> updateVehicleInfo({
    required String driverUid,
    required Map<String, dynamic> vehicleInfo,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      await firestore.collection('drivers').doc(driverUid).update({
        'vehicleInfo': vehicleInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Vehicle info updated successfully');
    } catch (e) {
      print('❌ Error updating vehicle info: $e');
      rethrow;
    }
  }

  // Update driver's preferred vehicle type
  Future<void> updatePreferredVehicleType({
    required String driverUid,
    required String vehicleType,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      await firestore.collection('drivers').doc(driverUid).update({
        'preferredVehicleType': vehicleType,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Preferred vehicle type updated successfully');
    } catch (e) {
      print('❌ Error updating preferred vehicle type: $e');
      rethrow;
    }
  }

  // Add payment method for driver
  Future<void> addPaymentMethod({
    required String driverUid,
    required Map<String, dynamic> paymentMethod,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      await firestore.collection('drivers').doc(driverUid).update({
        'paymentMethods': FieldValue.arrayUnion([paymentMethod]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Payment method added successfully');
    } catch (e) {
      print('❌ Error adding payment method: $e');
      rethrow;
    }
  }

  // Remove payment method for driver
  Future<void> removePaymentMethod({
    required String driverUid,
    required Map<String, dynamic> paymentMethod,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      await firestore.collection('drivers').doc(driverUid).update({
        'paymentMethods': FieldValue.arrayRemove([paymentMethod]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Payment method removed successfully');
    } catch (e) {
      print('❌ Error removing payment method: $e');
      rethrow;
    }
  }

  // Update driver's document verification status
  Future<void> updateDocumentVerification({
    required String driverUid,
    required String documentType, // 'licenseVerification' or 'vehicleRegistration'
    required bool isVerified,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      await firestore.collection('drivers').doc(driverUid).update({
        'documents.$documentType': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Document verification status updated successfully');
    } catch (e) {
      print('❌ Error updating document verification: $e');
      rethrow;
    }
  }

  // Increment total rides count
  Future<void> incrementTotalRides(String driverUid) async {
    try {
      await ensureFirebaseInitialized();
      
      await firestore.collection('drivers').doc(driverUid).update({
        'totalRides': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Total rides incremented successfully');
    } catch (e) {
      print('❌ Error incrementing total rides: $e');
      rethrow;
    }
  }

  // Update total spent amount
  Future<void> updateTotalSpent({
    required String driverUid,
    required double amount,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      await firestore.collection('drivers').doc(driverUid).update({
        'totalSpent': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Total spent updated successfully');
    } catch (e) {
      print('❌ Error updating total spent: $e');
      rethrow;
    }
  }

  // Update driver's rating
  Future<void> updateDriverRating({
    required String driverUid,
    required double rating,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      await firestore.collection('drivers').doc(driverUid).update({
        'rating': rating,
        'reviewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Driver rating updated successfully');
    } catch (e) {
      print('❌ Error updating driver rating: $e');
      rethrow;
    }
  }

  // Get driver by UID
  Future<DocumentSnapshot?> getDriverData(String driverUid) async {
    try {
      await ensureFirebaseInitialized();
      
      final doc = await firestore.collection('drivers').doc(driverUid).get();
      if (doc.exists) {
        return doc;
      }
      return null;
    } catch (e) {
      print('❌ Error getting driver data: $e');
      rethrow;
    }
  }

  // Get drivers by vehicle type
  Future<List<DocumentSnapshot>> getDriversByVehicleType(String vehicleType) async {
    try {
      await ensureFirebaseInitialized();
      
      final querySnapshot = await firestore
          .collection('drivers')
          .where('preferredVehicleType', isEqualTo: vehicleType)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs;
    } catch (e) {
      print('❌ Error getting drivers by vehicle type: $e');
      rethrow;
    }
  }

  // Get top rated drivers
  Future<List<DocumentSnapshot>> getTopRatedDrivers({int limit = 10}) async {
    try {
      await ensureFirebaseInitialized();
      
      final querySnapshot = await firestore
          .collection('drivers')
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs;
    } catch (e) {
      print('❌ Error getting top rated drivers: $e');
      rethrow;
    }
  }

  // Get drivers with verified documents
  Future<List<DocumentSnapshot>> getVerifiedDrivers() async {
    try {
      await ensureFirebaseInitialized();
      
      final querySnapshot = await firestore
          .collection('drivers')
          .where('documents.licenseVerification', isEqualTo: true)
          .where('documents.vehicleRegistration', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs;
    } catch (e) {
      print('❌ Error getting verified drivers: $e');
      rethrow;
    }
  }

  // Get driver statistics
  Future<Map<String, dynamic>> getDriverStats(String driverUid) async {
    try {
      await ensureFirebaseInitialized();
      
      final doc = await firestore.collection('drivers').doc(driverUid).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'totalRides': data['totalRides'] ?? 0,
          'totalSpent': (data['totalSpent'] ?? 0.0).toDouble(),
          'rating': (data['rating'] ?? 0.0).toDouble(),
          'reviewCount': data['reviewCount'] ?? 0,
          'isDocumentsVerified': (data['documents']['licenseVerification'] ?? false) && 
                                (data['documents']['vehicleRegistration'] ?? false),
          'preferredVehicleType': data['preferredVehicleType'] ?? '',
          'vehicleInfo': data['vehicleInfo'] ?? {},
          'paymentMethodsCount': (data['paymentMethods'] as List?)?.length ?? 0,
        };
      }
      
      return {
        'totalRides': 0,
        'totalSpent': 0.0,
        'rating': 0.0,
        'reviewCount': 0,
        'isDocumentsVerified': false,
        'preferredVehicleType': '',
        'vehicleInfo': {},
        'paymentMethodsCount': 0,
      };
    } catch (e) {
      print('❌ Error getting driver stats: $e');
      return {
        'totalRides': 0,
        'totalSpent': 0.0,
        'rating': 0.0,
        'reviewCount': 0,
        'isDocumentsVerified': false,
        'preferredVehicleType': '',
        'vehicleInfo': {},
        'paymentMethodsCount': 0,
      };
    }
  }

  // Get real-time driver data stream
  Stream<DocumentSnapshot> getDriverDataStream(String driverUid) {
    return firestore
        .collection('drivers')
        .doc(driverUid)
        .snapshots();
  }

  // Search drivers by name or email
  Future<List<DocumentSnapshot>> searchDrivers(String searchQuery) async {
    try {
      await ensureFirebaseInitialized();
      
      // Search by name (case insensitive)
      final nameQuery = await firestore
          .collection('drivers')
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
          .where('isActive', isEqualTo: true)
          .get();
      
      // Search by email (case insensitive)
      final emailQuery = await firestore
          .collection('drivers')
          .where('email', isGreaterThanOrEqualTo: searchQuery.toLowerCase())
          .where('email', isLessThanOrEqualTo: searchQuery.toLowerCase() + '\uf8ff')
          .where('isActive', isEqualTo: true)
          .get();
      
      // Combine results and remove duplicates
      final Map<String, DocumentSnapshot> uniqueResults = {};
      
      for (var doc in nameQuery.docs) {
        uniqueResults[doc.id] = doc;
      }
      
      for (var doc in emailQuery.docs) {
        uniqueResults[doc.id] = doc;
      }
      
      return uniqueResults.values.toList();
    } catch (e) {
      print('❌ Error searching drivers: $e');
      return [];
    }
  }
}