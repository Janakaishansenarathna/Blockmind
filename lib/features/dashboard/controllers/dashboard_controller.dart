// controllers/home_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_apps/device_apps.dart';

import '../../../data/local/database/database_helper.dart';
import '../../../data/local/models/app_model.dart';
import '../../../data/local/models/schedule_model.dart';
import '../../../data/local/models/usage_log_model.dart';
import '../../../data/local/models/user_model.dart';
import '../../../data/services/database_initialization_service.dart';
import 'quick_mood_controller.dart';

class HomeController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Services
  late DatabaseInitializationService _dbInitService;
  late QuickModeController _quickModeController;

  // User data
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxString userName = 'User'.obs;
  RxString currentUserId = 'default_user'.obs;

  // App data
  RxList<AppModel> allApps = <AppModel>[].obs;
  RxList<AppModel> filteredApps = <AppModel>[].obs;
  RxBool isLoadingApps = false.obs;
  RxString searchQuery = ''.obs;

  // Progress tracking
  Rx<Duration> savedTimeToday = Duration.zero.obs;
  RxInt unblockCount = 0.obs;
  RxDouble progressPercentage = 0.0.obs;
  RxDouble uncompletedPercentage = 0.0.obs;
  RxInt notificationCount = 0.obs;

  // Schedule data
  RxList<ScheduleModel> schedules = <ScheduleModel>[].obs;
  RxList<ScheduleModel> activeSchedules = <ScheduleModel>[].obs;

  // UI State
  RxBool isInitialized = false.obs;
  RxBool isInitializing = false.obs;
  RxString errorMessage = ''.obs;

  // Timers
  Timer? _progressTimer;
  Timer? _appMonitorTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    _appMonitorTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeController() async {
    if (isInitializing.value) return;

    try {
      isInitializing.value = true;
      errorMessage.value = '';

      print('HomeController: Starting initialization...');

      // Get database service
      _dbInitService = Get.find<DatabaseInitializationService>();
      _quickModeController = Get.put(QuickModeController());

      // Wait for database to be ready
      print('HomeController: Waiting for database...');
      final dbReady = await _dbInitService.ensureDatabaseReady();
      if (!dbReady) {
        throw Exception('Database initialization failed');
      }

      // Set user ID in quick mode controller
      _quickModeController.setUserId(currentUserId.value);

      // Load initial data
      await _loadInitialData();

      // Start monitoring
      _startPeriodicUpdates();

      isInitialized.value = true;
      print('HomeController: Initialization completed successfully');
    } catch (e) {
      print('HomeController: Initialization failed: $e');
      errorMessage.value = 'Failed to initialize: $e';

      // Show error but don't crash
      Get.snackbar(
        'Initialization Error',
        'Some features may not work properly: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> _loadInitialData() async {
    print('HomeController: Loading initial data...');

    try {
      // Load user data
      await _loadUserData();

      // Load installed apps
      await _loadInstalledApps();

      // Load schedules
      await _loadSchedules();

      // Load progress data
      await _loadProgressData();

      print('HomeController: Initial data loaded successfully');
    } catch (e) {
      print('HomeController: Error loading initial data: $e');
      // Don't throw here, just log the error
    }
  }

  Future<void> _loadUserData() async {
    try {
      // For now, create a default user
      currentUser.value = UserModel(
        id: currentUserId.value,
        name: 'Default User',
        email: 'user@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      userName.value = currentUser.value!.name;
      print('HomeController: User data loaded');
    } catch (e) {
      print('HomeController: Error loading user data: $e');
      userName.value = 'User';
    }
  }

  Future<void> _loadInstalledApps() async {
    if (!_dbInitService.isInitialized.value) {
      print('HomeController: Database not ready, skipping app loading');
      return;
    }

    try {
      isLoadingApps.value = true;
      print('HomeController: Loading installed apps...');

      // Try to load real device apps first
      await _loadRealDeviceApps();

      // If no real apps loaded, use fallback apps
      if (allApps.isEmpty) {
        print('HomeController: No real apps found, using fallback apps');
        allApps.value = _getFallbackApps();
      }

      filteredApps.value = allApps.toList();
      print('HomeController: Loaded ${allApps.length} apps');
    } catch (e) {
      print('HomeController: Error loading apps: $e');
      // Use fallback apps if loading fails
      allApps.value = _getFallbackApps();
      filteredApps.value = allApps.toList();
    } finally {
      isLoadingApps.value = false;
    }
  }

  Future<void> _loadRealDeviceApps() async {
    try {
      // Get installed apps from device
      List<Application> deviceApps = await DeviceApps.getInstalledApplications(
        includeAppIcons: false,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );

      List<AppModel> appModels = [];

      for (Application app in deviceApps) {
        try {
          final appModel = AppModel(
            id: app.packageName,
            name: app.appName,
            packageName: app.packageName,
            icon: _getIconForPackage(app.packageName),
            iconColor: _generateColorFromString(app.appName),
            isSystemApp: app.systemApp,
            category: _getCategoryForPackage(app.packageName),
          );

          appModels.add(appModel);

          // Save to database
          await _databaseHelper.insertApp(appModel);
        } catch (e) {
          print('HomeController: Error processing app ${app.appName}: $e');
        }
      }

      // Sort by name
      appModels
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      allApps.value = appModels;

      print('HomeController: Loaded ${appModels.length} real device apps');
    } catch (e) {
      print('HomeController: Error loading real device apps: $e');
      throw e;
    }
  }

  IconData _getIconForPackage(String packageName) {
    final Map<String, IconData> knownIcons = {
      'com.facebook.katana': Icons.facebook,
      'com.instagram.android': Icons.camera_alt,
      'com.whatsapp': Icons.chat,
      'com.google.android.youtube': Icons.play_circle_fill,
      'com.twitter.android': Icons.alternate_email,
      'com.zhiliaoapp.musically': Icons.music_note,
      'com.snapchat.android': Icons.camera,
      'com.pinterest': Icons.push_pin,
      'com.linkedin.android': Icons.work,
      'com.reddit.frontpage': Icons.forum,
      'com.discord': Icons.headset_mic,
      'com.spotify.music': Icons.music_note,
      'com.netflix.mediaclient': Icons.tv,
      'com.chrome.beta': Icons.web,
      'com.android.chrome': Icons.web,
    };

    return knownIcons[packageName] ?? Icons.android;
  }

  String _getCategoryForPackage(String packageName) {
    final Map<String, String> knownCategories = {
      'com.facebook.katana': 'Social Media',
      'com.instagram.android': 'Social Media',
      'com.twitter.android': 'Social Media',
      'com.snapchat.android': 'Social Media',
      'com.linkedin.android': 'Social Media',
      'com.reddit.frontpage': 'Social Media',
      'com.google.android.youtube': 'Entertainment',
      'com.netflix.mediaclient': 'Entertainment',
      'com.spotify.music': 'Entertainment',
      'com.zhiliaoapp.musically': 'Entertainment',
      'com.whatsapp': 'Communication',
      'com.discord': 'Communication',
    };

    return knownCategories[packageName] ?? 'Other';
  }

  Color _generateColorFromString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
      Colors.deepOrange,
    ];

    return colors[hash.abs() % colors.length];
  }

  List<AppModel> _getFallbackApps() {
    return [
      AppModel(
        id: 'com.facebook.katana',
        name: 'Facebook',
        packageName: 'com.facebook.katana',
        icon: Icons.facebook,
        iconColor: const Color(0xFF1877F2),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.instagram.android',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        icon: Icons.camera_alt,
        iconColor: const Color(0xFFE4405F),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.whatsapp',
        name: 'WhatsApp',
        packageName: 'com.whatsapp',
        icon: Icons.chat,
        iconColor: const Color(0xFF25D366),
        category: 'Communication',
      ),
      AppModel(
        id: 'com.google.android.youtube',
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        icon: Icons.play_circle_fill,
        iconColor: const Color(0xFFFF0000),
        category: 'Entertainment',
      ),
      AppModel(
        id: 'com.zhiliaoapp.musically',
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        icon: Icons.music_note,
        iconColor: const Color(0xFF000000),
        category: 'Entertainment',
      ),
      AppModel(
        id: 'com.twitter.android',
        name: 'Twitter',
        packageName: 'com.twitter.android',
        icon: Icons.alternate_email,
        iconColor: const Color(0xFF1DA1F2),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.snapchat.android',
        name: 'Snapchat',
        packageName: 'com.snapchat.android',
        icon: Icons.camera,
        iconColor: const Color(0xFFFFFC00),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.netflix.mediaclient',
        name: 'Netflix',
        packageName: 'com.netflix.mediaclient',
        icon: Icons.tv,
        iconColor: const Color(0xFFE50914),
        category: 'Entertainment',
      ),
    ];
  }

  Future<void> _loadSchedules() async {
    if (!_dbInitService.isInitialized.value) return;

    try {
      final loadedSchedules =
          await _databaseHelper.getAllSchedules(userId: currentUserId.value);
      schedules.value = loadedSchedules;
      activeSchedules.value = loadedSchedules.where((s) => s.isActive).toList();

      print('HomeController: Loaded ${loadedSchedules.length} schedules');
    } catch (e) {
      print('HomeController: Error loading schedules: $e');
      schedules.value = [];
      activeSchedules.value = [];
    }
  }

  Future<void> _loadProgressData() async {
    if (!_dbInitService.isInitialized.value) return;

    try {
      final today = DateTime.now();
      final usageLogs = await _databaseHelper.getUsageLogsForDate(
        today,
        userId: currentUserId.value,
      );

      Duration totalSavedTime = Duration.zero;
      int totalUnblockCount = 0;

      for (final log in usageLogs) {
        if (log.wasBlocked) {
          totalSavedTime += log.duration;
          totalUnblockCount += log.openCount;
        }
      }

      savedTimeToday.value = totalSavedTime;
      unblockCount.value = totalUnblockCount;

      // Calculate progress percentages
      const targetSavedTime = Duration(hours: 4);
      progressPercentage.value =
          (totalSavedTime.inMinutes / targetSavedTime.inMinutes)
              .clamp(0.0, 1.0);

      const targetUnblockLimit = 5;
      uncompletedPercentage.value =
          (totalUnblockCount / targetUnblockLimit).clamp(0.0, 1.0);

      notificationCount.value = activeSchedules.length +
          (_quickModeController.isQuickModeActive.value ? 1 : 0);

      print(
          'HomeController: Progress loaded - Saved: ${totalSavedTime.inMinutes}min, Unblocks: $totalUnblockCount');
    } catch (e) {
      print('HomeController: Error loading progress data: $e');
    }
  }

  void _startPeriodicUpdates() {
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _loadProgressData();
    });

    _appMonitorTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Monitor app usage if quick mode is active
      if (_quickModeController.isQuickModeActive.value) {
        await _monitorAppUsage();
      }
    });

    print('HomeController: Periodic updates started');
  }

  Future<void> _monitorAppUsage() async {
    try {
      // Log usage for currently blocked apps
      for (final appId in _quickModeController.blockedAppIds) {
        final app = allApps.firstWhereOrNull((a) => a.id == appId);
        if (app != null) {
          await _logAppUsage(app, wasBlocked: true);
        }
      }
    } catch (e) {
      print('HomeController: Error monitoring app usage: $e');
    }
  }

  Future<void> _logAppUsage(AppModel app,
      {required bool wasBlocked, String? scheduleId}) async {
    try {
      final log = UsageLogModel(
        id: '${app.id}_${DateTime.now().millisecondsSinceEpoch}',
        appId: app.id,
        date: DateTime.now(),
        duration: const Duration(minutes: 1),
        wasBlocked: wasBlocked,
        scheduleId: scheduleId,
        openCount: wasBlocked ? 1 : 0,
      );

      await _databaseHelper.insertUsageLog(log, userId: currentUserId.value);
    } catch (e) {
      print('HomeController: Error logging app usage: $e');
    }
  }

  // Public methods for UI

  void searchApps(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredApps.value = allApps.toList();
    } else {
      filteredApps.value = allApps
          .where((app) =>
              app.name.toLowerCase().contains(query.toLowerCase()) ||
              app.packageName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  Map<String, List<AppModel>> getAppsByCategory() {
    final selectedApps = _quickModeController.selectedApps;

    final Map<String, List<AppModel>> categories = {};

    if (selectedApps.isNotEmpty) {
      categories['Selected Apps (${selectedApps.length})'] =
          selectedApps.toList();
    }

    categories['Social Media'] = allApps
        .where((app) =>
            app.category == 'Social Media' &&
            !_quickModeController.isAppSelected(app))
        .toList();

    categories['Entertainment'] = allApps
        .where((app) =>
            app.category == 'Entertainment' &&
            !_quickModeController.isAppSelected(app))
        .toList();

    categories['Communication'] = allApps
        .where((app) =>
            app.category == 'Communication' &&
            !_quickModeController.isAppSelected(app))
        .toList();

    categories['Other'] = allApps
        .where((app) =>
            app.category == 'Other' && !_quickModeController.isAppSelected(app))
        .toList();

    // Remove empty categories
    categories.removeWhere((key, value) => value.isEmpty);

    return categories;
  }

  Future<void> refreshData() async {
    await _loadInstalledApps();
    await _loadSchedules();
    await _loadProgressData();
  }

  // Getters for UI

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get savedTimeText {
    return "You've saved ${formatDuration(savedTimeToday.value)} today!";
  }

  String get unblockText {
    if (unblockCount.value == 0) {
      return "No app unblocks today - Great job!";
    }
    return "You've unblocked apps ${unblockCount.value} times today";
  }

  String get selectedAppsText {
    final selectedApps = _quickModeController.selectedApps;

    if (selectedApps.isEmpty) {
      return 'Add Something to block. Tap the Add button to select distracting apps';
    } else if (selectedApps.length == 1) {
      return 'Currently blocking: ${selectedApps.first.name}';
    } else {
      return 'Currently blocking: ${selectedApps.map((app) => app.name).take(2).join(", ")}${selectedApps.length > 2 ? " and ${selectedApps.length - 2} more" : ""}';
    }
  }

  bool isAppBlocked(AppModel app) {
    // Check if app is blocked by quick mode
    if (_quickModeController.isQuickModeActive.value &&
        _quickModeController.blockedAppIds.contains(app.id)) {
      return true;
    }

    // Check if app is blocked by any active schedule
    for (final schedule in activeSchedules) {
      if (schedule.isCurrentlyActive &&
          schedule.blockedApps.contains(app.packageName)) {
        return true;
      }
    }

    return false;
  }
}
