import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spot_share2/features/auth/services/base_services.dart';

class ParkingSessionService extends BaseFirestoreService {
  static final ParkingSessionService _instance = ParkingSessionService._internal();
  factory ParkingSessionService() => _instance;
  ParkingSessionService._internal();

  // Start a new parking session
  Future<String?> startParkingSession({
    required String driverUid,
    required String location,
    required String vehicleType,
    required double hourlyRate,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      // Check if there's already an active session
      final activeSessions = await firestore
          .collection('parking_sessions')
          .where('driverUid', isEqualTo: driverUid)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (activeSessions.docs.isNotEmpty) {
        throw Exception('Driver already has an active parking session');
      }
      
      final sessionData = {
        'driverUid': driverUid,
        'location': location,
        'vehicleType': vehicleType,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'hourlyRate': hourlyRate,
        'totalCost': 0.0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final docRef = await firestore.collection('parking_sessions').add(sessionData);
      print('✅ Parking session started successfully');
      
      return docRef.id;
    } catch (e) {
      print('❌ Error starting parking session: $e');
      rethrow;
    }
  }

  // End an active parking session
  Future<Map<String, dynamic>?> endParkingSession({
    required String driverUid,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      // Find active session
      final activeSessions = await firestore
          .collection('parking_sessions')
          .where('driverUid', isEqualTo: driverUid)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (activeSessions.docs.isEmpty) {
        throw Exception('No active parking session found');
      }
      
      final sessionDoc = activeSessions.docs.first;
      final sessionData = sessionDoc.data();
      final startTime = (sessionData['startTime'] as Timestamp).toDate();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      final hours = duration.inMinutes / 60.0;
      final hourlyRate = sessionData['hourlyRate'] as double;
      final totalCost = hours * hourlyRate;
      
      // Update session
      await sessionDoc.reference.update({
        'endTime': FieldValue.serverTimestamp(),
        'totalCost': totalCost,
        'duration': duration.inMinutes,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update driver's total spent
      await firestore.collection('drivers').doc(driverUid).update({
        'totalSpent': FieldValue.increment(totalCost),
        'totalRides': FieldValue.increment(1),
      });
      
      print('✅ Parking session ended successfully');
      
      return {
        'sessionId': sessionDoc.id,
        'duration': duration.inMinutes,
        'totalCost': totalCost,
        'location': sessionData['location'],
        'startTime': startTime,
        'endTime': endTime,
      };
    } catch (e) {
      print('❌ Error ending parking session: $e');
      rethrow;
    }
  }

  // Get current active parking session
  Future<DocumentSnapshot?> getActiveParkingSession(String driverUid) async {
    try {
      await ensureFirebaseInitialized();
      
      final activeSessions = await firestore
          .collection('parking_sessions')
          .where('driverUid', isEqualTo: driverUid)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (activeSessions.docs.isNotEmpty) {
        return activeSessions.docs.first;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting active parking session: $e');
      return null;
    }
  }

  // Get parking session history for a driver
  Future<List<DocumentSnapshot>> getParkingHistory({
    required String driverUid,
    int limit = 20,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      final querySnapshot = await firestore
          .collection('parking_sessions')
          .where('driverUid', isEqualTo: driverUid)
          .where('isActive', isEqualTo: false)
          .orderBy('endTime', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs;
    } catch (e) {
      print('❌ Error getting parking history: $e');
      return [];
    }
  }

  // Stream active parking session for real-time updates
  Stream<DocumentSnapshot?> getActiveParkingSessionStream(String driverUid) async* {
    try {
      await ensureFirebaseInitialized();
      
      yield* firestore
          .collection('parking_sessions')
          .where('driverUid', isEqualTo: driverUid)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              return snapshot.docs.first;
            }
            return null;
          });
    } catch (e) {
      print('❌ Error streaming active parking session: $e');
      yield null;
    }
  }

  // Update parking session location (if driver moves)
  Future<void> updateParkingLocation({
    required String sessionId,
    required String newLocation,
  }) async {
    try {
      await ensureFirebaseInitialized();
      
      await firestore.collection('parking_sessions').doc(sessionId).update({
        'location': newLocation,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Parking location updated successfully');
    } catch (e) {
      print('❌ Error updating parking location: $e');
      rethrow;
    }
  }

  // Get parking statistics for a driver
  Future<Map<String, dynamic>> getParkingStatistics(String driverUid) async {
    try {
      await ensureFirebaseInitialized();
      
      final allSessions = await firestore
          .collection('parking_sessions')
          .where('driverUid', isEqualTo: driverUid)
          .where('isActive', isEqualTo: false)
          .get();
      
      if (allSessions.docs.isEmpty) {
        return {
          'totalSessions': 0,
          'totalSpent': 0.0,
          'totalTimeParked': 0,
          'averageSessionDuration': 0,
          'averageSessionCost': 0.0,
          'mostUsedLocation': 'N/A',
        };
      }
      
      double totalSpent = 0.0;
      int totalTimeParked = 0;
      Map<String, int> locationCount = {};
      
      for (var doc in allSessions.docs) {
        final data = doc.data();
        totalSpent += (data['totalCost'] ?? 0.0) as double;
        totalTimeParked += (data['duration'] ?? 0) as int;
        
        final location = data['location'] as String;
        locationCount[location] = (locationCount[location] ?? 0) + 1;
      }
      
      final totalSessions = allSessions.docs.length;
      final averageSessionDuration = totalSessions > 0 ? totalTimeParked / totalSessions : 0;
      final averageSessionCost = totalSessions > 0 ? totalSpent / totalSessions : 0.0;
      
      String mostUsedLocation = 'N/A';
      if (locationCount.isNotEmpty) {
        mostUsedLocation = locationCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }
      
      return {
        'totalSessions': totalSessions,
        'totalSpent': totalSpent,
        'totalTimeParked': totalTimeParked,
        'averageSessionDuration': averageSessionDuration,
        'averageSessionCost': averageSessionCost,
        'mostUsedLocation': mostUsedLocation,
      };
    } catch (e) {
      print('❌ Error getting parking statistics: $e');
      return {
        'totalSessions': 0,
        'totalSpent': 0.0,
        'totalTimeParked': 0,
        'averageSessionDuration': 0,
        'averageSessionCost': 0.0,
        'mostUsedLocation': 'N/A',
      };
    }
  }
}