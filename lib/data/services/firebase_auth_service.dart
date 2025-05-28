import 'package:firebase_auth/firebase_auth.dart';
import '../local/models/user_model.dart';
import '../repositories/auth_repository.dart';

class FirebaseAuthService {
  final AuthRepository _authRepository = AuthRepository();

  // Get current Firebase Auth user
  User? get currentUser => _authRepository.currentUser;

  // Stream to track auth state changes
  Stream<User?> get authStateChanges => _authRepository.authStateChanges;

  // Register with email and password
  Future<UserModel> registerWithEmailPassword(
      String name, String email, String password) async {
    try {
      return await _authRepository.registerWithEmailPassword(
          name, email, password);
    } catch (e) {
      print('FirebaseAuthService - Register error: $e');
      rethrow;
    }
  }

  // Login with email and password
  Future<UserModel> loginWithEmailPassword(
      String email, String password) async {
    try {
      return await _authRepository.loginWithEmailPassword(email, password);
    } catch (e) {
      print('FirebaseAuthService - Login error: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      return await _authRepository.signInWithGoogle();
    } catch (e) {
      print('FirebaseAuthService - Google sign in error: $e');
      rethrow;
    }
  }

  // Sign in with Facebook (commented out as per your code)
  // Future<UserModel> signInWithFacebook() async {
  //   try {
  //     return await _authRepository.signInWithFacebook();
  //   } catch (e) {
  //     print('FirebaseAuthService - Facebook sign in error: $e');
  //     rethrow;
  //   }
  // }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      return await _authRepository.resetPassword(email);
    } catch (e) {
      print('FirebaseAuthService - Reset password error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      return await _authRepository.signOut();
    } catch (e) {
      print('FirebaseAuthService - Sign out error: $e');
      rethrow;
    }
  }

  // Get current user model
  Future<UserModel?> getCurrentUser() async {
    try {
      UserModel? user = await _authRepository.getCurrentUserFromLocal();

      // If not in local storage or auth state changed, try Firestore
      if (user == null || user.id != currentUser?.uid) {
        user = await _authRepository.getCurrentUserFromFirestore();

        // If found in Firestore, save to local storage
        if (user != null) {
          await _authRepository.saveUserToLocal(user);
        }
      }

      return user;
    } catch (e) {
      print('FirebaseAuthService - Get current user error: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      return await _authRepository.isLoggedIn();
    } catch (e) {
      print('FirebaseAuthService - Check logged in error: $e');
      return false;
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required UserModel currentUser,
    String? name,
    String? photoUrl,
    String? phone,
  }) async {
    try {
      return await _authRepository.updateUserProfile(
        currentUser: currentUser,
        name: name,
        photoUrl: photoUrl,
        phone: phone,
      );
    } catch (e) {
      print('FirebaseAuthService - Update profile error: $e');
      rethrow;
    }
  }

  // Update user premium status
  Future<UserModel> updatePremiumStatus({
    required UserModel currentUser,
    required bool isPremium,
    required DateTime? expiryDate,
  }) async {
    try {
      return await _authRepository.updatePremiumStatus(
        currentUser: currentUser,
        isPremium: isPremium,
        expiryDate: expiryDate,
      );
    } catch (e) {
      print('FirebaseAuthService - Update premium status error: $e');
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      return await _authRepository.sendEmailVerification();
    } catch (e) {
      print('FirebaseAuthService - Send email verification error: $e');
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      return await _authRepository.isEmailVerified();
    } catch (e) {
      print('FirebaseAuthService - Check email verified error: $e');
      return false;
    }
  }

  // Get current user for verification screen
  Future<UserModel> getCurrentUserForVerification() async {
    try {
      return await _authRepository.getCurrentUserForVerification();
    } catch (e) {
      print(
          'FirebaseAuthService - Get current user for verification error: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      return await _authRepository.deleteAccount();
    } catch (e) {
      print('FirebaseAuthService - Delete account error: $e');
      rethrow;
    }
  }

  // Refresh user data
  Future<UserModel?> refreshUserData() async {
    try {
      if (currentUser != null) {
        return await _authRepository.getCurrentUserFromFirestore();
      }
      return null;
    } catch (e) {
      print('FirebaseAuthService - Refresh user data error: $e');
      return null;
    }
  }

  // Check auth state
  bool get isAuthenticated => currentUser != null;

  // Get user ID
  String? get userId => currentUser?.uid;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user display name
  String? get userDisplayName => currentUser?.displayName;

  // Get user photo URL
  String? get userPhotoUrl => currentUser?.photoURL;
}
