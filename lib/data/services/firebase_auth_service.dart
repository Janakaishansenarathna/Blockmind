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
    return _authRepository.registerWithEmailPassword(name, email, password);
  }

  // Login with email and password
  Future<UserModel> loginWithEmailPassword(
      String email, String password) async {
    return _authRepository.loginWithEmailPassword(email, password);
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    return _authRepository.signInWithGoogle();
  }

  // Sign in with Facebook
  // Future<UserModel> signInWithFacebook() async {
  //   return _authRepository.signInWithFacebook();
  // }

  // Reset password
  Future<void> resetPassword(String email) async {
    return _authRepository.resetPassword(email);
  }

  // Logout
  Future<void> signOut() async {
    return _authRepository.signOut();
  }

  // Get current user model
  Future<UserModel?> getCurrentUser() async {
    UserModel? user = await _authRepository.getCurrentUserFromLocal();

    // If not in local storage or auth state changed, try Firestore
    if (user == null || user.id != currentUser?.uid) {
      user = await _authRepository.getCurrentUserFromFirestore();

      // If found in Firestore, save to local storage
      if (user != null) {
        // Use a public method from the repository to save user to local storage
        // instead of directly accessing the private _userDao property
        await _authRepository.saveUserToLocal(user);
      }
    }

    return user;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _authRepository.isLoggedIn();
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required UserModel currentUser,
    String? name,
    String? photoUrl,
  }) async {
    return _authRepository.updateUserProfile(
      currentUser: currentUser,
      name: name,
      photoUrl: photoUrl,
    );
  }

  // Update user premium status
  Future<UserModel> updatePremiumStatus({
    required UserModel currentUser,
    required bool isPremium,
    required DateTime? expiryDate,
  }) async {
    return _authRepository.updatePremiumStatus(
      currentUser: currentUser,
      isPremium: isPremium,
      expiryDate: expiryDate,
    );
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    return _authRepository.sendEmailVerification();
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    return _authRepository.isEmailVerified();
  }

  // Get current user for verification screen
  Future<UserModel> getCurrentUserForVerification() async {
    return _authRepository.getCurrentUserForVerification();
  }
}
