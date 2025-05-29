import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/local/models/user_model.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../routes/routes.dart';
import '../../../utils/helpers/loading_helper.dart';

class AuthController extends GetxController {
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
    _disposeControllers();
    super.onClose();
  }

  void _disposeControllers() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    forgotPasswordEmailController.dispose();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      isLoading.value = true;

      // Listen to auth state changes
      _authService.authStateChanges.listen((User? user) {
        if (user != null) {
          _handleUserSignedIn(user);
        } else {
          _handleUserSignedOut();
        }
      });

      // Check current user
      await checkCurrentUser();
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      errorMessage.value = 'Failed to initialize authentication';
    } finally {
      isLoading.value = false;
    }
  }

  // Handle user signed in
  Future<void> _handleUserSignedIn(User user) async {
    try {
      // Create user model from Firebase user
      final userData = UserModel.newUser(
        id: user.uid,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );

      currentUser.value = userData;
      await _saveUserLocally(userData);
      isAuthenticated.value = true;
    } catch (e) {
      debugPrint('Error handling user sign in: $e');
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
      // Check Firebase Auth current user
      User? firebaseUser = _authService.currentUser;

      if (firebaseUser != null) {
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
      debugPrint('Error checking current user: $e');
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
        _showError('Please accept the Terms of Service and Privacy Policy');
        return false;
      }

      _setLoading(true, 'Creating your account...');

      UserModel user = await _authService.registerWithEmailPassword(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      currentUser.value = user;
      await _saveUserLocally(user);
      clearRegisterForm();

      _showSuccess(
        'Account Created',
        'Please check your email to verify your account',
      );

      Get.offAllNamed(AppRoutes.emailVerification);
      return true;
    } catch (e) {
      _handleError('Registration Failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login with email and password
  Future<bool> loginWithEmailPassword() async {
    try {
      if (!loginFormKey.currentState!.validate()) {
        return false;
      }

      _setLoading(true, 'Logging in...');

      UserModel user = await _authService.loginWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      // Check email verification
      if (!_authService.isEmailVerified) {
        currentUser.value = user;
        await _saveUserLocally(user);
        Get.offAllNamed(AppRoutes.emailVerification);
        return true;
      }

      clearLoginForm();
      Get.offAllNamed(AppRoutes.dashboard);
      return true;
    } catch (e) {
      _handleError('Login Failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login with Google
  Future<bool> loginWithGoogle() async {
    try {
      _setLoading(true, 'Logging in with Google...');

      UserModel user = await _authService.signInWithGoogle();

      currentUser.value = user;
      await _saveUserLocally(user);

      Get.offAllNamed(AppRoutes.dashboard);
      return true;
    } catch (e) {
      _handleError('Google Login Failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register with Google
  Future<bool> registerWithGoogle() async {
    if (!acceptedTerms.value) {
      _showError('Please accept the Terms of Service and Privacy Policy');
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

      // _setLoading(true, 'Sending reset email...');

      await _authService
          .resetPassword(forgotPasswordEmailController.text.trim());

      _showSuccess(
        'Email Sent',
        'Password reset email has been sent to ${forgotPasswordEmailController.text.trim()}',
      );

      clearForgotPasswordForm();
      return true;
    } catch (e) {
      _handleError('Reset Failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      _setLoading(true);

      await _authService.sendEmailVerification();

      _showSuccess(
        'Verification Email Sent',
        'A new verification email has been sent to your email address.',
      );
    } catch (e) {
      _handleError('Error', e);
    } finally {
      _setLoading(false);
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      bool isVerified = _authService.isEmailVerified;

      if (isVerified) {
        Get.offAllNamed(AppRoutes.dashboard);
        return true;
      }
      return false;
    } catch (e) {
      _handleError('Verification Check Failed', e);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? photoUrl,
    String? phone,
  }) async {
    try {
      if (currentUser.value == null) return false;

      _setLoading(true, 'Updating profile...');

      UserModel updatedUser = await _authService.updateUserProfile(
        currentUser: currentUser.value!,
        name: name,
        photoUrl: photoUrl,
        phone: phone,
      );

      currentUser.value = updatedUser;
      await _saveUserLocally(updatedUser);

      _showSuccess(
        'Profile Updated',
        'Your profile has been updated successfully',
      );

      return true;
    } catch (e) {
      _handleError('Update Failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true, 'Signing out...');

      await _authService.signOut();
      await _clearUserLocally();

      _resetState();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      debugPrint('Error signing out: $e');
      _showError('Failed to sign out completely');
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      if (currentUser.value == null) return false;

      _setLoading(true, 'Deleting account...');

      await _authService.deleteAccount();
      await _clearUserLocally();

      _resetState();

      _showSuccess(
        'Account Deleted',
        'Your account has been deleted successfully',
      );

      Get.offAllNamed(AppRoutes.login);
      return true;
    } catch (e) {
      _handleError('Delete Failed', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading, [String? message]) {
    isLoading.value = loading;
    if (loading && message != null) {
      LoadingHelper.show(message);
    } else if (!loading) {
      LoadingHelper.hide();
    }
  }

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void _showError(String message) {
    errorMessage.value = message;
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _handleError(String title, dynamic error) {
    String message = _getErrorMessage(error);
    errorMessage.value = message;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _resetState() {
    currentUser.value = null;
    isAuthenticated.value = false;
    errorMessage.value = '';
    clearAllForms();
  }

  // Toggle methods
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

  void clearAllForms() {
    clearLoginForm();
    clearRegisterForm();
    clearForgotPasswordForm();
  }

  // Local storage methods
  Future<void> _saveUserLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(userStorageKey, userJson);
      await prefs.setBool(isLoggedInKey, true);
    } catch (e) {
      debugPrint('Error saving user locally: $e');
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
      debugPrint('Error getting user from local storage: $e');
    }
    return null;
  }

  Future<void> _clearUserLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(userStorageKey);
      await prefs.setBool(isLoggedInKey, false);
    } catch (e) {
      debugPrint('Error clearing user data: $e');
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
  String _getErrorMessage(dynamic error) {
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
    } else if (error.toString().contains('network') ||
        error.toString().contains('12500')) {
      return 'Network error. Please check your internet connection and try again.';
    } else {
      return error.toString().isNotEmpty
          ? error.toString()
          : 'An unexpected error occurred. Please try again.';
    }
  }

  // Getters for UI
  bool get isUserLoggedIn => isAuthenticated.value && currentUser.value != null;
  bool get isEmailVerified => _authService.isEmailVerified;
  String get userDisplayName => currentUser.value?.name ?? 'User';
  String get userEmail => currentUser.value?.email ?? '';
  String get userPhotoUrl => currentUser.value?.photoUrl ?? '';
  String get userInitials => currentUser.value?.initials ?? 'U';
}
