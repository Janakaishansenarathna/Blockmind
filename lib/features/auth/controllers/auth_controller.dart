import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/local/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../routes/routes.dart';
import '../../../utils/helpers/loading_helper.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController forgotPasswordEmailController =
      TextEditingController();

  // Form keys
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> forgotPasswordFormKey = GlobalKey<FormState>();

  // Reactive variables
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxBool acceptedTerms = false.obs;
  RxBool obscurePassword = true.obs;
  RxBool obscureConfirmPassword = true.obs;
  RxBool isAuthenticated = false.obs;

  // Storage keys
  static const String userStorageKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    forgotPasswordEmailController.dispose();
    super.onClose();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      isLoading.value = true;

      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          _handleUserSignedIn(user);
        } else {
          _handleUserSignedOut();
        }
      });

      // Check current user
      await checkCurrentUser();
    } catch (e) {
      print('Error initializing auth: $e');
      errorMessage.value = 'Failed to initialize authentication';
    } finally {
      isLoading.value = false;
    }
  }

  // Handle user signed in
  Future<void> _handleUserSignedIn(User user) async {
    try {
      // Get user data from repository
      UserModel? userData = await _userRepository.getUserById(user.uid);

      if (userData != null) {
        // Update last login
        userData = userData.updateLastLogin();
        await _userRepository.updateUser(userData);
        currentUser.value = userData;
      } else {
        // Create new user if not found
        final newUser = UserModel.newUser(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          photoUrl: user.photoURL,
        );

        await _userRepository.createUser(newUser);
        currentUser.value = newUser;
      }

      // Save to local storage
      await _saveUserLocally(currentUser.value!);
      isAuthenticated.value = true;
    } catch (e) {
      print('Error handling user sign in: $e');
      errorMessage.value = 'Failed to load user data';
    }
  }

  // Handle user signed out
  void _handleUserSignedOut() {
    currentUser.value = null;
    isAuthenticated.value = false;
    _clearUserLocally();
  }

  // Check if user is already logged in
  Future<void> checkCurrentUser() async {
    try {
      // First check Firebase Auth
      User? firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // User is signed in to Firebase, get user data
        await _handleUserSignedIn(firebaseUser);
      } else {
        // Check local storage for offline data
        UserModel? localUser = await _getUserFromLocal();
        if (localUser != null) {
          currentUser.value = localUser;
          isAuthenticated.value = true;
        }
      }
    } catch (e) {
      print('Error checking current user: $e');
      errorMessage.value = 'Error checking authentication status';
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailPassword() async {
    try {
      if (!registerFormKey.currentState!.validate()) {
        return false;
      }

      if (!acceptedTerms.value) {
        errorMessage.value =
            'Please accept the Terms of Service and Privacy Policy';
        Get.snackbar(
          'Terms Required',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';
      LoadingHelper.show('Creating your account...');

      // Create Firebase user
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create user account');
      }

      // Update display name
      await userCredential.user!.updateDisplayName(nameController.text.trim());

      // Create user model
      final user = UserModel.newUser(
        id: userCredential.user!.uid,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        photoUrl: userCredential.user!.photoURL,
      );

      // Save to Firestore
      await _userRepository.createUser(user);

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Update current user
      currentUser.value = user;
      await _saveUserLocally(user);

      // Clear form
      clearRegisterForm();

      // Show success message
      Get.snackbar(
        'Account Created',
        'Please check your email to verify your account',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );

      // Navigate to email verification
      Get.offAllNamed(AppRoutes.emailVerification);
      return true;
    } catch (e) {
      errorMessage.value = _handleAuthError(e);
      Get.snackbar(
        'Registration Failed',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
      LoadingHelper.hide();
    }
  }

  // Login with email and password
  Future<bool> loginWithEmailPassword() async {
    try {
      if (!loginFormKey.currentState!.validate()) {
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';
      LoadingHelper.show('Logging in...');

      // Sign in with Firebase
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user == null) {
        throw Exception('Login failed');
      }

      // Check email verification
      if (!userCredential.user!.emailVerified) {
        // User exists but email not verified
        final user = UserModel.newUser(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'User',
          email: userCredential.user!.email ?? '',
          photoUrl: userCredential.user!.photoURL,
        );

        currentUser.value = user;
        await _saveUserLocally(user);

        Get.offAllNamed(AppRoutes.emailVerification);
        return true;
      }

      // User will be handled by auth state listener
      clearLoginForm();

      // Navigate to dashboard
      Get.offAllNamed(AppRoutes.dashboard);
      return true;
    } catch (e) {
      errorMessage.value = _handleAuthError(e);
      Get.snackbar(
        'Login Failed',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
      LoadingHelper.hide();
    }
  }

  // Login with Google
  Future<bool> loginWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      LoadingHelper.show('Logging in with Google...');

      // Sign out from previous sessions
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in flow
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Google sign in failed');
      }

      // User will be handled by auth state listener
      // Navigate to dashboard
      Get.offAllNamed(AppRoutes.dashboard);
      return true;
    } catch (e) {
      errorMessage.value = _handleAuthError(e);
      Get.snackbar(
        'Google Login Failed',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
      LoadingHelper.hide();
    }
  }

  // Register with Google
  Future<bool> registerWithGoogle() async {
    if (!acceptedTerms.value) {
      errorMessage.value =
          'Please accept the Terms of Service and Privacy Policy';
      Get.snackbar(
        'Terms Required',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return await loginWithGoogle();
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail() async {
    try {
      if (!forgotPasswordFormKey.currentState!.validate()) {
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';
      LoadingHelper.show('Sending reset email...');

      await _auth.sendPasswordResetEmail(
        email: forgotPasswordEmailController.text.trim(),
      );

      Get.snackbar(
        'Email Sent',
        'Password reset email has been sent to ${forgotPasswordEmailController.text.trim()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );

      clearForgotPasswordForm();
      return true;
    } catch (e) {
      errorMessage.value = _handleAuthError(e);
      Get.snackbar(
        'Reset Failed',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
      LoadingHelper.hide();
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      isLoading.value = true;

      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        Get.snackbar(
          'Verification Email Sent',
          'A new verification email has been sent to your email address.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      }
    } catch (e) {
      errorMessage.value = _handleAuthError(e);
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser; // Get updated user

        if (user != null && user.emailVerified) {
          // Email is verified, navigate to dashboard
          Get.offAllNamed(AppRoutes.dashboard);
          return true;
        }
      }
      return false;
    } catch (e) {
      errorMessage.value = _handleAuthError(e);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? photoUrl,
  }) async {
    try {
      if (currentUser.value == null) return false;

      isLoading.value = true;
      LoadingHelper.show('Updating profile...');

      // Update Firebase user profile
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        if (name != null) {
          await firebaseUser.updateDisplayName(name);
        }
        if (photoUrl != null) {
          await firebaseUser.updatePhotoURL(photoUrl);
        }
      }

      // Update user model
      UserModel updatedUser = currentUser.value!.copyWith(
        name: name,
        photoUrl: photoUrl,
      );

      // Update in repository
      await _userRepository.updateUser(updatedUser);

      // Update local user
      currentUser.value = updatedUser;
      await _saveUserLocally(updatedUser);

      Get.snackbar(
        'Profile Updated',
        'Your profile has been updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      errorMessage.value = _handleAuthError(e);
      Get.snackbar(
        'Update Failed',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
      LoadingHelper.hide();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      LoadingHelper.show('Signing out...');

      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('Google sign out error: $e');
      }

      // Clear local data
      await _clearUserLocally();

      // Reset state
      currentUser.value = null;
      isAuthenticated.value = false;
      errorMessage.value = '';

      // Clear all forms
      clearLoginForm();
      clearRegisterForm();
      clearForgotPasswordForm();

      // Navigate to login screen
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      print('Error signing out: $e');
      Get.snackbar(
        'Sign Out Error',
        'Failed to sign out completely',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      LoadingHelper.hide();
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      if (currentUser.value == null) return false;

      isLoading.value = true;
      LoadingHelper.show('Deleting account...');

      // Delete user data from Firestore
      await _userRepository.deleteUser(currentUser.value!.id);

      // Delete Firebase user
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.delete();
      }

      // Clear local data
      await _clearUserLocally();

      // Reset state
      currentUser.value = null;
      isAuthenticated.value = false;

      Get.snackbar(
        'Account Deleted',
        'Your account has been deleted successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to login screen
      Get.offAllNamed(AppRoutes.login);
      return true;
    } catch (e) {
      errorMessage.value = _handleAuthError(e);
      Get.snackbar(
        'Delete Failed',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
      LoadingHelper.hide();
    }
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  void toggleTermsAcceptance() {
    acceptedTerms.value = !acceptedTerms.value;
  }

  // Clear form methods
  void clearLoginForm() {
    emailController.clear();
    passwordController.clear();
    errorMessage.value = '';
  }

  void clearRegisterForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    acceptedTerms.value = false;
    errorMessage.value = '';
  }

  void clearForgotPasswordForm() {
    forgotPasswordEmailController.clear();
    errorMessage.value = '';
  }

  // Local storage methods
  Future<void> _saveUserLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(userStorageKey, userJson);
      await prefs.setBool(isLoggedInKey, true);
    } catch (e) {
      print('Error saving user locally: $e');
    }
  }

  Future<UserModel?> _getUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonString = prefs.getString(userStorageKey);

      if (userJsonString != null) {
        final userJson = jsonDecode(userJsonString) as Map<String, dynamic>;
        return UserModel.fromJson(userJson);
      }
    } catch (e) {
      print('Error getting user from local storage: $e');
    }
    return null;
  }

  Future<void> _clearUserLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(userStorageKey);
      await prefs.setBool(isLoggedInKey, false);
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  // Validation methods
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // Error handling
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Wrong password. Please try again.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'email-already-in-use':
          return 'The email is already in use by another account.';
        case 'weak-password':
          return 'The password is too weak. Please choose a stronger password.';
        case 'operation-not-allowed':
          return 'This sign-in method is not allowed.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in credentials.';
        case 'invalid-credential':
          return 'The credential is invalid or expired.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'email-not-verified':
          return 'Please verify your email before logging in.';
        case 'requires-recent-login':
          return 'Please sign in again to perform this action.';
        case 'provider-already-linked':
          return 'This account is already linked to another provider.';
        case 'credential-already-in-use':
          return 'This credential is already associated with a different account.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    } else if (error.toString().contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return error.toString().isNotEmpty
          ? error.toString()
          : 'An unexpected error occurred. Please try again.';
    }
  }

  // Getters for UI
  bool get isUserLoggedIn => isAuthenticated.value && currentUser.value != null;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
  String get userDisplayName => currentUser.value?.name ?? 'User';
  String get userEmail => currentUser.value?.email ?? '';
  String get userPhotoUrl => currentUser.value?.photoUrl ?? '';
  String get userInitials => currentUser.value?.initials ?? 'U';
}
