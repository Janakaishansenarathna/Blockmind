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

      if (result.user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Failed to create user account',
        );
      }

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

      if (result.user == null) {
        throw FirebaseAuthException(
          code: 'login-failed',
          message: 'Login failed. Please try again.',
        );
      }

      // Check if email is verified - Allow login but handle verification in controller
      // This allows the user to access the email verification screen

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
        // Update last login and user info
        userModel = userModel.copyWith(
          lastLoginAt: DateTime.now(),
          // Update name if it has changed
          name: result.user!.displayName ?? userModel.name,
          // Update photo if it has changed
          photoUrl: result.user!.photoURL ?? userModel.photoUrl,
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
      // Sign out from any previous sessions to ensure clean login
      await _googleSignIn.signOut();

      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-signin-aborted',
          message: 'Google sign in was cancelled by user',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'google-auth-failed',
          message: 'Failed to get Google authentication tokens',
        );
      }

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

      // Check if this is a new user
      bool isNewUser = !(await _databaseHelper.userExists(result.user!.uid));

      UserModel userModel;

      if (isNewUser) {
        // Create new user model
        userModel = UserModel.newUser(
          id: result.user!.uid,
          name: result.user!.displayName ?? googleUser.displayName ?? 'User',
          email: result.user!.email ?? googleUser.email,
          photoUrl: result.user!.photoURL,
        );
      } else {
        // Get existing user from Firestore
        userModel = (await _databaseHelper.getUser(result.user!.uid))!;

        // Update last login and any changed info
        userModel = userModel.copyWith(
          lastLoginAt: DateTime.now(),
          // Update profile picture if it has changed
          photoUrl: result.user!.photoURL ?? userModel.photoUrl,
          // Update name if it has changed
          name: result.user!.displayName ?? userModel.name,
          // Update email if it has changed (rare but possible)
          email: result.user!.email ?? userModel.email,
        );
      }

      // Save/update in Firestore
      await _databaseHelper.createOrUpdateUser(userModel);

      // Save to local storage
      await _userDao.saveUser(userModel);

      return userModel;
    } catch (e) {
      print('Error signing in with Google: $e');
      // Sign out from Google on error to reset state
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        print(
            'Error signing out from Google after failed login: $signOutError');
      }
      rethrow;
    }
  }

  // // Sign in with Facebook
  // Future<UserModel> signInWithFacebook() async {
  //   try {
  //     // Trigger the Facebook sign in flow
  //     final LoginResult loginResult = await _facebookAuth.login();

  //     if (loginResult.status != LoginStatus.success) {
  //       throw FirebaseAuthException(
  //         code: 'facebook-signin-failed',
  //         message: 'Facebook sign in failed: ${loginResult.message}',
  //       );
  //     }

  //     // Get access token
  //     final AccessToken accessToken = loginResult.accessToken!;

  //     // Create a Facebook credential
  //     final OAuthCredential facebookCredential =
  //         FacebookAuthProvider.credential(accessToken.tokenString);

  //     // Sign in to Firebase with the Facebook credential
  //     UserCredential result =
  //         await _firebaseAuth.signInWithCredential(facebookCredential);

  //     if (result.user == null) {
  //       throw FirebaseAuthException(
  //         code: 'firebase-signin-failed',
  //         message: 'Failed to sign in with Facebook credentials',
  //       );
  //     }

  //     // Get additional user data from Facebook
  //     final userData = await _facebookAuth.getUserData();

  //     // Check if this is a new user
  //     bool isNewUser = !(await _databaseHelper.userExists(result.user!.uid));

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
  //     // Log out from Facebook on error
  //     try {
  //       await _facebookAuth.logOut();
  //     } catch (logoutError) {
  //       print('Error logging out from Facebook after failed login: $logoutError');
  //     }
  //     rethrow;
  //   }
  // }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Email address cannot be empty',
        );
      }

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
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('Error signing out from Google: $e');
      }

      // Sign out from Facebook
      // try {
      //   await _facebookAuth.logOut();
      // } catch (e) {
      //   print('Error signing out from Facebook: $e');
      // }

      // Remove from local storage
      await _userDao.deleteUser();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user model from local storage
  Future<UserModel?> getCurrentUserFromLocal() async {
    try {
      return await _userDao.getUser();
    } catch (e) {
      print('Error getting user from local storage: $e');
      return null;
    }
  }

  // Get current user model from Firestore
  Future<UserModel?> getCurrentUserFromFirestore() async {
    try {
      if (currentUser == null) return null;
      return await _databaseHelper.getUser(currentUser!.uid);
    } catch (e) {
      print('Error getting user from Firestore: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      // Check both Firebase Auth and local storage
      bool hasFirebaseUser = currentUser != null;
      bool hasLocalUser = await _userDao.isLoggedIn();

      return hasFirebaseUser && hasLocalUser;
    } catch (e) {
      print('Error checking login status: $e');
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
      // Create updated user model
      UserModel updatedUser = currentUser.copyWith(
        name: name,
        photoUrl: photoUrl,
        phone: phone,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _databaseHelper.createOrUpdateUser(updatedUser);

      // Update in local storage
      await _userDao.updateUser(updatedUser);

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
        updatedAt: DateTime.now(),
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

  // Save user to local storage (public method)
  Future<void> saveUserToLocal(UserModel user) async {
    try {
      await _userDao.saveUser(user);
    } catch (e) {
      print('Error saving user to local storage: $e');
      rethrow;
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

      await user.sendEmailVerification();
    } catch (e) {
      print('Error sending email verification: $e');
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) return false;

      // Reload user to get latest verification status
      await user.reload();
      user = _firebaseAuth.currentUser; // Get refreshed user

      return user?.emailVerified ?? false;
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
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user currently signed in',
        );
      }

      // Get user from Firestore
      UserModel? userModel = await _databaseHelper.getUser(user.uid);

      if (userModel == null) {
        // Create new user model if not found
        userModel = UserModel.newUser(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          photoUrl: user.photoURL,
        );
        await _databaseHelper.createOrUpdateUser(userModel);
        await _userDao.saveUser(userModel);
      }

      return userModel;
    } catch (e) {
      print('Error getting current user for verification: $e');
      rethrow;
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

      String userId = user.uid;

      // Delete user data from Firestore
      // await _databaseHelper.deleteUser(userId);

      // Delete from local storage
      await _userDao.deleteUser();

      // Delete Firebase Auth user (this should be done last)
      await user.delete();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // Refresh current user data
  Future<UserModel?> refreshUserData() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) return null;

      await user.reload();
      user = _firebaseAuth.currentUser; // Get refreshed user

      if (user == null) return null;

      // Get updated user data from Firestore
      UserModel? userModel = await _databaseHelper.getUser(user.uid);

      if (userModel != null) {
        // Update local storage with fresh data
        await _userDao.saveUser(userModel);
      }

      return userModel;
    } catch (e) {
      print('Error refreshing user data: $e');
      return null;
    }
  }

  // Check if user exists in Firestore
  Future<bool> userExistsInFirestore(String userId) async {
    try {
      return await _databaseHelper.userExists(userId);
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Reauthenticate user (needed for sensitive operations like account deletion)
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

      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      print('Error reauthenticating user: $e');
      rethrow;
    }
  }

  // Get user by ID (utility method)
  Future<UserModel?> getUserById(String userId) async {
    try {
      return await _databaseHelper.getUser(userId);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }
}
