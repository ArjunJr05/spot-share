import 'package:firebase_auth/firebase_auth.dart';
import 'package:spot_share2/features/auth/services/base_services.dart';
import 'package:spot_share2/features/auth/services/firestore_services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    String? phoneNumber,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        await credential.user!.sendEmailVerification();
        
        // Save user data to appropriate collection based on userType
        await _firestoreService.saveUserData(
          uid: credential.user!.uid,
          email: email,
          name: name,
          userType: userType,
          phoneNumber: phoneNumber,
          photoUrl: credential.user!.photoURL,
          emailVerified: false,
        );

        // Save registration analytics
        await _firestoreService.saveRegistrationAnalytics(
          uid: credential.user!.uid,
          email: email,
          userType: userType,
          isGoogleSignIn: false,
        );

        return credential;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      print('Error in signUpWithEmailAndPassword: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Get user type to determine which collection to update
        final userType = await _firestoreService.getUserType(credential.user!.uid);
        
        if (userType != null) {
          // Update last login in the appropriate collection
          await _firestoreService.updateLastLogin(credential.user!.uid, userType);
          
          // Update email verification status in the appropriate collection
          await _firestoreService.updateUserData(credential.user!.uid, userType, {
            'emailVerified': credential.user!.emailVerified,
          });

          // Save login analytics
          await _firestoreService.saveLoginAnalytics(
            uid: credential.user!.uid,
            email: email,
            userType: userType,
            isGoogleSignIn: false,
          );
        }
      }
      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      print('Error in signInWithEmailAndPassword: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user type before deleting the account
        final userType = await _firestoreService.getUserType(user.uid);
        
        // Delete user data from Firestore first
        if (userType != null) {
          await _firestoreService.deleteUserData(user.uid, userType);
        }
        
        // Then delete the Firebase Auth account
        await user.delete();
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // Helper method to get current user's type
  Future<UserType?> getCurrentUserType() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await _firestoreService.getUserType(user.uid);
    }
    return null;
  }

  // Helper method to check if current user exists in Firestore
  Future<bool> isUserDataComplete() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firestoreService.getUserData(user.uid);
      return userData != null && userData.exists;
    }
    return false;
  }

  // Method to update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }

        // Also update in Firestore
        final userType = await _firestoreService.getUserType(user.uid);
        if (userType != null) {
          final updates = <String, dynamic>{};
          if (displayName != null) updates['name'] = displayName;
          if (photoUrl != null) updates['photoUrl'] = photoUrl;
          
          if (updates.isNotEmpty) {
            await _firestoreService.updateUserData(user.uid, userType, updates);
          }
        }
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Method to resend email verification
  Future<void> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('Error resending email verification: $e');
      rethrow;
    }
  }

  // Method to check if email is verified and update Firestore accordingly
  Future<void> refreshUserVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = _auth.currentUser;
        
        if (updatedUser != null) {
          final userType = await _firestoreService.getUserType(updatedUser.uid);
          if (userType != null) {
            await _firestoreService.updateUserData(updatedUser.uid, userType, {
              'emailVerified': updatedUser.emailVerified,
            });
          }
        }
      }
    } catch (e) {
      print('Error refreshing user verification status: $e');
      rethrow;
    }
  }

  // Additional helper methods for better functionality

  // Get current user's complete data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firestoreService.getUserData(user.uid);
      if (userData != null && userData.exists) {
        return userData.data() as Map<String, dynamic>?;
      }
    }
    return null;
  }

  // Check if current user is landowner
  Future<bool> isCurrentUserLandOwner() async {
    final userType = await getCurrentUserType();
    return userType == UserType.landOwner;
  }

  // Check if current user is driver
  Future<bool> isCurrentUserDriver() async {
    final userType = await getCurrentUserType();
    return userType == UserType.driver;
  }

  // Get current user's landowner data (if landowner)
  Future<Map<String, dynamic>?> getCurrentLandownerData() async {
    final user = _auth.currentUser;
    if (user != null && await isCurrentUserLandOwner()) {
      final userData = await _firestoreService.getUserData(user.uid);
      if (userData != null && userData.exists) {
        return userData.data() as Map<String, dynamic>?;
      }
    }
    return null;
  }

  // Get current user's driver data (if driver)
  Future<Map<String, dynamic>?> getCurrentDriverData() async {
    final user = _auth.currentUser;
    if (user != null && await isCurrentUserDriver()) {
      final userData = await _firestoreService.getDriverData(user.uid);
      if (userData != null && userData.exists) {
        return userData.data() as Map<String, dynamic>?;
      }
    }
    return null;
  }

  // Update current user's phone number
  Future<void> updatePhoneNumber(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userType = await _firestoreService.getUserType(user.uid);
        if (userType != null) {
          await _firestoreService.updateUserData(user.uid, userType, {
            'phoneNumber': phoneNumber,
          });
        }
      }
    } catch (e) {
      print('Error updating phone number: $e');
      rethrow;
    }
  }

  // Check if user has completed their profile setup
  Future<bool> isProfileComplete() async {
    final userData = await getCurrentUserData();
    if (userData != null) {
      // Check if required fields are filled
      final hasName = userData['name'] != null && userData['name'].toString().isNotEmpty;
      final hasPhone = userData['phoneNumber'] != null && userData['phoneNumber'].toString().isNotEmpty;
      
      return hasName && hasPhone;
    }
    return false;
  }

  // Get user's display name with fallback
  String getUserDisplayName() {
    final user = _auth.currentUser;
    if (user != null) {
      return user.displayName ?? user.email?.split('@').first ?? 'User';
    }
    return 'User';
  }

  // Check connection and initialize services
  Future<bool> initializeServices() async {
    try {
      await _firestoreService.ensureFirebaseInitialized();
      return await _firestoreService.testConnection();
    } catch (e) {
      print('Error initializing services: $e');
      return false;
    }
  }

  // Stream to listen for auth state changes with user data
  Stream<Map<String, dynamic>?> get authStateWithUserData async* {
    await for (final user in _auth.authStateChanges()) {
      if (user != null) {
        try {
          final userData = await _firestoreService.getUserData(user.uid);
          if (userData != null && userData.exists) {
            final data = userData.data() as Map<String, dynamic>;
            data['firebaseUser'] = user;
            yield data;
          } else {
            yield {'firebaseUser': user};
          }
        } catch (e) {
          print('Error fetching user data in stream: $e');
          yield {'firebaseUser': user};
        }
      } else {
        yield null;
      }
    }
  }
}