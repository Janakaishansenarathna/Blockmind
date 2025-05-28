// controllers/quick_mode_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/local/database/database_helper.dart';
import '../../../data/local/models/app_model.dart';

class QuickModeController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Observables
  final RxBool isQuickModeActive = false.obs;
  final RxString activeQuickBlockId = ''.obs;
  final RxInt remainingTimeSeconds = 0.obs;
  final RxList<String> blockedAppIds = <String>[].obs;
  final RxList<AppModel> availableApps = <AppModel>[].obs;
  final RxList<AppModel> selectedApps = <AppModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt selectedDurationMinutes = 30.obs;

  // Mood tracking
  final RxInt currentMood = 0.obs;
  final RxString moodNotes = ''.obs;
  final RxList<Map<String, dynamic>> moodHistory = <Map<String, dynamic>>[].obs;

  Timer? _countdownTimer;
  String? _currentUserId;

  // Storage keys
  static const String selectedAppsKey = 'quick_mode_selected_apps';
  static const String selectedDurationKey = 'quick_mode_duration';

  @override
  void onInit() {
    super.onInit();
    _loadSavedData();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  // ===== INITIALIZATION =====

  void setUserId(String userId) {
    _currentUserId = userId;
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      isLoading.value = true;
      await checkActiveQuickMode();
      await _loadTodayMood();
      await _loadMoodHistory();
    } catch (e) {
      _handleError('Failed to initialize Quick Mode', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load selected apps
      final selectedAppsJson = prefs.getString(selectedAppsKey);
      if (selectedAppsJson != null && selectedAppsJson.isNotEmpty) {
        final List<dynamic> appsList = jsonDecode(selectedAppsJson);
        selectedApps.value =
            appsList.map((json) => AppModel.fromJson(json)).toList();
      }

      // Load selected duration
      selectedDurationMinutes.value = prefs.getInt(selectedDurationKey) ?? 30;

      print('QuickModeController: Saved data loaded');
    } catch (e) {
      print('QuickModeController: Error loading saved data: $e');
    }
  }

  Future<void> _savePersistentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save selected apps
      final selectedAppsJson =
          jsonEncode(selectedApps.map((app) => app.toJson()).toList());
      await prefs.setString(selectedAppsKey, selectedAppsJson);

      // Save selected duration
      await prefs.setInt(selectedDurationKey, selectedDurationMinutes.value);

      print('QuickModeController: Data saved successfully');
    } catch (e) {
      print('QuickModeController: Error saving data: $e');
    }
  }

  // ===== APP MANAGEMENT =====

  void setAvailableApps(List<AppModel> apps) {
    availableApps.value = apps.where((app) => !app.isSystemApp).toList();
    availableApps.sort((a, b) => a.name.compareTo(b.name));
  }

  void toggleAppSelection(AppModel app) {
    if (isAppSelected(app)) {
      selectedApps.removeWhere((a) => a.id == app.id);
    } else {
      selectedApps.add(app);
    }
    _savePersistentData();
  }

  bool isAppSelected(AppModel app) {
    return selectedApps.any((a) => a.id == app.id);
  }

  void clearSelectedApps() {
    selectedApps.clear();
    _savePersistentData();
  }

  void selectAllApps() {
    selectedApps.value = List.from(availableApps);
    _savePersistentData();
  }

  void selectPopularApps() {
    final popularPackages = [
      'com.instagram.android',
      'com.facebook.katana',
      'com.twitter.android',
      'com.snapchat.android',
      'com.zhiliaoapp.musically', // TikTok
      'com.google.android.youtube',
    ];

    selectedApps.clear();
    for (final app in availableApps) {
      if (popularPackages.contains(app.packageName)) {
        selectedApps.add(app);
      }
    }
    _savePersistentData();
  }

  void setDuration(int minutes) {
    selectedDurationMinutes.value = minutes;
    _savePersistentData();
  }

  // ===== QUICK MODE OPERATIONS =====

  Future<bool> startQuickMode([int? durationMinutes]) async {
    if (selectedApps.isEmpty) {
      errorMessage.value = 'Please select at least one app to block';
      Get.snackbar(
        'No Apps Selected',
        'Please select at least one app to block',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (_currentUserId == null) {
      errorMessage.value = 'User not authenticated';
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final duration = durationMinutes ?? selectedDurationMinutes.value;

      // Stop any existing quick mode
      if (isQuickModeActive.value) {
        await stopQuickMode();
      }

      print(
          'QuickModeController: Starting Quick Mode for $duration minutes with ${selectedApps.length} apps');

      // Start new quick mode in database
      final quickBlockId = await _databaseHelper.startQuickMode(
        userId: _currentUserId!,
        durationMinutes: duration,
        blockedAppIds: selectedApps.map((app) => app.id).toList(),
      );

      // Block the selected apps in database
      for (final app in selectedApps) {
        await _databaseHelper.insertBlockedApp(
          app,
          userId: _currentUserId!,
          isQuickBlock: true,
        );
      }

      // Update state
      activeQuickBlockId.value = quickBlockId;
      blockedAppIds.value = selectedApps.map((app) => app.id).toList();
      isQuickModeActive.value = true;
      remainingTimeSeconds.value = duration * 60;

      // Start countdown timer
      _startCountdownTimer();

      Get.snackbar(
        'Quick Mode Started',
        'Blocking ${selectedApps.length} apps for $duration minutes',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      print(
          'QuickModeController: Quick mode started successfully: $quickBlockId');
      return true;
    } catch (e) {
      _handleError('Failed to start Quick Mode', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> stopQuickMode() async {
    if (!isQuickModeActive.value) return;

    try {
      isLoading.value = true;

      print('QuickModeController: Stopping Quick Mode');

      // Stop the quick mode in database
      if (activeQuickBlockId.value.isNotEmpty) {
        await _databaseHelper.stopQuickMode(activeQuickBlockId.value);
      }

      // Unblock the apps
      for (final appId in blockedAppIds) {
        await _databaseHelper.removeBlockedApp(appId, userId: _currentUserId);
      }

      // Update state
      _resetQuickModeState();

      Get.snackbar(
        'Quick Mode Stopped',
        'Apps are now unblocked',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      print('QuickModeController: Quick mode stopped successfully');
    } catch (e) {
      _handleError('Failed to stop Quick Mode', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> toggleQuickMode([int? durationMinutes]) async {
    if (isQuickModeActive.value) {
      await stopQuickMode();
      return false;
    } else {
      return await startQuickMode(durationMinutes);
    }
  }

  Future<void> checkActiveQuickMode() async {
    if (_currentUserId == null) return;

    try {
      final activeQuickMode =
          await _databaseHelper.getActiveQuickMode(_currentUserId!);

      if (activeQuickMode != null) {
        activeQuickBlockId.value = activeQuickMode['id'];
        blockedAppIds.value = List<String>.from(activeQuickMode['blockedApps']);
        isQuickModeActive.value = true;
        remainingTimeSeconds.value =
            (activeQuickMode['remainingTime'] / 1000).round();

        if (remainingTimeSeconds.value > 0) {
          _startCountdownTimer();
          print(
              'QuickModeController: Found active Quick Mode with ${remainingTimeSeconds.value} seconds remaining');
        } else {
          // Quick mode has expired
          await stopQuickMode();
        }
      } else {
        _resetQuickModeState();
      }
    } catch (e) {
      print('QuickModeController: Error checking active Quick Mode: $e');
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeSeconds.value > 0) {
        remainingTimeSeconds.value--;
      } else {
        timer.cancel();
        stopQuickMode();

        // Show completion notification
        Get.snackbar(
          'Quick Mode Completed!',
          'Your blocking session has finished. Great job!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    });
  }

  void _resetQuickModeState() {
    _countdownTimer?.cancel();
    isQuickModeActive.value = false;
    activeQuickBlockId.value = '';
    remainingTimeSeconds.value = 0;
    blockedAppIds.clear();
  }

  // ===== QUICK MODE HISTORY =====

  Future<List<Map<String, dynamic>>> getQuickModeHistory({int? limit}) async {
    if (_currentUserId == null) return [];

    try {
      return await _databaseHelper.getQuickModeHistory(_currentUserId!,
          limit: limit);
    } catch (e) {
      print('QuickModeController: Error getting Quick Mode history: $e');
      return [];
    }
  }

  // ===== MOOD TRACKING =====

  Future<void> saveMood(int moodLevel, {String? notes}) async {
    if (_currentUserId == null) {
      errorMessage.value = 'User not authenticated';
      return;
    }

    if (moodLevel < 1 || moodLevel > 5) {
      errorMessage.value = 'Mood level must be between 1 and 5';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _databaseHelper.saveMood(
        userId: _currentUserId!,
        moodLevel: moodLevel,
        notes: notes,
      );

      currentMood.value = moodLevel;
      moodNotes.value = notes ?? '';

      await _loadMoodHistory();

      Get.snackbar(
        'Mood Saved',
        'Your mood has been recorded for today',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _handleError('Failed to save mood', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTodayMood() async {
    if (_currentUserId == null) return;

    try {
      final todayMood =
          await _databaseHelper.getMoodForDate(_currentUserId!, DateTime.now());

      if (todayMood != null) {
        currentMood.value = todayMood['moodLevel'];
        moodNotes.value = todayMood['notes'] ?? '';
      } else {
        currentMood.value = 0;
        moodNotes.value = '';
      }
    } catch (e) {
      print('QuickModeController: Error loading today mood: $e');
    }
  }

  Future<void> _loadMoodHistory() async {
    if (_currentUserId == null) return;

    try {
      final history =
          await _databaseHelper.getMoodHistory(_currentUserId!, days: 30);
      moodHistory.value = history;
    } catch (e) {
      print('QuickModeController: Error loading mood history: $e');
    }
  }

  Future<void> resetMoodData() async {
    if (_currentUserId == null) {
      errorMessage.value = 'User not authenticated';
      return;
    }

    try {
      isLoading.value = true;

      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Reset Mood Data'),
              content: const Text(
                  'Are you sure you want to delete all your mood tracking data? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;

      await _databaseHelper.resetMoodData(_currentUserId!);

      // Reset local state
      currentMood.value = 0;
      moodNotes.value = '';
      moodHistory.clear();

      Get.snackbar(
        'Mood Data Reset',
        'All mood tracking data has been deleted',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _handleError('Failed to reset mood data', e);
    } finally {
      isLoading.value = false;
    }
  }

  // ===== UTILITY METHODS =====

  String formatRemainingTime() {
    final minutes = remainingTimeSeconds.value ~/ 60;
    final seconds = remainingTimeSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😞';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '❓';
    }
  }

  String getMoodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very Happy';
      default:
        return 'Unknown';
    }
  }

  Color getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red.shade700;
      case 2:
        return Colors.orange.shade700;
      case 3:
        return Colors.grey.shade600;
      case 4:
        return Colors.green.shade600;
      case 5:
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  double getMoodAverage({int? days}) {
    if (moodHistory.isEmpty) return 0.0;

    final relevantMoods =
        days != null ? moodHistory.take(days).toList() : moodHistory.toList();

    if (relevantMoods.isEmpty) return 0.0;

    final sum = relevantMoods.fold<int>(
        0, (sum, mood) => sum + (mood['moodLevel'] as int));
    return sum / relevantMoods.length;
  }

  int getMoodStreak() {
    if (moodHistory.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < moodHistory.length; i++) {
      final moodDate =
          DateTime.fromMillisecondsSinceEpoch(moodHistory[i]['date']);
      final expectedDate = today.subtract(Duration(days: i));

      // Check if this mood is for the expected consecutive day
      if (moodDate.year == expectedDate.year &&
          moodDate.month == expectedDate.month &&
          moodDate.day == expectedDate.day) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ===== QUICK MODE PRESETS =====

  void applyQuickModePreset(QuickModePreset preset) {
    selectedApps.clear();

    for (final app in availableApps) {
      if (preset.shouldIncludeApp(app)) {
        selectedApps.add(app);
      }
    }
    _savePersistentData();
  }

  List<QuickModePreset> getQuickModePresets() {
    return [
      QuickModePreset(
        name: 'Social Media',
        description: 'Block social media apps',
        icon: Icons.people,
        color: Colors.blue,
        packageNames: [
          'com.instagram.android',
          'com.facebook.katana',
          'com.twitter.android',
          'com.snapchat.android',
          'com.zhiliaoapp.musically',
          'com.linkedin.android',
        ],
      ),
      QuickModePreset(
        name: 'Entertainment',
        description: 'Block entertainment apps',
        icon: Icons.tv,
        color: Colors.purple,
        packageNames: [
          'com.netflix.mediaclient',
          'com.google.android.youtube',
          'com.amazon.avod.thirdpartyclient',
          'com.disney.disneyplus',
        ],
      ),
      QuickModePreset(
        name: 'Games',
        description: 'Block gaming apps',
        icon: Icons.games,
        color: Colors.red,
        categories: ['Games'],
      ),
      QuickModePreset(
        name: 'All Distracting',
        description: 'Block most distracting apps',
        icon: Icons.block,
        color: Colors.orange,
        packageNames: [
          'com.instagram.android',
          'com.facebook.katana',
          'com.twitter.android',
          'com.snapchat.android',
          'com.zhiliaoapp.musically',
          'com.google.android.youtube',
          'com.netflix.mediaclient',
        ],
      ),
    ];
  }

  // ===== ERROR HANDLING =====

  void _handleError(String message, dynamic error) {
    errorMessage.value = message;
    print('QuickModeController: $message: $error');

    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  void clearError() {
    errorMessage.value = '';
  }

  // ===== GETTERS FOR UI =====

  String get quickModeButtonText {
    if (selectedApps.isEmpty && !isQuickModeActive.value) {
      return '+ Add Apps';
    } else if (isQuickModeActive.value) {
      return 'Stop Blocking';
    } else {
      return 'Start (${selectedApps.length} apps)';
    }
  }

  String get selectedAppsCountText {
    if (selectedApps.isEmpty) {
      return 'No apps selected';
    } else if (selectedApps.length == 1) {
      return '1 app selected';
    } else {
      return '${selectedApps.length} apps selected';
    }
  }

  String get remainingTimeText {
    if (!isQuickModeActive.value || remainingTimeSeconds.value == 0) {
      return '';
    }
    return 'Time remaining: ${formatRemainingTime()}';
  }

  bool get hasSelectedApps => selectedApps.isNotEmpty;
  bool get canStartQuickMode =>
      selectedApps.isNotEmpty && !isQuickModeActive.value;
}

// ===== QUICK MODE PRESET MODEL =====

class QuickModePreset {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String>? packageNames;
  final List<String>? categories;

  QuickModePreset({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.packageNames,
    this.categories,
  });

  bool shouldIncludeApp(AppModel app) {
    if (packageNames != null && packageNames!.contains(app.packageName)) {
      return true;
    }

    if (categories != null &&
        app.category != null &&
        categories!.contains(app.category)) {
      return true;
    }

    return false;
  }
}
