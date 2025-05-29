import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/local/models/user_model.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../data/repositories/usage_repository.dart';
import '../../../data/local/models/usage_log_model.dart';
import '../../../utils/helpers/loading_helper.dart';
import '../../auth/controllers/auth_controller.dart';

/// Production-ready ProfileController with comprehensive error handling,
/// logging, and state management for user profile operations
class ProfileController extends GetxController {
  // === CONSTANTS ===
  static const String _tag = 'ProfileController';
  static const String _settingsKey = 'profile_settings';
  static const int _maxImageSizeMB = 5;
  static const int _maxImageSizeBytes = _maxImageSizeMB * 1024 * 1024;
  static const Duration _snackbarDuration = Duration(seconds: 3);
  static const Duration _successSnackbarDuration = Duration(seconds: 2);

  // === DEPENDENCIES ===
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UsageRepository _usageRepository = UsageRepository();
  final ImagePicker _imagePicker = ImagePicker();

  /// Get AuthController instance with comprehensive error handling
  AuthController? get _authController {
    try {
      if (Get.isRegistered<AuthController>()) {
        final controller = Get.find<AuthController>();
        _log('AuthController found and retrieved successfully');
        return controller;
      } else {
        _log('AuthController not registered in GetX');
        return null;
      }
    } catch (e, stackTrace) {
      _logError('Failed to get AuthController', e, stackTrace);
      return null;
    }
  }

  // === REACTIVE STATE VARIABLES ===

  // User data state
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoadingStats = false.obs;
  final RxBool isUpdatingPhoto = false.obs;
  final RxString errorMessage = ''.obs;

  // Form controllers for profile editing
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> profileFormKey = GlobalKey<FormState>();

  // Usage statistics (reactive observables)
  final RxString totalUsageTime = '0h 0m'.obs;
  final RxString dailyAverageTime = '0h 0m'.obs;
  final RxString weeklyUsageTime = '0h 0m'.obs;
  final RxString monthlyUsageTime = '0h 0m'.obs;
  final RxInt totalAppsUsed = 0.obs;
  final RxInt screenPickups = 0.obs;
  final RxList<UsageLogModel> recentUsageLogs = <UsageLogModel>[].obs;
  final RxInt successfulBlocks = 0.obs;
  final RxInt currentStreak = 0.obs;

  // Profile settings (reactive observables)
  final RxBool notificationsEnabled = true.obs;
  final RxBool showBlockedApps = true.obs;
  final RxBool newUsageReport = true.obs;
  final RxBool scheduleNotifications = true.obs;
  final RxBool scheduleBeforeStart = true.obs;
  final RxBool scheduleAfterEnd = true.obs;
  final RxBool showBlockNotifications = false.obs;
  final RxBool quickModeAfterEnd = true.obs;
  final RxBool quickModeShowBlock = false.obs;
  final RxBool showActivityNotifications = true.obs;

  // Premium status
  final RxBool isPremiumUser = false.obs;
  final RxInt premiumDaysLeft = 0.obs;

  // === LIFECYCLE METHODS ===

  @override
  void onInit() {
    super.onInit();
    _log('ProfileController initializing...');
    _initializeProfile();
  }

  @override
  void onClose() {
    _log('ProfileController disposing resources...');
    _disposeControllers();
    super.onClose();
  }

  /// Dispose all text controllers to prevent memory leaks
  void _disposeControllers() {
    try {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      _log('Text controllers disposed successfully');
    } catch (e, stackTrace) {
      _logError('Error disposing controllers', e, stackTrace);
    }
  }

  // === INITIALIZATION METHODS ===

  /// Initialize all profile data in the correct order
  Future<void> _initializeProfile() async {
    try {
      _log('Starting profile initialization...');

      // Load data in parallel where possible, but user profile first
      await loadUserProfile();

      // Load other data in parallel
      await Future.wait([
        loadProfileSettings(),
        loadUsageStatistics(),
      ]);

      await _checkPremiumStatus();

      _log('Profile initialization completed successfully');
    } catch (e, stackTrace) {
      _logError('Failed to initialize profile', e, stackTrace);
      _handleInitializationError(e);
    }
  }

  /// Handle initialization errors gracefully
  void _handleInitializationError(dynamic error) {
    errorMessage.value = 'Failed to initialize profile: ${error.toString()}';

    _showErrorSnackbar(
      'Initialization Error',
      'Failed to load profile data. Some features may not work properly.',
    );
  }

  // === USER PROFILE METHODS ===

  /// Load user profile data with comprehensive error handling and fallback mechanisms
  Future<void> loadUserProfile() async {
    try {
      _log('Loading user profile...');
      isLoading.value = true;
      errorMessage.value = '';

      UserModel? user;

      // Priority 1: Try AuthController (most reliable source)
      if (_authController?.currentUser.value != null) {
        user = _authController!.currentUser.value;
        _log('User loaded from AuthController: ${user!.name}');
      }
      // Priority 2: Try auth service directly (fallback)
      else {
        _log('AuthController unavailable, trying auth service...');
        try {
          user = (_authService.currentUser!) as UserModel?;
          if (user != null) {
            _log('User loaded from auth service: ${user.name}');
          }
        } catch (serviceError, stackTrace) {
          _logError(
              'Auth service failed to load user', serviceError, stackTrace);
        }
      }

      if (user != null) {
        currentUser.value = user;
        _updateFormControllers();
        await _checkPremiumStatus();
        _log('User profile loaded successfully: ${user.name}');
      } else {
        throw Exception('No user found - user may not be authenticated');
      }
    } catch (e, stackTrace) {
      _logError('Failed to load user profile', e, stackTrace);
      errorMessage.value = 'Failed to load profile: ${e.toString()}';

      _showErrorSnackbar(
        'Profile Loading Error',
        'Unable to load profile data. Please check your connection and try again.',
      );
    } finally {
      isLoading.value = false;
      _log('Load user profile operation completed');
    }
  }

  /// Update form controllers with current user data, preventing infinite loops
  void _updateFormControllers() {
    if (currentUser.value == null) {
      _log('Cannot update form controllers - no current user');
      return;
    }

    try {
      final user = currentUser.value!;

      // Only update if different to avoid loops and unnecessary operations
      if (nameController.text != user.name) {
        nameController.text = user.name;
        _log('Name controller updated: ${user.name}');
      }

      if (emailController.text != user.email) {
        emailController.text = user.email;
        _log('Email controller updated: ${user.email}');
      }

      final userPhone = user.phone ?? '';
      if (phoneController.text != userPhone) {
        phoneController.text = userPhone;
        _log('Phone controller updated: $userPhone');
      }

      _log('Form controllers updated successfully');
    } catch (e, stackTrace) {
      _logError('Error updating form controllers', e, stackTrace);
    }
  }

  /// Check and update premium status
  Future<void> _checkPremiumStatus() async {
    try {
      if (currentUser.value != null) {
        final user = currentUser.value!;
        isPremiumUser.value = user.isPremiumActive;
        premiumDaysLeft.value = user.premiumDaysRemaining;

        _log(
            'Premium status updated - Active: ${isPremiumUser.value}, Days left: ${premiumDaysLeft.value}');
      } else {
        _log('Cannot check premium status - no current user');
      }
    } catch (e, stackTrace) {
      _logError('Error checking premium status', e, stackTrace);
      // Set safe defaults
      isPremiumUser.value = false;
      premiumDaysLeft.value = 0;
    }
  }

  // === PROFILE UPDATE METHODS ===

  /// Update user profile with comprehensive validation and error handling
  /// Returns true if successful, false otherwise
  Future<bool> updateProfile({bool showSuccessMessage = true}) async {
    try {
      _log('=== STARTING PROFILE UPDATE ===');
      _debugFormState();

      // Pre-validation checks
      if (!_validatePreConditions()) {
        return false;
      }

      // Form validation
      final isFormValid = profileFormKey.currentState?.validate() ?? false;
      _log('Form validation result: $isFormValid');

      if (!isFormValid) {
        _log('Form validation failed - aborting update');
        if (showSuccessMessage) {
          _showErrorSnackbar(
              'Validation Error', 'Please fix the errors in the form');
        }
        return false;
      }

      // Check for actual changes
      final changeInfo = _analyzeChanges();
      if (!changeInfo.hasChanges) {
        _log('No changes detected - operation completed');
        if (showSuccessMessage) {
          _showInfoSnackbar('No Changes', 'No changes detected to save');
        }
        return true;
      }

      // Start update process
      _setLoadingState(true, 'Updating profile...');
      _log(
          'Starting profile update process with changes: ${changeInfo.description}');

      // Perform the update
      final updatedUser = await _performProfileUpdate(changeInfo);

      if (updatedUser != null) {
        // Update local state
        await _updateLocalState(updatedUser);

        _log('Profile update completed successfully');

        if (showSuccessMessage) {
          _showSuccessSnackbar('Success', 'Profile updated successfully');
        }

        return true;
      } else {
        throw Exception('Profile update returned null user');
      }
    } catch (e, stackTrace) {
      _logError('Profile update failed', e, stackTrace);
      errorMessage.value = 'Failed to update profile: ${e.toString()}';

      if (showSuccessMessage) {
        _showErrorSnackbar(
            'Update Error', 'Failed to update profile. Please try again.');
      }
      return false;
    } finally {
      _setLoadingState(false);
      _log('=== PROFILE UPDATE COMPLETED ===');
    }
  }

  /// Validate pre-conditions for profile update
  bool _validatePreConditions() {
    if (currentUser.value == null) {
      _log('Pre-validation failed: No user data available');
      errorMessage.value = 'No user data available';
      return false;
    }
    return true;
  }

  /// Analyze what changes need to be made
  ProfileChangeInfo _analyzeChanges() {
    final user = currentUser.value!;
    final newName = nameController.text.trim();
    final newPhone = phoneController.text.trim();
    final currentName = user.name;
    final currentPhone = user.phone ?? '';

    final hasNameChange = newName != currentName;
    final hasPhoneChange = newPhone != currentPhone;

    _log('Change analysis:');
    _log('  Name change: $hasNameChange ("$currentName" -> "$newName")');
    _log('  Phone change: $hasPhoneChange ("$currentPhone" -> "$newPhone")');

    return ProfileChangeInfo(
      hasNameChange: hasNameChange,
      hasPhoneChange: hasPhoneChange,
      newName: hasNameChange ? newName : null,
      newPhone: hasPhoneChange ? newPhone : null,
    );
  }

  /// Perform the actual profile update
  Future<UserModel?> _performProfileUpdate(ProfileChangeInfo changeInfo) async {
    try {
      UserModel updatedUser;

      // Method 1: Try AuthController first (preferred)
      if (_authController != null) {
        _log('Updating profile through AuthController...');
        final success = await _authController!.updateUserProfile(
          name: changeInfo.newName,
          phone: changeInfo.newPhone,
        );

        if (success && _authController!.currentUser.value != null) {
          updatedUser = _authController!.currentUser.value!;
          _log('AuthController update successful');
        } else {
          throw Exception(
              'AuthController update returned success=false or null user');
        }
      }
      // Method 2: Direct update through auth service (fallback)
      else {
        _log('Updating profile through auth service (fallback)...');
        updatedUser = await _authService.updateUserProfile(
          currentUser: currentUser.value!,
          name: changeInfo.newName,
          phone: changeInfo.newPhone,
        );
        _log('Auth service update successful');
      }

      return updatedUser;
    } catch (e, stackTrace) {
      _logError('Profile update service call failed', e, stackTrace);
      rethrow;
    }
  }

  /// Update local state after successful profile update
  Future<void> _updateLocalState(UserModel updatedUser) async {
    // Update local user state
    currentUser.value = updatedUser;

    // Sync with AuthController if available
    if (_authController != null) {
      _authController!.currentUser.value = updatedUser;
      _log('AuthController state synchronized');
    }

    // Update form controllers to reflect saved state
    _updateFormControllers();

    // Refresh premium status
    await _checkPremiumStatus();

    _log('Local state updated successfully');
  }

  // === PROFILE PICTURE METHODS ===

  /// Update profile picture with comprehensive validation and error handling
  Future<bool> updateProfilePicture({bool showSuccessMessage = true}) async {
    try {
      _log('=== STARTING PROFILE PICTURE UPDATE ===');

      // Show image source selection dialog
      final imageSource = await _showImageSourceDialog();
      if (imageSource == null) {
        _log('Image source selection cancelled by user');
        return false;
      }

      // Pick image with validation
      final imagePath = await _pickAndValidateImage(imageSource);
      if (imagePath == null) {
        return false;
      }

      // Update profile picture
      _setPhotoLoadingState(true, 'Updating profile picture...');
      _log('Starting profile picture update with image: $imagePath');

      final updatedUser = await _performProfilePictureUpdate(imagePath);

      if (updatedUser != null) {
        await _updateLocalStateAfterPhotoUpdate(updatedUser);

        _log('Profile picture update completed successfully');

        if (showSuccessMessage) {
          _showSuccessSnackbar(
              'Success', 'Profile picture updated successfully');
        }

        return true;
      } else {
        throw Exception('Profile picture update returned null user');
      }
    } catch (e, stackTrace) {
      _logError('Profile picture update failed', e, stackTrace);

      if (showSuccessMessage) {
        _showErrorSnackbar('Photo Update Error',
            'Failed to update profile picture: ${e.toString()}');
      }
      return false;
    } finally {
      _setPhotoLoadingState(false);
      _log('=== PROFILE PICTURE UPDATE COMPLETED ===');
    }
  }

  /// Pick and validate image file
  Future<String?> _pickAndValidateImage(ImageSource source) async {
    try {
      _log('Picking image from ${source.name}...');

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image == null) {
        _log('No image selected by user');
        return null;
      }

      final imagePath = image.path;
      _log('Image selected: $imagePath');

      // Validate file exists
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Selected image file not found at path: $imagePath');
      }

      // Validate file size
      final fileSizeInBytes = await imageFile.length();
      _log(
          'Image file size: ${(fileSizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB');

      if (fileSizeInBytes > _maxImageSizeBytes) {
        throw Exception(
            'Image file is too large (${(fileSizeInBytes / 1024 / 1024).toStringAsFixed(1)} MB). Maximum allowed size is $_maxImageSizeMB MB');
      }

      _log('Image validation passed');
      return imagePath;
    } catch (e, stackTrace) {
      _logError('Image picking/validation failed', e, stackTrace);
      rethrow;
    }
  }

  /// Perform the actual profile picture update
  Future<UserModel?> _performProfilePictureUpdate(String imagePath) async {
    try {
      UserModel updatedUser;

      // Method 1: Try AuthController first (preferred)
      if (_authController != null) {
        _log('Updating profile picture through AuthController...');
        final success =
            await _authController!.updateUserProfile(photoUrl: imagePath);

        if (success && _authController!.currentUser.value != null) {
          updatedUser = _authController!.currentUser.value!;
          _log('AuthController photo update successful');
        } else {
          throw Exception('AuthController photo update failed');
        }
      }
      // Method 2: Direct update through auth service (fallback)
      else {
        _log('Updating profile picture through auth service (fallback)...');
        updatedUser = await _authService.updateUserProfile(
          currentUser: currentUser.value!,
          photoUrl: imagePath,
        );
        _log('Auth service photo update successful');
      }

      return updatedUser;
    } catch (e, stackTrace) {
      _logError('Profile picture update service call failed', e, stackTrace);
      rethrow;
    }
  }

  /// Update local state after successful photo update
  Future<void> _updateLocalStateAfterPhotoUpdate(UserModel updatedUser) async {
    // Update local user state
    currentUser.value = updatedUser;

    // Sync with AuthController if available
    if (_authController != null) {
      _authController!.currentUser.value = updatedUser;
      _log('AuthController state synchronized after photo update');
    }

    // Force UI refresh to show new photo
    currentUser.refresh();

    _log('Local state updated after photo update');
  }

  /// Show dialog for image source selection
  Future<ImageSource?> _showImageSourceDialog() async {
    try {
      final result = await Get.dialog<String>(
        AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Select Image Source',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white70),
                title:
                    const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () => Get.back(result: 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white70),
                title: const Text('Gallery',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Get.back(result: 'gallery'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );

      if (result == 'camera') {
        return ImageSource.camera;
      } else if (result == 'gallery') {
        return ImageSource.gallery;
      }
      return null;
    } catch (e, stackTrace) {
      _logError('Error showing image source dialog', e, stackTrace);
      return null;
    }
  }

  // === SETTINGS METHODS ===

  /// Load profile settings from local storage
  Future<void> loadProfileSettings() async {
    try {
      _log('Loading profile settings...');
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
        _applySettings(settings);
        _log('Profile settings loaded successfully');
      } else {
        _log('No saved profile settings found, using defaults');
      }
    } catch (e, stackTrace) {
      _logError('Error loading profile settings', e, stackTrace);
      // Continue with default settings
    }
  }

  /// Apply settings from loaded data
  void _applySettings(Map<String, dynamic> settings) {
    notificationsEnabled.value = settings['notificationsEnabled'] ?? true;
    showBlockedApps.value = settings['showBlockedApps'] ?? true;
    newUsageReport.value = settings['newUsageReport'] ?? true;
    scheduleNotifications.value = settings['scheduleNotifications'] ?? true;
    scheduleBeforeStart.value = settings['scheduleBeforeStart'] ?? true;
    scheduleAfterEnd.value = settings['scheduleAfterEnd'] ?? true;
    showBlockNotifications.value = settings['showBlockNotifications'] ?? false;
    quickModeAfterEnd.value = settings['quickModeAfterEnd'] ?? true;
    quickModeShowBlock.value = settings['quickModeShowBlock'] ?? false;
    showActivityNotifications.value =
        settings['showActivityNotifications'] ?? true;
  }

  /// Save profile settings to local storage
  Future<void> saveProfileSettings() async {
    try {
      _log('Saving profile settings...');
      final prefs = await SharedPreferences.getInstance();
      final settings = _buildSettingsMap();

      await prefs.setString(_settingsKey, jsonEncode(settings));
      _log('Profile settings saved successfully');
    } catch (e, stackTrace) {
      _logError('Error saving profile settings', e, stackTrace);
      rethrow;
    }
  }

  /// Build settings map for saving
  Map<String, dynamic> _buildSettingsMap() {
    return {
      'notificationsEnabled': notificationsEnabled.value,
      'showBlockedApps': showBlockedApps.value,
      'newUsageReport': newUsageReport.value,
      'scheduleNotifications': scheduleNotifications.value,
      'scheduleBeforeStart': scheduleBeforeStart.value,
      'scheduleAfterEnd': scheduleAfterEnd.value,
      'showBlockNotifications': showBlockNotifications.value,
      'quickModeAfterEnd': quickModeAfterEnd.value,
      'quickModeShowBlock': quickModeShowBlock.value,
      'showActivityNotifications': showActivityNotifications.value,
    };
  }

  // === USAGE STATISTICS METHODS ===

  /// Load usage statistics with fallback to mock data
  Future<void> loadUsageStatistics() async {
    try {
      _log('Loading usage statistics...');
      isLoadingStats.value = true;

      if (currentUser.value == null) {
        _log('No current user - using mock usage data');
        _setMockUsageData();
        return;
      }

      try {
        await _loadRealUsageStats();
        _log('Real usage statistics loaded successfully');
      } catch (e, stackTrace) {
        _logError(
            'Failed to load real usage stats, using mock data', e, stackTrace);
        _setMockUsageData();
      }
    } catch (e, stackTrace) {
      _logError('Error loading usage statistics', e, stackTrace);
      _setMockUsageData();
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// Load real usage statistics from repository
  Future<void> _loadRealUsageStats() async {
    final userId = currentUser.value!.id;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get today's usage
    final todayUsage = await _usageRepository.getTotalUsageForPeriod(
      userId,
      startOfDay,
      endOfDay,
    );
    totalUsageTime.value = _formatDuration(todayUsage);

    // Get weekly usage
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final weekStart =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final weeklyUsage = await _usageRepository.getTotalUsageForPeriod(
      userId,
      weekStart,
      today,
    );
    weeklyUsageTime.value = _formatDuration(weeklyUsage);

    // Calculate daily average
    final daysInWeek = today.weekday;
    if (daysInWeek > 0) {
      final avgDaily =
          Duration(milliseconds: weeklyUsage.inMilliseconds ~/ daysInWeek);
      dailyAverageTime.value = _formatDuration(avgDaily);
    }

    // Get monthly usage
    final startOfMonth = DateTime(today.year, today.month, 1);
    final monthlyUsage = await _usageRepository.getTotalUsageForPeriod(
      userId,
      startOfMonth,
      today,
    );
    monthlyUsageTime.value = _formatDuration(monthlyUsage);

    // Get additional stats
    final logs = await _usageRepository.getUsageLogsForPeriod(
      userId,
      startOfDay,
      endOfDay,
      limit: 10,
    );
    recentUsageLogs.value = logs;
    totalAppsUsed.value = logs.map((log) => log.appPackageName).toSet().length;

    screenPickups.value = await _usageRepository.getScreenPickupsCount(
      userId,
      startOfDay,
      endOfDay,
    );

    // Get user stats
    final user = currentUser.value!;
    successfulBlocks.value = user.successfulBlocks;
    currentStreak.value = user.currentStreak;

    _log(
        'Usage statistics loaded - Today: ${totalUsageTime.value}, Weekly: ${weeklyUsageTime.value}');
  }

  /// Set mock usage data for demo/fallback purposes
  void _setMockUsageData() {
    totalUsageTime.value = '6h 30m';
    dailyAverageTime.value = '7h 15m';
    weeklyUsageTime.value = '42h 45m';
    monthlyUsageTime.value = '180h 30m';
    totalAppsUsed.value = 12;
    screenPickups.value = 67;
    successfulBlocks.value = 18;
    currentStreak.value = 4;

    _log('Mock usage data set');
  }

  // === ACCOUNT MANAGEMENT METHODS ===

  /// Sign out user with confirmation dialog
  Future<void> signOut() async {
    try {
      _log('Initiating sign out process...');

      final confirmed = await _showConfirmationDialog(
        title: 'Sign Out',
        message: 'Are you sure you want to sign out?',
        confirmText: 'Sign Out',
        confirmColor: Colors.red,
      );

      if (!confirmed) {
        _log('Sign out cancelled by user');
        return;
      }

      LoadingHelper.show('Signing out...');

      try {
        // Sign out through AuthController if available
        if (_authController != null) {
          _log('Signing out through AuthController...');
          await _authController!.signOut();
        } else {
          _log('Signing out through auth service...');
          await _authService.signOut();

          // Clear local settings
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_settingsKey);

          // Clear local state
          currentUser.value = null;

          // Navigate to login
          Get.offAllNamed('/login');
        }

        _log('Sign out completed successfully');
      } catch (e, stackTrace) {
        _logError('Sign out process failed', e, stackTrace);
        rethrow;
      }
    } catch (e, stackTrace) {
      _logError('Sign out failed', e, stackTrace);
      _showErrorSnackbar(
          'Sign Out Error', 'Failed to sign out: ${e.toString()}');
    } finally {
      LoadingHelper.hide();
    }
  }

  /// Delete account with double confirmation
  Future<void> deleteAccount() async {
    try {
      _log('Initiating account deletion process...');

      final confirmed = await _showConfirmationDialog(
        title: 'Delete Account',
        message:
            'Are you sure you want to delete your account? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        titleColor: Colors.red,
      );

      if (!confirmed) {
        _log('Account deletion cancelled by user');
        return;
      }

      LoadingHelper.show('Deleting account...');

      try {
        bool success = false;

        if (_authController != null) {
          _log('Deleting account through AuthController...');
          success = await _authController!.deleteAccount();
        } else {
          _log('Deleting account manually...');
          // Manual deletion process
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          currentUser.value = null;
          success = true;
          Get.offAllNamed('/login');
        }

        if (success) {
          _log('Account deletion completed successfully');
        } else {
          throw Exception('Account deletion returned false');
        }
      } catch (e, stackTrace) {
        _logError('Account deletion process failed', e, stackTrace);
        rethrow;
      }
    } catch (e, stackTrace) {
      _logError('Account deletion failed', e, stackTrace);
      _showErrorSnackbar(
          'Deletion Error', 'Failed to delete account. Please try again.');
    } finally {
      LoadingHelper.hide();
    }
  }

  // === NOTIFICATION SETTINGS METHODS ===

  /// Update notification settings and save to storage
  Future<void> updateNotificationSettings() async {
    try {
      _log('Updating notification settings...');
      await saveProfileSettings();
      _showSuccessSnackbar('Success', 'Notification settings updated');
    } catch (e, stackTrace) {
      _logError('Failed to update notification settings', e, stackTrace);
      _showErrorSnackbar(
          'Settings Error', 'Failed to update settings: ${e.toString()}');
    }
  }

  // === UTILITY METHODS ===

  /// Refresh all profile data
  Future<void> refreshProfile() async {
    try {
      _log('Refreshing all profile data...');
      await Future.wait([
        loadUserProfile(),
        loadUsageStatistics(),
        loadProfileSettings(),
      ]);
      _log('Profile refresh completed successfully');
    } catch (e, stackTrace) {
      _logError('Profile refresh failed', e, stackTrace);
      _showErrorSnackbar('Refresh Error', 'Failed to refresh profile data');
    }
  }

  /// Get user initials for avatar display
  String getUserInitials() {
    if (currentUser.value?.name != null && currentUser.value!.name.isNotEmpty) {
      return currentUser.value!.initials;
    }
    return 'U';
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '0m';
    }
  }

  // === VALIDATION METHODS ===

  /// Validate name input
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (trimmedValue.length > 50) {
      return 'Name must be less than 50 characters';
    }

    // Check for valid characters (letters, spaces, common punctuation)
    if (!RegExp(r"^[a-zA-Z\s\-\'\.]+$").hasMatch(trimmedValue)) {
      return 'Name contains invalid characters';
    }

    return null;
  }

  /// Validate email input
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Validate phone input (optional field)
  String? validatePhone(String? value) {
    // Phone is optional, so empty is OK
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final phone = value.trim();

    // Remove common formatting characters
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Check length (10-15 digits is reasonable for most countries)
    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      return 'Phone number must be 10-15 digits';
    }

    // Check if contains only digits (after cleaning)
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return 'Phone number contains invalid characters';
    }

    return null;
  }

  // === GETTERS FOR UI ===

  bool get hasUserData => currentUser.value != null;
  String get userName => currentUser.value?.name ?? 'User';
  String get userEmail => currentUser.value?.email ?? '';
  String get userPhone => currentUser.value?.phone ?? '';
  String get userPhotoUrl => currentUser.value?.photoUrl ?? '';
  bool get isPremium => isPremiumUser.value;
  int get premiumDays => premiumDaysLeft.value;

  /// Check if there are unsaved profile changes
  bool hasProfileChanges() {
    if (currentUser.value == null) return false;

    final user = currentUser.value!;
    final nameChanged = nameController.text.trim() != user.name;
    final phoneChanged = phoneController.text.trim() != (user.phone ?? '');

    return nameChanged || phoneChanged;
  }

  // === TOGGLE METHODS FOR SETTINGS ===

  void toggleNotifications() {
    notificationsEnabled.toggle();
    updateNotificationSettings();
  }

  void toggleShowBlockedApps() {
    showBlockedApps.toggle();
    updateNotificationSettings();
  }

  void toggleNewUsageReport() {
    newUsageReport.toggle();
    updateNotificationSettings();
  }

  void toggleScheduleBeforeStart() {
    scheduleBeforeStart.toggle();
    updateNotificationSettings();
  }

  void toggleScheduleAfterEnd() {
    scheduleAfterEnd.toggle();
    updateNotificationSettings();
  }

  void toggleShowBlockNotifications() {
    showBlockNotifications.toggle();
    updateNotificationSettings();
  }

  void toggleQuickModeAfterEnd() {
    quickModeAfterEnd.toggle();
    updateNotificationSettings();
  }

  void toggleQuickModeShowBlock() {
    quickModeShowBlock.toggle();
    updateNotificationSettings();
  }

  void toggleShowActivityNotifications() {
    showActivityNotifications.toggle();
    updateNotificationSettings();
  }

  // === PRIVATE HELPER METHODS ===

  /// Set loading state and show/hide loading dialog
  void _setLoadingState(bool loading, [String? message]) {
    isLoading.value = loading;
    if (loading && message != null) {
      LoadingHelper.show(message);
    } else if (!loading) {
      LoadingHelper.hide();
    }
  }

  /// Set photo loading state
  void _setPhotoLoadingState(bool loading, [String? message]) {
    isUpdatingPhoto.value = loading;
    if (loading && message != null) {
      LoadingHelper.show(message);
    } else if (!loading) {
      LoadingHelper.hide();
    }
  }

  /// Show confirmation dialog
  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    Color? confirmColor,
    Color? titleColor,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          title,
          style: TextStyle(color: titleColor ?? Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? Colors.blue,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show error snackbar
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: _snackbarDuration,
    );
  }

  /// Show success snackbar
  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: _successSnackbarDuration,
    );
  }

  /// Show info snackbar
  void _showInfoSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: _successSnackbarDuration,
    );
  }

  /// Debug form state for troubleshooting
  void _debugFormState() {
    _log('=== FORM STATE DEBUG ===');
    _log('Form key valid: ${profileFormKey.currentState?.validate() ?? false}');
    _log('Current user: ${currentUser.value?.name}');
    _log('Name controller: "${nameController.text}"');
    _log('Phone controller: "${phoneController.text}"');
    _log(
        'Has name changes: ${nameController.text.trim() != (currentUser.value?.name ?? "")}');
    _log(
        'Has phone changes: ${phoneController.text.trim() != (currentUser.value?.phone ?? "")}');
    _log('Name validation: ${validateName(nameController.text)}');
    _log('Phone validation: ${validatePhone(phoneController.text)}');
    _log('Is loading: ${isLoading.value}');
    _log('==========================');
  }

  /// Log information messages
  void _log(String message) {
    print('[$_tag] $message');
  }

  /// Log error messages with stack trace
  void _logError(String message, dynamic error, StackTrace? stackTrace) {
    print('[$_tag] ERROR: $message');
    print('[$_tag] Error details: $error');
    if (stackTrace != null) {
      print('[$_tag] Stack trace: $stackTrace');
    }
  }
}

/// Helper class to analyze profile changes
class ProfileChangeInfo {
  final bool hasNameChange;
  final bool hasPhoneChange;
  final String? newName;
  final String? newPhone;

  ProfileChangeInfo({
    required this.hasNameChange,
    required this.hasPhoneChange,
    this.newName,
    this.newPhone,
  });

  bool get hasChanges => hasNameChange || hasPhoneChange;

  String get description {
    final changes = <String>[];
    if (hasNameChange) changes.add('name');
    if (hasPhoneChange) changes.add('phone');
    return changes.join(', ');
  }
}
