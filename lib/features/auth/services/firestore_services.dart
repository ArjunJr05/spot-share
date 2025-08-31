import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spot_share2/features/auth/services/base_services.dart';
import 'package:spot_share2/features/auth/services/driver_services.dart';
import 'package:spot_share2/features/auth/services/land_owner_services.dart';
import 'package:spot_share2/firebase_options.dart';
import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';


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