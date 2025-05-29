// services/app_blocker_manager.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../local/models/app_model.dart';
import '../local/models/schedule_model.dart';
import '../local/models/usage_log_model.dart';
import 'app_blocker_service.dart';
import 'device_app_service.dart';
import 'usage_stats_service.dart';
import 'notification_service.dart';

class AppBlockerManager {
  static final AppBlockerManager _instance = AppBlockerManager._internal();

  // Services
  final FirebaseAppBlockerService _blockerService = FirebaseAppBlockerService();
  final DeviceAppService _deviceAppService = DeviceAppService();
  final UsageStatsService _usageStatsService = UsageStatsService();
  final NotificationService _notificationService = NotificationService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  bool _isInitialized = false;
  Timer? _appCheckTimer;
  Timer? _syncTimer;
  String? _currentUserId;

  // Stream subscriptions for real-time monitoring
  StreamSubscription? _quickModeSubscription;
  StreamSubscription? _blockedAppsSubscription;
  StreamSubscription? _schedulesSubscription;
  StreamSubscription? _authSubscription;

  // Current state cache
  bool _isQuickModeActive = false;
  List<String> _currentlyBlockedApps = [];
  List<ScheduleModel> _activeSchedules = [];
  Map<String, dynamic>? _activeQuickMode;

  factory AppBlockerManager() {
    return _instance;
  }

  AppBlockerManager._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('AppBlockerManager: Starting initialization...');

      // Initialize Firebase service
      await _blockerService.initialize();

      // Initialize notification service
      await _notificationService.initialize();

      // Set up auth listener
      _setupAuthListener();

      // Check current user
      final user = _auth.currentUser;
      if (user != null) {
        await _handleUserSignIn(user.uid);
      }

      // Start app monitoring
      _startAppMonitoring();

      // Start periodic sync
      _startPeriodicSync();

      _isInitialized = true;
      print('AppBlockerManager: Initialization completed successfully');
    } catch (e) {
      print('AppBlockerManager: Initialization failed: $e');
      rethrow;
    }
  }

  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _handleUserSignIn(user.uid);
      } else {
        _handleUserSignOut();
      }
    });
  }

  Future<void> _handleUserSignIn(String userId) async {
    try {
      _currentUserId = userId;
      _blockerService.setCurrentUser(userId);

      // Set up real-time listeners
      _setupRealtimeListeners();

      print('AppBlockerManager: User signed in: $userId');
    } catch (e) {
      print('AppBlockerManager: Error handling user sign in: $e');
    }
  }

  void _handleUserSignOut() {
    _currentUserId = null;
    _teardownRealtimeListeners();
    _clearCachedState();
    print('AppBlockerManager: User signed out');
  }

  void _setupRealtimeListeners() {
    if (_currentUserId == null) return;

    // Listen to quick mode changes
    _quickModeSubscription = _blockerService.watchActiveQuickMode().listen(
      (quickMode) {
        _activeQuickMode = quickMode;
        _isQuickModeActive = quickMode != null;

        if (quickMode != null) {
          _currentlyBlockedApps =
              List<String>.from(quickMode['blockedApps'] ?? []);
          _handleQuickModeStateChange(quickMode);
        } else {
          _currentlyBlockedApps.clear();
        }
      },
      onError: (error) {
        print('AppBlockerManager: Error in quick mode stream: $error');
      },
    );

    // Listen to blocked apps changes
    _blockedAppsSubscription = _blockerService.watchBlockedApps().listen(
      (blockedApps) {
        _currentlyBlockedApps =
            blockedApps.map((app) => app.packageName).toList();
      },
      onError: (error) {
        print('AppBlockerManager: Error in blocked apps stream: $error');
      },
    );

    // Listen to schedule changes
    _schedulesSubscription = _blockerService.watchSchedules().listen(
      (schedules) {
        _activeSchedules = schedules.where((s) => s.isActive).toList();
      },
      onError: (error) {
        print('AppBlockerManager: Error in schedules stream: $error');
      },
    );
  }

  void _handleQuickModeStateChange(Map<String, dynamic> quickMode) {
    final endTime = (quickMode['endTime'] as Timestamp?)?.toDate();
    final isActive = quickMode['isActive'] ?? false;

    if (isActive && endTime != null) {
      final remainingTime = endTime.difference(DateTime.now());

      if (remainingTime.isNegative) {
        // Quick mode has expired
        _notificationService.showTimerNotification(
          'Quick Mode Completed!',
          'Your blocking session has finished. Great job!',
        );
      } else {
        // Quick mode is active
        final blockedAppsCount =
            (quickMode['blockedApps'] as List?)?.length ?? 0;
        _notificationService.showTimerNotification(
          'Quick Mode Active',
          'Blocking $blockedAppsCount apps - ${_formatDuration(remainingTime)} remaining',
        );
      }
    }
  }

  void _teardownRealtimeListeners() {
    _quickModeSubscription?.cancel();
    _blockedAppsSubscription?.cancel();
    _schedulesSubscription?.cancel();

    _quickModeSubscription = null;
    _blockedAppsSubscription = null;
    _schedulesSubscription = null;
  }

  void _clearCachedState() {
    _isQuickModeActive = false;
    _currentlyBlockedApps.clear();
    _activeSchedules.clear();
    _activeQuickMode = null;
  }

  // ===== PUBLIC API METHODS =====

  // Get all installed apps
  Future<List<AppModel>> getInstalledApps() async {
    try {
      // First try to get from device
      final deviceApps = await _deviceAppService.getInstalledApps();
      if (deviceApps.isNotEmpty) {
        return deviceApps;
      }

      // Fallback to service method
      return await _blockerService.getInstalledApps();
    } catch (e) {
      print('AppBlockerManager: Error getting installed apps: $e');
      return await _blockerService.getInstalledApps();
    }
  }

  // Get blocked apps
  Future<List<AppModel>> getBlockedApps() async {
    try {
      return await _blockerService.getBlockedApps();
    } catch (e) {
      print('AppBlockerManager: Error getting blocked apps: $e');
      return [];
    }
  }

  // Block an app
  Future<void> blockApp(AppModel app, {bool isQuickBlock = false}) async {
    try {
      await _blockerService.addBlockedApp(app, isQuickBlock: isQuickBlock);

      await _notificationService.showTimerNotification(
        'App Blocked',
        '${app.name} is now blocked',
      );

      // Log the blocking action
      await _logAppUsage(app, wasBlocked: true);
    } catch (e) {
      print('AppBlockerManager: Error blocking app: $e');
      rethrow;
    }
  }

  // Unblock an app
  Future<void> unblockApp(String appId) async {
    try {
      await _blockerService.removeBlockedApp(appId);

      await _notificationService.showTimerNotification(
        'App Unblocked',
        'App is now accessible',
      );
    } catch (e) {
      print('AppBlockerManager: Error unblocking app: $e');
      rethrow;
    }
  }

  // Start quick block
  Future<String?> startQuickBlock(
      Duration duration, List<AppModel> apps) async {
    try {
      if (apps.isEmpty) {
        throw Exception('No apps selected for blocking');
      }

      // First add apps to blocked list
      for (var app in apps) {
        await _blockerService.addBlockedApp(app, isQuickBlock: true);
      }

      // Start quick mode in Firebase
      final quickModeId = await _blockerService.startQuickMode(
        appIds: apps.map((app) => app.id).toList(),
        durationMinutes: duration.inMinutes,
      );

      // Show notification
      await _notificationService.showTimerNotification(
        'Quick Mode Started',
        'Blocking ${apps.length} apps for ${_formatDuration(duration)}',
      );

      print('AppBlockerManager: Quick mode started: $quickModeId');
      return quickModeId;
    } catch (e) {
      print('AppBlockerManager: Error starting quick block: $e');
      rethrow;
    }
  }

  // Stop quick block
  Future<void> stopQuickBlock() async {
    try {
      if (_activeQuickMode != null) {
        await _blockerService.stopQuickMode(_activeQuickMode!['id']);
      }

      // Remove all quick block apps
      await _blockerService.removeAllBlockedApps(onlyQuickBlocks: true);

      // Show notification
      await _notificationService.showTimerNotification(
        'Quick Mode Stopped',
        'Apps are now unblocked',
      );

      print('AppBlockerManager: Quick mode stopped');
    } catch (e) {
      print('AppBlockerManager: Error stopping quick block: $e');
      rethrow;
    }
  }

  // Get quick block status
  bool isQuickBlockActive() {
    return _isQuickModeActive;
  }

  // Get quick block duration
  Duration? getQuickBlockDuration() {
    if (_activeQuickMode == null) return null;
    return Duration(minutes: _activeQuickMode!['durationMinutes'] ?? 0);
  }

  // Get quick block end time
  DateTime? getQuickBlockEndTime() {
    if (_activeQuickMode == null) return null;
    return (_activeQuickMode!['endTime'] as Timestamp?)?.toDate();
  }

  // Get time remaining in quick block
  Duration? getQuickBlockTimeRemaining() {
    final endTime = getQuickBlockEndTime();
    if (endTime == null) return null;

    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;

    return endTime.difference(now);
  }

  // Get currently blocked app IDs
  List<String> getCurrentlyBlockedApps() {
    return List.from(_currentlyBlockedApps);
  }

  // Get all schedules
  Future<List<ScheduleModel>> getSchedules() async {
    try {
      return await _blockerService.getSchedules();
    } catch (e) {
      print('AppBlockerManager: Error getting schedules: $e');
      return [];
    }
  }

  // Add a schedule
  Future<void> addSchedule(ScheduleModel schedule) async {
    try {
      await _blockerService.addSchedule(schedule);

      await _notificationService.showTimerNotification(
        'Schedule Added',
        '${schedule.title} has been created',
      );
    } catch (e) {
      print('AppBlockerManager: Error adding schedule: $e');
      rethrow;
    }
  }

  // Update a schedule
  Future<void> updateSchedule(ScheduleModel schedule) async {
    try {
      await _blockerService.updateSchedule(schedule);

      await _notificationService.showTimerNotification(
        'Schedule Updated',
        '${schedule.title} has been updated',
      );
    } catch (e) {
      print('AppBlockerManager: Error updating schedule: $e');
      rethrow;
    }
  }

  // Toggle schedule active state
  Future<void> toggleScheduleActive(String scheduleId, bool isActive) async {
    try {
      await _blockerService.toggleScheduleActive(scheduleId, isActive);

      await _notificationService.showTimerNotification(
        'Schedule ${isActive ? 'Activated' : 'Deactivated'}',
        'Schedule status has been updated',
      );
    } catch (e) {
      print('AppBlockerManager: Error toggling schedule: $e');
      rethrow;
    }
  }

  // Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _blockerService.deleteSchedule(scheduleId);

      await _notificationService.showTimerNotification(
        'Schedule Deleted',
        'Schedule has been removed',
      );
    } catch (e) {
      print('AppBlockerManager: Error deleting schedule: $e');
      rethrow;
    }
  }

  // Get usage statistics
  Future<Map<String, Duration>> getTodayUsageStats() async {
    try {
      return await _blockerService.getTodayUsageStats();
    } catch (e) {
      print('AppBlockerManager: Error getting usage stats: $e');
      return {};
    }
  }

  // Get saved time today
  Future<Duration> getSavedTimeToday() async {
    try {
      return await _blockerService.getTotalSavedTime();
    } catch (e) {
      print('AppBlockerManager: Error getting saved time: $e');
      return Duration.zero;
    }
  }

  // Get unblock count today
  Future<int> getUnblockCountToday() async {
    try {
      return await _blockerService.getUnblockCount();
    } catch (e) {
      print('AppBlockerManager: Error getting unblock count: $e');
      return 0;
    }
  }

  // Check if app should be blocked
  Future<bool> shouldBlockApp(String packageName) async {
    try {
      // Check cached blocked apps first for performance
      if (_currentlyBlockedApps.contains(packageName)) {
        return true;
      }

      // Check against active schedules
      final now = DateTime.now();
      final currentDay = now.weekday;
      final currentMinutes = now.hour * 60 + now.minute;

      for (final schedule in _activeSchedules) {
        if (schedule.blockedApps.contains(packageName)) {
          final startMinutes =
              schedule.startTime.hour * 60 + schedule.startTime.minute;
          final endMinutes =
              schedule.endTime.hour * 60 + schedule.endTime.minute;

          bool isInTimeRange;
          if (startMinutes <= endMinutes) {
            // Same day schedule
            isInTimeRange =
                currentMinutes >= startMinutes && currentMinutes <= endMinutes;
          } else {
            // Overnight schedule
            isInTimeRange =
                currentMinutes >= startMinutes || currentMinutes <= endMinutes;
          }

          if (schedule.days.contains(currentDay) && isInTimeRange) {
            return true;
          }
        }
      }

      // Fallback to Firebase check
      return await _blockerService.shouldBlockApp(packageName);
    } catch (e) {
      print('AppBlockerManager: Error checking if app should be blocked: $e');
      return false;
    }
  }

  // ===== MOOD TRACKING =====

  Future<void> saveMood(int moodLevel, {String? notes}) async {
    try {
      await _blockerService.saveMood(moodLevel: moodLevel, notes: notes);
    } catch (e) {
      print('AppBlockerManager: Error saving mood: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTodayMood() async {
    try {
      return await _blockerService.getMoodForDate(DateTime.now());
    } catch (e) {
      print('AppBlockerManager: Error getting today mood: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMoodHistory({int days = 30}) async {
    try {
      return await _blockerService.getMoodHistory(days: days);
    } catch (e) {
      print('AppBlockerManager: Error getting mood history: $e');
      return [];
    }
  }

  // ===== PRIVATE HELPER METHODS =====

  Future<void> _logAppUsage(AppModel app, {required bool wasBlocked}) async {
    try {
      final log = UsageLogModel(
        id: '${app.id}_${DateTime.now().millisecondsSinceEpoch}',
        appId: app.id,
        date: DateTime.now(),
        duration: const Duration(minutes: 1),
        wasBlocked: wasBlocked,
        openCount: wasBlocked ? 1 : 0,
      );

      await _blockerService.logAppUsage(log);
    } catch (e) {
      print('AppBlockerManager: Error logging app usage: $e');
    }
  }

  // Start monitoring for app launches
  void _startAppMonitoring() {
    // Check every 5 seconds for blocked apps
    _appCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // In a real implementation, you would use platform-specific code
        // to detect the foreground app and check if it should be blocked

        // For now, this is a placeholder that could integrate with
        // Android's UsageStatsManager or similar iOS APIs
        await _checkForegroundApp();
      } catch (e) {
        print('AppBlockerManager: Error in app monitoring: $e');
      }
    });
  }

  Future<void> _checkForegroundApp() async {
    // Placeholder for foreground app detection
    // This would integrate with platform-specific code to:
    // 1. Get the currently running foreground app
    // 2. Check if it should be blocked
    // 3. Show blocking overlay or redirect if needed
    // 4. Log usage statistics
  }

  // Start periodic sync for offline support
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        // Sync any offline data or refresh cache
        await _syncOfflineData();
      } catch (e) {
        print('AppBlockerManager: Error in periodic sync: $e');
      }
    });
  }

  Future<void> _syncOfflineData() async {
    // Placeholder for syncing offline data
    // This could include:
    // 1. Uploading cached usage logs
    // 2. Syncing configuration changes
    // 3. Downloading updated schedules
  }

  // Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  // ===== STREAM GETTERS FOR UI =====

  Stream<bool> get quickModeStatusStream {
    return _blockerService
        .watchActiveQuickMode()
        .map((quickMode) => quickMode != null);
  }

  Stream<List<AppModel>> get blockedAppsStream {
    return _blockerService.watchBlockedApps();
  }

  Stream<List<ScheduleModel>> get schedulesStream {
    return _blockerService.watchSchedules();
  }

  Stream<Map<String, dynamic>?> get activeQuickModeStream {
    return _blockerService.watchActiveQuickMode();
  }

  // ===== CLEANUP =====

  Future<void> dispose() async {
    print('AppBlockerManager: Disposing resources...');

    _appCheckTimer?.cancel();
    _syncTimer?.cancel();

    _teardownRealtimeListeners();
    await _authSubscription?.cancel();

    _clearCachedState();
    _isInitialized = false;

    print('AppBlockerManager: Cleanup completed');
  }

  // ===== GETTERS =====

  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;
  bool get hasActiveUser => _currentUserId != null;
}
