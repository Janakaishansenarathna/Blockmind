import 'dart:async';

import '../local/models/app_model.dart';
import '../local/models/schedule_model.dart';
import '../services/app_blocker_service.dart';
import '../services/device_app_service.dart';
import '../services/usage_stats_service.dart';
import '../services/notification_service.dart';

class AppBlockerManager {
  static final AppBlockerManager _instance = AppBlockerManager._internal();

  // Services
  final AppBlockerService _blockerService = AppBlockerService();
  final DeviceAppService _deviceAppService = DeviceAppService();
  final UsageStatsService _usageStatsService = UsageStatsService();
  final NotificationService _notificationService = NotificationService();

  // State variables
  bool _isInitialized = false;
  Timer? _quickBlockTimer;
  Timer? _appCheckTimer;

  factory AppBlockerManager() {
    return _instance;
  }

  AppBlockerManager._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize all services
    await _blockerService.initialize();
    await _notificationService.initialize();

    // Start monitoring apps
    _startAppMonitoring();

    _isInitialized = true;
  }

  // Get all installed apps
  Future<List<AppModel>> getInstalledApps() async {
    return await _deviceAppService.getInstalledApps();
  }

  // Get blocked apps
  Future<List> getBlockedApps() async {
    return await _blockerService.getBlockedApps();
  }

  // Block an app
  Future<void> blockApp(AppModel app) async {
    await _blockerService.addBlockedApp(app);
  }

  // Unblock an app
  Future<void> unblockApp(String appId) async {
    await _blockerService.removeBlockedApp(appId);
  }

  // Start quick block
  Future<void> startQuickBlock(Duration duration, List<AppModel> apps) async {
    // Save selected apps
    for (var app in apps) {
      await _blockerService.addBlockedApp(app);
    }

    // Set quick block active with duration
    await _blockerService.setQuickBlockDuration(duration);
    await _blockerService.setQuickBlockActive(true);

    // Start a timer to check when quick block ends
    _startQuickBlockTimer();

    // Show notification
    await _notificationService.showTimerNotification(
      'Quick Block Started',
      'Apps will be blocked for ${_formatDuration(duration)}',
    );
  }

  // Stop quick block
  Future<void> stopQuickBlock() async {
    await _blockerService.setQuickBlockActive(false);
    _quickBlockTimer?.cancel();

    // Show notification
    await _notificationService.showTimerNotification(
      'Quick Block Stopped',
      'App blocking has been stopped',
    );
  }

  // Get quick block status
  bool isQuickBlockActive() {
    return _blockerService.isQuickBlockActive();
  }

  // Get quick block duration
  Duration getQuickBlockDuration() {
    return _blockerService.getQuickBlockDuration();
  }

  // Get quick block end time
  DateTime? getQuickBlockEndTime() {
    return _blockerService.getQuickBlockEndTime();
  }

  // Get time remaining in quick block
  Duration? getQuickBlockTimeRemaining() {
    final endTime = _blockerService.getQuickBlockEndTime();
    if (endTime == null) return null;

    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;

    return endTime.difference(now);
  }

  // Get all schedules
  Future<List<ScheduleModel>> getSchedules() async {
    return await _blockerService.getSchedules();
  }

  // Add a schedule
  Future<void> addSchedule(ScheduleModel schedule) async {
    await _blockerService.addSchedule(schedule);
  }

  // Update a schedule
  Future<void> updateSchedule(ScheduleModel schedule) async {
    await _blockerService.updateSchedule(schedule);
  }

  // Toggle schedule active state
  Future<void> toggleScheduleActive(String scheduleId, bool isActive) async {
    await _blockerService.toggleScheduleActive(scheduleId, isActive);
  }

  // Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    await _blockerService.deleteSchedule(scheduleId);
  }

  // Get usage statistics
  Future<Map<String, Duration>> getTodayUsageStats() async {
    return await _blockerService.getTodayUsageStats();
  }

  // Get saved time today
  Future<Duration> getSavedTimeToday() async {
    return await _blockerService.getTotalSavedTime();
  }

  // Get unblock count today
  Future<int> getUnblockCountToday() async {
    return await _blockerService.getUnblockCount();
  }

  // Check if app should be blocked
  bool shouldBlockApp(String packageName) {
    return _blockerService.shouldBlockApp(packageName);
  }

  // Start monitoring for app launches
  void _startAppMonitoring() {
    // Check every 2 seconds for the foreground app
    _appCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // This is a placeholder. In a real implementation, you would use
      // platform-specific code to detect the foreground app and block it if needed
    });
  }

  // Start timer for quick block
  void _startQuickBlockTimer() {
    _quickBlockTimer?.cancel();

    _quickBlockTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      final endTime = _blockerService.getQuickBlockEndTime();
      if (endTime == null || DateTime.now().isAfter(endTime)) {
        // Quick block has ended
        _blockerService.setQuickBlockActive(false);
        _quickBlockTimer?.cancel();

        // Show notification
        _notificationService.showTimerNotification(
          'Quick Block Ended',
          'Your apps are no longer blocked',
        );
      }
    });
  }

  // Format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return '$twoDigitHours:$twoDigitMinutes';
  }

  // Clean up resources
  void dispose() {
    _quickBlockTimer?.cancel();
    _appCheckTimer?.cancel();
  }
}
