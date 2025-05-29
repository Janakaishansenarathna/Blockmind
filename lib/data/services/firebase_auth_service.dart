import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../local/models/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Get current Firebase Auth user
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream to track auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Register with email and password
  Future<UserModel> registerWithEmailPassword(
      String name, String email, String password) async {
    try {
      debugPrint('Starting email registration for: $email');

      // Create user in Firebase Auth
      UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Failed to create user account',
        );
      }

      debugPrint('Firebase user created successfully: ${result.user!.uid}');

      // Update display name
      await result.user!.updateDisplayName(name);

      // Send email verification
      await result.user!.sendEmailVerification();

      // Create user model
      UserModel userModel = UserModel.newUser(
        id: result.user!.uid,
        name: name,
        email: email,
        photoUrl: result.user!.photoURL,
      );

      debugPrint('User model created: ${userModel.id}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase Auth Exception during registration: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during registration: $e');
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  // Login with email and password
  Future<UserModel> loginWithEmailPassword(
      String email, String password) async {
    try {
      debugPrint('Starting email login for: $email');

      // Sign in with Firebase Auth
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      if (result.user == null) {
        throw FirebaseAuthException(
          code: 'login-failed',
          message: 'Login failed. Please try again.',
        );
      }

      debugPrint('Firebase login successful: ${result.user!.uid}');

      // Create user model from Firebase user
      UserModel userModel = UserModel.newUser(
        id: result.user!.uid,
        name: result.user!.displayName ?? 'User',
        email: result.user!.email!,
        photoUrl: result.user!.photoURL,
      );

      // Update last login
      userModel = userModel.copyWith(lastLoginAt: DateTime.now());

      debugPrint('User model created for login: ${userModel.id}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase Auth Exception during login: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      debugPrint('Starting Google sign in');

      // Clear any previous Google sign in session
      await _googleSignIn.signOut();

      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google sign in was cancelled by user');
        throw FirebaseAuthException(
          code: 'google-signin-aborted',
          message: 'Google sign in was cancelled by user',
        );
      }

      debugPrint('Google user obtained: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('Failed to get Google authentication tokens');
        throw FirebaseAuthException(
          code: 'google-auth-failed',
          message: 'Failed to get Google authentication tokens',
        );
      }

      debugPrint('Google authentication tokens obtained');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result =
          await _firebaseAuth.signInWithCredential(credential);

      if (result.user == null) {
        throw FirebaseAuthException(
          code: 'firebase-signin-failed',
          message: 'Failed to sign in with Google credentials',
        );
      }

      debugPrint('Firebase Google sign in successful: ${result.user!.uid}');

      // Create user model
      UserModel userModel = UserModel.newUser(
        id: result.user!.uid,
        name: result.user!.displayName ?? googleUser.displayName ?? 'User',
        email: result.user!.email ?? googleUser.email,
        photoUrl: result.user!.photoURL,
      );

      // Update last login
      userModel = userModel.copyWith(lastLoginAt: DateTime.now());

      debugPrint('User model created for Google sign in: ${userModel.id}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase Auth Exception during Google sign in: ${e.code} - ${e.message}');
      await _cleanupGoogleSignIn();
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during Google sign in: $e');
      await _cleanupGoogleSignIn();

      // Handle specific Google sign in errors
      if (e.toString().contains('12500')) {
        throw FirebaseAuthException(
          code: 'google-signin-config-error',
          message:
              'Google Sign-In configuration error. Please check your setup.',
        );
      } else if (e.toString().contains('network')) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message:
              'Network error during Google sign in. Please check your connection.',
        );
      }

      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: 'Google sign in failed: ${e.toString()}',
      );
    }
  }

  // Helper method to cleanup Google sign in state
  Future<void> _cleanupGoogleSignIn() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error during Google sign out cleanup: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('Sending password reset email to: $email');

      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Email address cannot be empty',
        );
      }

      await _firebaseAuth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase Auth Exception during password reset: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during password reset: $e');
      throw FirebaseAuthException(
        code: 'password-reset-failed',
        message: 'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      debugPrint('Starting sign out process');

      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      debugPrint('Sign out completed successfully');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Don't rethrow here as sign out should always succeed from user perspective
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
      debugPrint('Updating user profile for: ${currentUser.id}');

      // Update Firebase Auth profile
      User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        if (name != null && name != firebaseUser.displayName) {
          await firebaseUser.updateDisplayName(name);
        }

        if (photoUrl != null && photoUrl != firebaseUser.photoURL) {
          await firebaseUser.updatePhotoURL(photoUrl);
        }
      }

      // Create updated user model
      UserModel updatedUser = currentUser.copyWith(
        name: name,
        photoUrl: photoUrl,
        phone: phone,
        updatedAt: DateTime.now(),
      );

      debugPrint('User profile updated successfully');
      return updatedUser;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase Auth Exception during profile update: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during profile update: $e');
      throw FirebaseAuthException(
        code: 'profile-update-failed',
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user currently signed in',
        );
      }

      if (user.emailVerified) {
        throw FirebaseAuthException(
          code: 'email-already-verified',
          message: 'Email is already verified',
        );
      }

      debugPrint('Sending email verification to: ${user.email}');
      await user.sendEmailVerification();
      debugPrint('Email verification sent successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase Auth Exception during email verification: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during email verification: $e');
      throw FirebaseAuthException(
        code: 'email-verification-failed',
        message: 'Failed to send email verification: ${e.toString()}',
      );
    }
  }

  // Check if email is verified
  Future<bool> checkEmailVerification() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) return false;

      // Reload user to get latest verification status
      await user.reload();
      user = _firebaseAuth.currentUser; // Get refreshed user

      bool verified = user?.emailVerified ?? false;
      debugPrint('Email verification status: $verified');
      return verified;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user currently signed in',
        );
      }

      debugPrint('Deleting account for user: ${user.uid}');

      // Delete Firebase Auth user
      await user.delete();

      // Sign out from Google as well
      await _googleSignIn.signOut();

      debugPrint('Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase Auth Exception during account deletion: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during account deletion: $e');
      throw FirebaseAuthException(
        code: 'account-deletion-failed',
        message: 'Failed to delete account: ${e.toString()}',
      );
    }
  }

  // Reauthenticate user (needed for sensitive operations)
  Future<void> reauthenticateUser(String password) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user currently signed in',
        );
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      debugPrint('Reauthenticating user');
      await user.reauthenticateWithCredential(credential);
      debugPrint('User reauthenticated successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase Auth Exception during reauthentication: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during reauthentication: $e');
      throw FirebaseAuthException(
        code: 'reauthentication-failed',
        message: 'Failed to reauthenticate: ${e.toString()}',
      );
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

  // Refresh current user
  Future<void> refreshUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }
}
