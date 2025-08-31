import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spot_share2/firebase_options.dart';

// The UserType enum is now exclusively defined here
enum UserType { landOwner, driver }

class BaseFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  FirebaseFirestore get firestore => _firestore;

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      await ensureFirebaseInitialized();
      
      // First check in land_owners collection
      final landOwnerQuery = await _firestore
          .collection('land_owners')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (landOwnerQuery.docs.isNotEmpty) {
        final doc = landOwnerQuery.docs.first;
        return {
          'uid': doc.id,
          'userType': 'landOwner',
          'collection': 'land_owners',
          ...doc.data(),
        };
      }

      // Then check in drivers collection
      final driverQuery = await _firestore
          .collection('drivers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (driverQuery.docs.isNotEmpty) {
        final doc = driverQuery.docs.first;
        return {
          'uid': doc.id,
          'userType': 'driver',
          'collection': 'drivers',
          ...doc.data(),
        };
      }
      
      return null;
    } catch (e) {
      print('❌ Error checking user by email: $e');
      rethrow;
    }
  }

  Future<void> saveRegistrationAnalytics({
    required String uid,
    required String email,
    required UserType userType,
    required bool isGoogleSignIn,
  }) async {
    try {
      await ensureFirebaseInitialized();
      await _firestore.collection('user_registrations').add({
        'uid': uid,
        'email': email,
        'userType': userType.name,
        'isGoogleSignIn': isGoogleSignIn,
        'registrationTimestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
      print('✅ Registration analytics saved');
    } catch (e) {
      print('❌ Error saving registration analytics: $e');
      // Don't throw error for analytics failure
    }
  }

  Future<void> saveLoginAnalytics({
    required String uid,
    required String email,
    required UserType userType,
    required bool isGoogleSignIn,
  }) async {
    try {
      await ensureFirebaseInitialized();
      await _firestore.collection('user_logins').add({
        'uid': uid,
        'email': email,
        'userType': userType.name,
        'isGoogleSignIn': isGoogleSignIn,
        'loginTimestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
      print('✅ Login analytics saved');
    } catch (e) {
      print('❌ Error saving login analytics: $e');
    }
  }

  Future<QuerySnapshot> getUsersByType(UserType userType) async {
    try {
      await ensureFirebaseInitialized();
      String collection = userType == UserType.landOwner ? 'land_owners' : 'drivers';
      return await _firestore.collection(collection).get();
    } catch (e) {
      print('❌ Error getting users by type: $e');
      rethrow;
    }
  }

  Future<void> initializeDefaultData() async {
    try {
      await ensureFirebaseInitialized();

      final vehicleTypes = [
        {'id': 'car', 'name': 'Car', 'icon': '🚗', 'enabled': true},
        {'id': 'bike', 'name': 'Bike', 'icon': '🏍️', 'enabled': true},
        {'id': 'truck', 'name': 'Truck', 'icon': '🚚', 'enabled': true},
        {'id': 'van', 'name': 'Van', 'icon': '🚐', 'enabled': true},
        {'id': 'auto', 'name': 'Auto', 'icon': '🛺', 'enabled': true},
        {'id': 'lorry', 'name': 'Lorry', 'icon': '🚛', 'enabled': true},
      ];

      for (var vehicle in vehicleTypes) {
        await _firestore.collection('vehicle_types').doc(vehicle['id'] as String).set(vehicle);
      }

      final locations = [
        {'id': 'downtown', 'name': 'Downtown', 'coordinates': {'lat': 12.9716, 'lng': 77.5946}, 'enabled': true},
        {'id': 'airport', 'name': 'Airport', 'coordinates': {'lat': 13.0827, 'lng': 80.2707}, 'enabled': true},
        {'id': 'mall', 'name': 'Shopping Mall', 'coordinates': {'lat': 12.9784, 'lng': 77.6408}, 'enabled': true},
      ];

      for (var location in locations) {
        await _firestore.collection('parking_locations').doc(location['id'] as String).set(location);
      }

      print('✅ Default data initialized successfully');
    } catch (e) {
      print('❌ Error initializing default data: $e');
      rethrow;
    }
  }

  bool isFirebaseInitialized() {
    return Firebase.apps.isNotEmpty;
  }

  Future<bool> testConnection() async {
    try {
      await ensureFirebaseInitialized();
      await _firestore.collection('test').doc('connection_test').get();
      print('✅ Firestore connection test successful');
      return true;
    } catch (e) {
      print('❌ Firestore connection test failed: $e');
      return false;
    }
  }

  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      await ensureFirebaseInitialized();
      
      // First check in land_owners collection
      final landOwnerDoc = await _firestore.collection('land_owners').doc(uid).get();
      if (landOwnerDoc.exists) {
        return landOwnerDoc;
      }
      
      // Then check in drivers collection
      final driverDoc = await _firestore.collection('drivers').doc(uid).get();
      if (driverDoc.exists) {
        return driverDoc;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      rethrow;
    }
  }

  Future<UserType?> getUserType(String uid) async {
    try {
      await ensureFirebaseInitialized();
      
      // Check in land_owners collection first
      final landOwnerDoc = await _firestore.collection('land_owners').doc(uid).get();
      if (landOwnerDoc.exists) {
        return UserType.landOwner;
      }
      
      // Check in drivers collection
      final driverDoc = await _firestore.collection('drivers').doc(uid).get();
      if (driverDoc.exists) {
        return UserType.driver;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting user type: $e');
      rethrow;
    }
  }

  Future<void> updateLastLogin(String uid, UserType userType) async {
    try {
      await ensureFirebaseInitialized();
      String collection = userType == UserType.landOwner ? 'land_owners' : 'drivers';
      await _firestore.collection(collection).doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating last login: $e');
      rethrow;
    }
  }

  Future<void> updateUserData(String uid, UserType userType, Map<String, dynamic> updates) async {
    try {
      await ensureFirebaseInitialized();
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      String collection = userType == UserType.landOwner ? 'land_owners' : 'drivers';
      await _firestore.collection(collection).doc(uid).update(updates);
      print('✅ User data updated successfully');
    } catch (e) {
      print('❌ Error updating user data: $e');
      rethrow;
    }
  }

  Future<void> deleteUserData(String uid, UserType userType) async {
    try {
      await ensureFirebaseInitialized();
      String collection = userType == UserType.landOwner ? 'land_owners' : 'drivers';
      await _firestore.collection(collection).doc(uid).delete();
      print('✅ User data deleted successfully from Firestore');
    } catch (e) {
      print('❌ Error deleting user data: $e');
      rethrow;
    }
  }
}