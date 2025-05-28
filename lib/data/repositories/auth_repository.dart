import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../local/daos/user_dao.dart';
import '../local/database/database_helper.dart';
import '../local/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // final FacebookAuth _facebookAuth = FacebookAuth.instance;
  final UserDao _userDao = UserDao();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Stream to track auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Register with email and password
  Future<UserModel> registerWithEmailPassword(
      String name, String email, String password) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

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

      // Save to Firestore
      await _databaseHelper.createOrUpdateUser(userModel);

      // Save to local storage
      await _userDao.saveUser(userModel);

      return userModel;
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // Login with email and password
  Future<UserModel> loginWithEmailPassword(
      String email, String password) async {
    try {
      // Sign in with Firebase Auth
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      // Check if email is verified
      if (!result.user!.emailVerified) {
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before logging in.',
        );
      }

      // Get user from Firestore
      UserModel? userModel = await _databaseHelper.getUser(result.user!.uid);

      if (userModel == null) {
        // If user doesn't exist in Firestore (rare case), create new user model
        userModel = UserModel.newUser(
          id: result.user!.uid,
          name: result.user!.displayName ?? 'User',
          email: result.user!.email!,
          photoUrl: result.user!.photoURL,
        );

        await _databaseHelper.createOrUpdateUser(userModel);
      } else {
        // Update last login
        // await _databaseHelper.updateUserLastLogin(result.user!.uid);

        // Update user model with the latest login time
        userModel = userModel.copyWith(
          lastLoginAt: DateTime.now(),
        );

        await _databaseHelper.createOrUpdateUser(userModel);
      }

      // Save to local storage
      await _userDao.saveUser(userModel);

      return userModel;
    } catch (e) {
      print('Error logging in: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in aborted');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result =
          await _firebaseAuth.signInWithCredential(credential);

      // Check if this is a new user
      bool isNewUser = !(await _databaseHelper.userExists(result.user!.uid));

      UserModel userModel;

      if (isNewUser) {
        // Create new user model
        userModel = UserModel.newUser(
          id: result.user!.uid,
          name: result.user!.displayName ?? 'User',
          email: result.user!.email!,
          photoUrl: result.user!.photoURL,
        );
      } else {
        // Get existing user from Firestore
        userModel = (await _databaseHelper.getUser(result.user!.uid))!;

        // Update last login
        userModel = userModel.copyWith(
          lastLoginAt: DateTime.now(),
          // Update profile picture if it has changed
          photoUrl: result.user!.photoURL ?? userModel.photoUrl,
          // Update name if it has changed
          name: result.user!.displayName ?? userModel.name,
        );
      }

      // Save/update in Firestore
      await _databaseHelper.createOrUpdateUser(userModel);

      // Save to local storage
      await _userDao.saveUser(userModel);

      return userModel;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // // Sign in with Facebook
  // Future<UserModel> signInWithFacebook() async {
  //   try {
  //     // Trigger the Facebook sign in flow
  //     final LoginResult loginResult = await _facebookAuth.login();

  //     if (loginResult.status != LoginStatus.success) {
  //       throw Exception('Facebook sign in failed: ${loginResult.message}');
  //     }

  //     // Get access token
  //     final AccessToken accessToken = loginResult.accessToken!;

  //     // Create a Facebook credential
  //     final OAuthCredential facebookCredential =
  //         FacebookAuthProvider.credential(accessToken.tokenString);

  //     // Sign in to Firebase with the Facebook credential
  //     UserCredential result =
  //         await _firebaseAuth.signInWithCredential(facebookCredential);

  //     // Get additional user data from Facebook
  //     final userData = await _facebookAuth.getUserData();

  //     // Check if this is a new user
  //     bool isNewUser = _databaseHelper.userExists(result.user!.uid) as bool;

  //     UserModel userModel;

  //     if (isNewUser) {
  //       // Create new user model
  //       userModel = UserModel.newUser(
  //         id: result.user!.uid,
  //         name: result.user!.displayName ?? userData['name'] ?? 'User',
  //         email: result.user!.email ?? userData['email'] ?? '',
  //         photoUrl: result.user!.photoURL,
  //       );
  //     } else {
  //       // Get existing user from Firestore
  //       userModel = (await _databaseHelper.getUser(result.user!.uid))!;

  //       // Update last login
  //       userModel = userModel.copyWith(
  //         lastLoginAt: DateTime.now(),
  //         // Update profile picture if it has changed
  //         photoUrl: result.user!.photoURL ?? userModel.photoUrl,
  //         // Update name if it has changed
  //         name: result.user!.displayName ?? userModel.name,
  //       );
  //     }

  //     // Save/update in Firestore
  //     await _databaseHelper.createOrUpdateUser(userModel);

  //     // Save to local storage
  //     await _userDao.saveUser(userModel);

  //     return userModel;
  //   } catch (e) {
  //     print('Error signing in with Facebook: $e');
  //     rethrow;
  //   }
  // }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Facebook
      // await _facebookAuth.logOut();

      // Remove from local storage
      await _userDao.deleteUser();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user model from local storage
  Future<UserModel?> getCurrentUserFromLocal() async {
    return _userDao.getUser();
  }

  // Get current user model from Firestore
  Future<UserModel?> getCurrentUserFromFirestore() async {
    if (currentUser == null) return null;
    return _databaseHelper.getUser(currentUser!.uid);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _userDao.isLoggedIn();
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required UserModel currentUser,
    String? name,
    String? photoUrl,
  }) async {
    try {
      // Create updated user model
      UserModel updatedUser = currentUser.copyWith(
        name: name,
        photoUrl: photoUrl,
      );

      // Update in Firestore
      await _databaseHelper.createOrUpdateUser(updatedUser);

      // Update in local storage
      await _userDao.updateUser(updatedUser);

      // Update Firebase Auth profile
      if (name != null) {
        await _firebaseAuth.currentUser?.updateDisplayName(name);
      }

      if (photoUrl != null) {
        await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
      }

      return updatedUser;
    } catch (e) {
      print('Error updating user profile: $e');
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
      // Create updated user model
      UserModel updatedUser = currentUser.copyWith(
        isPremium: isPremium,
        premiumExpiryDate: expiryDate,
        maxPlansAllowed: isPremium ? 999 : 5, // Unlimited for premium
        maxAppsPerPlan: isPremium ? 999 : 3, // Unlimited for premium
      );

      // Update in Firestore
      await _databaseHelper.createOrUpdateUser(updatedUser);

      // Update in local storage
      await _userDao.updateUser(updatedUser);

      return updatedUser;
    } catch (e) {
      print('Error updating premium status: $e');
      rethrow;
    }
  }

  Future<void> saveUserToLocal(UserModel user) async {
    await _userDao.saveUser(user);
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('Error sending email verification: $e');
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      return _firebaseAuth.currentUser?.emailVerified ?? false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  // Get current user without email verification check (for verification screen)
  Future<UserModel> getCurrentUserForVerification() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user currently signed in');
      }

      // Get user from Firestore
      UserModel? userModel = await _databaseHelper.getUser(user.uid);

      if (userModel == null) {
        // Create new user model if not found
        userModel = UserModel.newUser(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email!,
          photoUrl: user.photoURL,
        );
        await _databaseHelper.createOrUpdateUser(userModel);
      }

      return userModel;
    } catch (e) {
      print('Error getting current user for verification: $e');
      rethrow;
    }
  }
}
