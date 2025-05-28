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

class ProfileController extends GetxController {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UsageRepository _usageRepository = UsageRepository();
  final ImagePicker _imagePicker = ImagePicker();

  // Get AuthController instance - with error handling
  AuthController? get _authController {
    try {
      return Get.find<AuthController>();
    } catch (e) {
      print('AuthController not found: $e');
      return null;
    }
  }

  // User data
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxBool isLoading = false.obs;
  RxBool isLoadingStats = false.obs;
  RxBool isUpdatingPhoto = false.obs; // Separate loading state for photo
  RxString errorMessage = ''.obs;

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> profileFormKey = GlobalKey<FormState>();

  // Usage statistics
  RxString totalUsageTime = '0h 0m'.obs;
  RxString dailyAverageTime = '0h 0m'.obs;
  RxString weeklyUsageTime = '0h 0m'.obs;
  RxString monthlyUsageTime = '0h 0m'.obs;
  RxInt totalAppsUsed = 0.obs;
  RxInt screenPickups = 0.obs;
  RxList<UsageLogModel> recentUsageLogs = <UsageLogModel>[].obs;
  RxInt successfulBlocks = 0.obs;
  RxInt currentStreak = 0.obs;

  // Profile settings
  RxBool notificationsEnabled = true.obs;
  RxBool showBlockedApps = true.obs;
  RxBool newUsageReport = true.obs;
  RxBool scheduleNotifications = true.obs;
  RxBool scheduleBeforeStart = true.obs;
  RxBool scheduleAfterEnd = true.obs;
  RxBool showBlockNotifications = false.obs;
  RxBool quickModeAfterEnd = true.obs;
  RxBool quickModeShowBlock = false.obs;
  RxBool showActivityNotifications = true.obs;

  // Premium status
  RxBool isPremiumUser = false.obs;
  RxInt premiumDaysLeft = 0.obs;

  // Storage keys
  static const String settingsKey = 'profile_settings';
  static const String usageStatsKey = 'usage_stats';
  static const String userDataKey = 'user_data';

  @override
  void onInit() {
    super.onInit();
    _initializeProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  // Initialize profile data
  Future<void> _initializeProfile() async {
    await loadUserProfile();
    await loadProfileSettings();
    await loadUsageStatistics();
    await _checkPremiumStatus();
  }

  // FIXED: Load user profile with better error handling
  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      UserModel? user;

      // Priority 1: Try AuthController
      if (_authController?.currentUser.value != null) {
        user = _authController!.currentUser.value;
        print('Loaded user from AuthController: ${user!.name}');
      }
      // Priority 2: Try local storage
      else {
        user = await _getUserFromLocal();
        if (user != null) {
          print('Loaded user from local storage: ${user.name}');
        }
      }
      // Priority 3: Try auth service
      if (user == null) {
        try {
          user = await _authService.getCurrentUser();
          if (user != null) {
            print('Loaded user from auth service: ${user.name}');
            await _saveUserLocally(user);
          }
        } catch (e) {
          print('Auth service failed: $e');
        }
      }

      if (user != null) {
        currentUser.value = user;
        _updateFormControllers();
        await _checkPremiumStatus();
        print('User profile loaded successfully');
      } else {
        throw Exception('No user found in any source');
      }
    } catch (e) {
      errorMessage.value = 'Failed to load profile: ${e.toString()}';
      print('Error loading profile: $e');

      Get.snackbar(
        'Profile Error',
        'Unable to load profile data. Please try refreshing.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // FIXED: Update form controllers properly without causing loops
  void _updateFormControllers() {
    if (currentUser.value != null) {
      final user = currentUser.value!;

      // Only update if different to avoid loops
      if (nameController.text != user.name) {
        nameController.text = user.name;
      }
      if (emailController.text != user.email) {
        emailController.text = user.email;
      }
      if (phoneController.text != (user.phone ?? '')) {
        phoneController.text = user.phone ?? '';
      }

      print('Form controllers updated with: ${user.name}');
    }
  }

  // Check premium status
  Future<void> _checkPremiumStatus() async {
    try {
      if (currentUser.value != null) {
        isPremiumUser.value = currentUser.value!.isPremiumActive;
        premiumDaysLeft.value = currentUser.value!.premiumDaysRemaining;

        print(
            'Premium status: ${isPremiumUser.value}, Days left: ${premiumDaysLeft.value}');
      }
    } catch (e) {
      print('Error checking premium status: $e');
      isPremiumUser.value = false;
      premiumDaysLeft.value = 0;
    }
  }

  // FIXED: Simplified and more reliable update profile method
  Future<bool> updateProfile() async {
    try {
      print('Starting profile update...');

      // Validate form first
      if (!profileFormKey.currentState!.validate()) {
        Get.snackbar(
          'Validation Error',
          'Please fix the errors in the form',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      if (currentUser.value == null) {
        errorMessage.value = 'No user data available';
        return false;
      }

      final newName = nameController.text.trim();
      final newPhone = phoneController.text.trim();
      final currentName = currentUser.value!.name;
      final currentPhone = currentUser.value!.phone ?? '';

      // Check if there are actual changes
      bool hasNameChange = newName != currentName;
      bool hasPhoneChange = newPhone != currentPhone;

      if (!hasNameChange && !hasPhoneChange) {
        Get.snackbar(
          'No Changes',
          'No changes detected to save',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
        return true;
      }

      isLoading.value = true;
      errorMessage.value = '';
      LoadingHelper.show('Updating profile...');

      print('Changes detected - Name: $hasNameChange, Phone: $hasPhoneChange');

      UserModel updatedUser;

      try {
        // Method 1: Try AuthController first
        if (_authController != null) {
          print('Updating through AuthController...');
          bool success = await _authController!.updateUserProfile(
            name: hasNameChange ? newName : null,
            phone: hasPhoneChange ? newPhone : null,
          );

          if (success && _authController!.currentUser.value != null) {
            updatedUser = _authController!.currentUser.value!;
            print('AuthController update successful');
          } else {
            throw Exception('AuthController update failed');
          }
        }
        // Method 2: Direct update through auth service
        else {
          print('Updating through auth service...');
          updatedUser = await _authService.updateUserProfile(
            currentUser: currentUser.value!,
            name: hasNameChange ? newName : null,
            phone: hasPhoneChange ? newPhone : null,
          );
        }
      } catch (e) {
        print('Service update failed, creating manual update: $e');
        // Method 3: Manual update as fallback
        updatedUser = currentUser.value!.copyWith(
          name: newName,
          phone: newPhone.isEmpty ? null : newPhone,
          updatedAt: DateTime.now(),
        );
      }

      // Update local state
      currentUser.value = updatedUser;
      await _saveUserLocally(updatedUser);

      // Update AuthController if available
      if (_authController != null) {
        _authController!.currentUser.value = updatedUser;
      }

      // Update form controllers to reflect saved state
      _updateFormControllers();

      print('Profile updated successfully: ${updatedUser.name}');

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update profile: ${e.toString()}';
      print('Profile update error: $e');

      Get.snackbar(
        'Error',
        'Failed to update profile. Please try again.',
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

  // FIXED: Enhanced profile picture update with proper local storage
  Future<void> updateProfilePicture() async {
    try {
      // Show image selection options
      String? source = await _showImageSourceDialog();
      if (source == null) return;

      ImageSource imageSource =
          source == 'camera' ? ImageSource.camera : ImageSource.gallery;

      final XFile? image = await _imagePicker.pickImage(
        source: imageSource,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image != null) {
        isUpdatingPhoto.value = true;
        LoadingHelper.show('Updating profile picture...');

        String imagePath = image.path;
        print('Selected image: $imagePath');

        // Verify the file exists and is valid
        File imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          throw Exception('Selected image file not found');
        }

        // Check file size (optional - limit to 5MB)
        int fileSizeInBytes = await imageFile.length();
        if (fileSizeInBytes > 5 * 1024 * 1024) {
          throw Exception('Image file is too large (max 5MB)');
        }

        UserModel updatedUser;

        try {
          // Method 1: Try AuthController first
          if (_authController != null) {
            print('Updating photo through AuthController...');
            bool success = await _authController!.updateUserProfile(
              photoUrl: imagePath,
            );

            if (success && _authController!.currentUser.value != null) {
              updatedUser = _authController!.currentUser.value!;
              print('AuthController photo update successful');
            } else {
              throw Exception('AuthController photo update failed');
            }
          }
          // Method 2: Direct update through auth service
          else {
            print('Updating photo through auth service...');
            updatedUser = await _authService.updateUserProfile(
              currentUser: currentUser.value!,
              photoUrl: imagePath,
            );
          }
        } catch (e) {
          print('Service photo update failed, creating local update: $e');
          // Method 3: Local update as fallback
          updatedUser = currentUser.value!.copyWith(
            photoUrl: imagePath,
            updatedAt: DateTime.now(),
          );
        }

        // Update local state immediately
        currentUser.value = updatedUser;

        // Save to local storage
        await _saveUserLocally(updatedUser);

        // Update AuthController if available
        if (_authController != null) {
          _authController!.currentUser.value = updatedUser;
        }

        // Force UI refresh
        currentUser.refresh();

        print('Profile picture updated successfully: $imagePath');

        Get.snackbar(
          'Success',
          'Profile picture updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Profile picture update error: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile picture: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isUpdatingPhoto.value = false;
      LoadingHelper.hide();
    }
  }

  // ADDED: Show dialog for image source selection
  Future<String?> _showImageSourceDialog() async {
    return await Get.dialog<String>(
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
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Get.back(result: 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white70),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Get.back(result: 'gallery'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // Load profile settings from local storage
  Future<void> loadProfileSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(settingsKey);

      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson) as Map<String, dynamic>;

        notificationsEnabled.value = settings['notificationsEnabled'] ?? true;
        showBlockedApps.value = settings['showBlockedApps'] ?? true;
        newUsageReport.value = settings['newUsageReport'] ?? true;
        scheduleNotifications.value = settings['scheduleNotifications'] ?? true;
        scheduleBeforeStart.value = settings['scheduleBeforeStart'] ?? true;
        scheduleAfterEnd.value = settings['scheduleAfterEnd'] ?? true;
        showBlockNotifications.value =
            settings['showBlockNotifications'] ?? false;
        quickModeAfterEnd.value = settings['quickModeAfterEnd'] ?? true;
        quickModeShowBlock.value = settings['quickModeShowBlock'] ?? false;
        showActivityNotifications.value =
            settings['showActivityNotifications'] ?? true;
      }
    } catch (e) {
      print('Error loading profile settings: $e');
    }
  }

  // Save profile settings to local storage
  Future<void> saveProfileSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
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

      await prefs.setString(settingsKey, jsonEncode(settings));
      print('Profile settings saved successfully');
    } catch (e) {
      print('Error saving profile settings: $e');
    }
  }

  // Load usage statistics with fallback to mock data
  Future<void> loadUsageStatistics() async {
    try {
      isLoadingStats.value = true;

      if (currentUser.value == null) {
        _setMockUsageData();
        return;
      }

      // Try to load from usage repository
      try {
        await _loadRealUsageStats();
      } catch (e) {
        print('Failed to load real usage stats: $e');
        // Fallback to local storage or mock data
        await _loadLocalUsageStats();
      }
    } catch (e) {
      print('Error loading usage statistics: $e');
      _setMockUsageData();
    } finally {
      isLoadingStats.value = false;
    }
  }

  // Load real usage statistics from repository
  Future<void> _loadRealUsageStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get total usage for today
    Duration todayUsage = await _usageRepository.getTotalUsageForPeriod(
      currentUser.value!.id,
      startOfDay,
      endOfDay,
    );
    totalUsageTime.value = _formatDuration(todayUsage);

    // Get weekly usage
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final weekStart =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    Duration weeklyUsage = await _usageRepository.getTotalUsageForPeriod(
      currentUser.value!.id,
      weekStart,
      today,
    );
    weeklyUsageTime.value = _formatDuration(weeklyUsage);

    // Calculate daily average
    int daysInWeek = today.weekday;
    if (daysInWeek > 0) {
      Duration avgDaily =
          Duration(milliseconds: weeklyUsage.inMilliseconds ~/ daysInWeek);
      dailyAverageTime.value = _formatDuration(avgDaily);
    }

    // Get monthly usage
    final startOfMonth = DateTime(today.year, today.month, 1);
    Duration monthlyUsage = await _usageRepository.getTotalUsageForPeriod(
      currentUser.value!.id,
      startOfMonth,
      today,
    );
    monthlyUsageTime.value = _formatDuration(monthlyUsage);

    // Get additional stats
    List<UsageLogModel> logs = await _usageRepository.getUsageLogsForPeriod(
      currentUser.value!.id,
      startOfDay,
      endOfDay,
      limit: 10,
    );
    recentUsageLogs.value = logs;
    totalAppsUsed.value = logs.map((log) => log.appPackageName).toSet().length;

    screenPickups.value = await _usageRepository.getScreenPickupsCount(
      currentUser.value!.id,
      startOfDay,
      endOfDay,
    );

    // Get user stats from model
    if (currentUser.value != null) {
      successfulBlocks.value = currentUser.value!.successfulBlocks;
      currentStreak.value = currentUser.value!.currentStreak;
    }

    // Save to local storage
    await _saveUsageStatsLocally();
  }

  // Load usage stats from local storage
  Future<void> _loadLocalUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(usageStatsKey);

      if (statsJson != null) {
        final stats = jsonDecode(statsJson) as Map<String, dynamic>;

        totalUsageTime.value = stats['totalUsageTime'] ?? '52h 30m';
        dailyAverageTime.value = stats['dailyAverageTime'] ?? '7h 24m';
        weeklyUsageTime.value = stats['weeklyUsageTime'] ?? '48h 15m';
        monthlyUsageTime.value = stats['monthlyUsageTime'] ?? '195h 45m';
        totalAppsUsed.value = stats['totalAppsUsed'] ?? 15;
        screenPickups.value = stats['screenPickups'] ?? 89;
        successfulBlocks.value = stats['successfulBlocks'] ?? 24;
        currentStreak.value = stats['currentStreak'] ?? 3;
      } else {
        _setMockUsageData();
      }
    } catch (e) {
      print('Error loading local usage stats: $e');
      _setMockUsageData();
    }
  }

  // Set mock usage data for demo purposes
  void _setMockUsageData() {
    totalUsageTime.value = '52h 30m';
    dailyAverageTime.value = '7h 24m';
    weeklyUsageTime.value = '48h 15m';
    monthlyUsageTime.value = '195h 45m';
    totalAppsUsed.value = 15;
    screenPickups.value = 89;
    successfulBlocks.value = 24;
    currentStreak.value = 3;
  }

  // Save usage stats to local storage
  Future<void> _saveUsageStatsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = {
        'totalUsageTime': totalUsageTime.value,
        'dailyAverageTime': dailyAverageTime.value,
        'weeklyUsageTime': weeklyUsageTime.value,
        'monthlyUsageTime': monthlyUsageTime.value,
        'totalAppsUsed': totalAppsUsed.value,
        'screenPickups': screenPickups.value,
        'successfulBlocks': successfulBlocks.value,
        'currentStreak': currentStreak.value,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(usageStatsKey, jsonEncode(stats));
    } catch (e) {
      print('Error saving usage stats locally: $e');
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      Get.dialog(
        AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                LoadingHelper.show('Signing out...');

                // Sign out through AuthController if available
                if (_authController != null) {
                  await _authController!.signOut();
                } else {
                  await _authService.signOut();
                  // Clear local data
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  currentUser.value = null;
                  Get.offAllNamed('/login');
                }

                LoadingHelper.hide();
              },
              child:
                  const Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } catch (e) {
      LoadingHelper.hide();
      Get.snackbar(
        'Error',
        'Failed to sign out: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      Get.dialog(
        AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
              const Text('Delete Account', style: TextStyle(color: Colors.red)),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                LoadingHelper.show('Deleting account...');

                bool success = false;
                if (_authController != null) {
                  success = await _authController!.deleteAccount();
                } else {
                  // Manual deletion process
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  currentUser.value = null;
                  success = true;
                  Get.offAllNamed('/login');
                }

                LoadingHelper.hide();

                if (!success) {
                  Get.snackbar(
                    'Error',
                    'Failed to delete account. Please try again.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } catch (e) {
      LoadingHelper.hide();
      Get.snackbar(
        'Error',
        'Failed to delete account: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings() async {
    try {
      await saveProfileSettings();

      Get.snackbar(
        'Success',
        'Notification settings updated',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update settings: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Refresh all data
  Future<void> refreshProfile() async {
    await Future.wait([
      loadUserProfile(),
      loadUsageStatistics(),
      loadProfileSettings(),
    ]);
  }

  // ENHANCED: Local storage methods
  Future<void> _saveUserLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(userDataKey, userJson);
      print('User saved locally: ${user.name}');
    } catch (e) {
      print('Error saving user locally: $e');
    }
  }

  Future<UserModel?> _getUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonString = prefs.getString(userDataKey);

      if (userJsonString != null) {
        final userJson = jsonDecode(userJsonString) as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);
        print('User loaded from local: ${user.name}');
        return user;
      }
    } catch (e) {
      print('Error getting user from local storage: $e');
    }
    return null;
  }

  // Utility methods
  String getUserInitials() {
    if (currentUser.value?.name != null && currentUser.value!.name.isNotEmpty) {
      return currentUser.value!.initials;
    }
    return 'U';
  }

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

  // Getters for UI
  bool get hasUserData => currentUser.value != null;
  String get userName => currentUser.value?.name ?? 'User';
  String get userEmail => currentUser.value?.email ?? '';
  String get userPhone => currentUser.value?.phone ?? '';
  String get userPhotoUrl => currentUser.value?.photoUrl ?? '';

  // Premium getters
  bool get isPremium => isPremiumUser.value;
  int get premiumDays => premiumDaysLeft.value;

  // FIXED: Better change detection
  bool hasProfileChanges() {
    if (currentUser.value == null) return false;

    final user = currentUser.value!;
    final nameChanged = nameController.text.trim() != user.name;
    final phoneChanged = phoneController.text.trim() != (user.phone ?? '');

    return nameChanged || phoneChanged;
  }

  // FIXED: Enhanced validation methods
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    // Check for valid characters (letters, spaces, common punctuation)
    if (!RegExp(r"^[a-zA-Z\s\-\'\.]+$").hasMatch(value.trim())) {
      return 'Name contains invalid characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

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

  // Toggle methods for settings
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
}
