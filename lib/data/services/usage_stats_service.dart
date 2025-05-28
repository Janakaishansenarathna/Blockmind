// data/services/usage_stats_service.dart
import 'package:app_usage/app_usage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../local/database/database_helper.dart';
import '../local/models/usage_log_model.dart';
import '../local/models/app_model.dart';
import '../local/daos/usage_log_dao.dart';

class UsageStatsService {
  static final UsageStatsService _instance = UsageStatsService._internal();

  factory UsageStatsService() {
    return _instance;
  }

  UsageStatsService._internal();

  final UsageLogDao _usageLogDao = UsageLogDao();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Timer? _usageTrackingTimer;
  Timer? _syncTimer;
  bool _isTracking = false;
  bool _isInitialized = false;
  String? _currentUserId;

  // Cache for app information
  Map<String, AppModel> _appCache = {};
  DateTime _lastCacheUpdate = DateTime.now();

  // ===== INITIALIZATION =====

  /// Initialize the service
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    _currentUserId = userId;
    await _databaseHelper.initDatabase();
    await requestUsageStatsPermission();
    await _loadAppCache();
    startUsageTracking();
    _startPeriodicSync();

    _isInitialized = true;
    print('UsageStatsService initialized for user: ${userId ?? "guest"}');
  }

  /// Set current user ID
  void setUserId(String userId) {
    _currentUserId = userId;
    print('UsageStatsService user set to: $userId');
  }

  // ===== PERMISSIONS =====

  /// Request usage stats permission
  Future<bool> requestUsageStatsPermission() async {
    try {
      // Check and request notification permission
      var notificationStatus = await Permission.notification.status;
      if (notificationStatus.isDenied) {
        notificationStatus = await Permission.notification.request();
      }

      // Check and request app usage permission (Android specific)
      // Note: This requires user to manually enable in Settings
      // Real implementation would guide user to Settings > Apps > Special access > Usage access

      print('Usage stats permission check completed');
      return true;
    } catch (e) {
      print('Error requesting usage stats permission: $e');
      return false;
    }
  }

  /// Guide user to usage access settings
  Future<void> openUsageAccessSettings() async {
    try {
      // This would open the usage access settings page
      // Implementation depends on platform-specific code
      print('Opening usage access settings...');
    } catch (e) {
      print('Error opening usage access settings: $e');
    }
  }

  // ===== APP CACHE MANAGEMENT =====

  /// Load app cache from database
  Future<void> _loadAppCache() async {
    try {
      final apps = await _databaseHelper.getAllApps();
      _appCache.clear();

      for (final app in apps) {
        _appCache[app.packageName] = app;
      }

      _lastCacheUpdate = DateTime.now();
      print('Loaded ${_appCache.length} apps into cache');
    } catch (e) {
      print('Error loading app cache: $e');
    }
  }

  /// Get or create app model
  Future<AppModel> _getOrCreateAppModel(
      String packageName, String appName) async {
    // Check cache first
    if (_appCache.containsKey(packageName)) {
      return _appCache[packageName]!;
    }

    // Try to get from database
    try {
      // final existingApp = await _databaseHelper.getAppById(packageName);
      // if (existingApp != null) {
      //   _appCache[packageName] = existingApp;
      //   return existingApp;
      // }
    } catch (e) {
      print('App not found in database: $packageName');
    }

    // Create new app model
    final newApp = AppModel(
      id: packageName,
      name: appName.isNotEmpty ? appName : packageName,
      packageName: packageName,
      icon: _getIconForPackage(packageName),
      iconColor: _generateColorFromString(appName),
      category: _getCategoryForPackage(packageName),
      lastUsed: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // Save to database
      await _databaseHelper.insertApp(newApp);
      _appCache[packageName] = newApp;
      print('Created and cached new app: ${newApp.name}');
    } catch (e) {
      print('Error saving new app to database: $e');
      // Still return the app model even if save fails
      _appCache[packageName] = newApp;
    }

    return newApp;
  }

  /// Get icon for package
  IconData _getIconForPackage(String packageName) {
    final Map<String, IconData> knownIcons = {
      'com.facebook.katana': Icons.facebook,
      'com.instagram.android': Icons.camera_alt,
      'com.whatsapp': Icons.chat,
      'com.google.android.youtube': Icons.play_circle_fill,
      'com.twitter.android': Icons.public,
      'com.zhiliaoapp.musically': Icons.music_note,
      'com.snapchat.android': Icons.camera,
      'com.spotify.music': Icons.music_note,
      'com.netflix.mediaclient': Icons.tv,
      'com.google.android.gm': Icons.email,
      'com.android.chrome': Icons.web,
      'com.google.android.apps.maps': Icons.map,
      'com.tencent.mm': Icons.chat_bubble,
      'jp.naver.line.android': Icons.chat,
      'com.pinterest': Icons.push_pin,
      'com.linkedin.android': Icons.work,
      'com.reddit.frontpage': Icons.forum,
      'com.discord': Icons.headset_mic,
    };

    return knownIcons[packageName] ?? Icons.android;
  }

  /// Generate color from string
  Color _generateColorFromString(String input) {
    final hash = input.hashCode;
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

  /// Get category for package
  String _getCategoryForPackage(String packageName) {
    if (packageName.contains('social') ||
        [
          'com.facebook.katana',
          'com.instagram.android',
          'com.twitter.android',
          'com.snapchat.android',
          'com.zhiliaoapp.musically',
          'com.pinterest',
          'com.linkedin.android',
          'com.reddit.frontpage',
          'com.discord'
        ].contains(packageName)) {
      return 'Social Media';
    }
    if (packageName.contains('game')) return 'Games';
    if (packageName.contains('music') ||
        packageName.contains('video') ||
        [
          'com.spotify.music',
          'com.netflix.mediaclient',
          'com.google.android.youtube'
        ].contains(packageName)) {
      return 'Entertainment';
    }
    if (packageName.contains('work') ||
        packageName.contains('office') ||
        packageName.contains('productivity')) {
      return 'Productivity';
    }
    if ([
      'com.whatsapp',
      'com.google.android.gm',
      'com.tencent.mm',
      'jp.naver.line.android'
    ].contains(packageName)) {
      return 'Communication';
    }
    return 'Other';
  }

  // ===== USAGE TRACKING =====

  /// Start tracking app usage
  void startUsageTracking() {
    if (_isTracking) return;

    _isTracking = true;
    _usageTrackingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _recordCurrentUsage().catchError((error) {
        print('Error in usage tracking timer: $error');
      });
    });

    print('Usage tracking started');
  }

  /// Stop tracking app usage
  void stopUsageTracking() {
    _usageTrackingTimer?.cancel();
    _syncTimer?.cancel();
    _isTracking = false;
    print('Usage tracking stopped');
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (_currentUserId != null) {
        syncUsageData(_currentUserId!).catchError((error) {
          print('Error in periodic sync: $error');
        });
      }
    });
  }

  /// Record current usage data
  Future<void> _recordCurrentUsage() async {
    if (_currentUserId == null) return;

    try {
      final now = DateTime.now();
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

      List<AppUsageInfo> appUsage =
          await AppUsage().getAppUsage(oneMinuteAgo, now);

      for (var usage in appUsage) {
        if (usage.usage.inSeconds >
                10 && // Only track meaningful usage (>10 seconds)
            usage.packageName.isNotEmpty &&
            !_isSystemApp(usage.packageName)) {
          // Get or create app model
          final appModel =
              await _getOrCreateAppModel(usage.packageName, usage.appName);

          // Create usage log entry
          final logId =
              '${_currentUserId}_${usage.packageName}_${now.millisecondsSinceEpoch}';
          final usageLog = UsageLogModel(
            id: logId,
            userId: _currentUserId!,
            appId: appModel.id,
            appPackageName: usage.packageName,
            appName: usage.appName,
            date: now,
            duration: usage.usage,
            wasBlocked: false, // Will be updated by blocking service
            openCount: 1,
            firstOpenTime: oneMinuteAgo,
            lastOpenTime: now,
            totalUsageMinutes: usage.usage.inMinutes,
          );

          await _usageLogDao.insertOrUpdateUsageLog(usageLog);

          // Update app's last used time
          try {
            final dailyUsage = await _calculateDailyUsage(appModel.id);
            final updatedApp = appModel.copyWith(
              lastUsed: now,
              dailyUsage: dailyUsage,
              updatedAt: now,
            );
            // await _databaseHelper.updateApp(updatedApp);
            _appCache[usage.packageName] = updatedApp;
          } catch (e) {
            print('Error updating app last used time: $e');
          }
        }
      }
    } catch (e) {
      print('Error recording usage: $e');
    }
  }

  /// Calculate daily usage for an app
  Future<Duration> _calculateDailyUsage(String appId) async {
    if (_currentUserId == null) return Duration.zero;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final logs = await _usageLogDao.getUsageLogsForPeriod(
        _currentUserId!,
        startOfDay,
        endOfDay,
        appId: appId,
      );

      Duration total = Duration.zero;
      for (final log in logs) {
        total += log.duration;
      }

      return total;
    } catch (e) {
      print('Error calculating daily usage: $e');
      return Duration.zero;
    }
  }

  /// Check if app is a system app
  bool _isSystemApp(String packageName) {
    final systemApps = [
      'com.android.systemui',
      'android',
      'com.android.launcher',
      'com.google.android.inputmethod',
      'com.android.settings',
      'com.android.vending', // Play Store
      'com.google.android.packageinstaller',
    ];

    return systemApps.any((system) => packageName.contains(system)) ||
        packageName.startsWith('com.android.') ||
        packageName.startsWith('com.google.android.gms') ||
        packageName.startsWith('com.samsung.android') ||
        packageName.startsWith('com.miui') ||
        packageName.startsWith('com.huawei');
  }

  // ===== USAGE STATISTICS =====

  /// Get app usage for today
  Future<Map<String, Duration>> getTodayUsageStats() async {
    try {
      final DateTime endDate = DateTime.now();
      final DateTime startDate =
          DateTime(endDate.year, endDate.month, endDate.day);

      List<AppUsageInfo> appUsage =
          await AppUsage().getAppUsage(startDate, endDate);

      Map<String, Duration> usageMap = {};
      for (var app in appUsage) {
        if (app.packageName.isNotEmpty && !_isSystemApp(app.packageName)) {
          usageMap[app.packageName] = app.usage;
        }
      }

      return usageMap;
    } catch (e) {
      print('Failed to get usage stats: $e');
      return {};
    }
  }

  /// Get usage for a specific time range
  Future<Map<String, Duration>> getUsageStatsForRange(
      DateTime startDate, DateTime endDate) async {
    try {
      List<AppUsageInfo> appUsage =
          await AppUsage().getAppUsage(startDate, endDate);

      Map<String, Duration> usageMap = {};
      for (var app in appUsage) {
        if (!_isSystemApp(app.packageName)) {
          usageMap[app.packageName] = app.usage;
        }
      }

      return usageMap;
    } catch (e) {
      print('Failed to get usage stats: $e');
      return {};
    }
  }

  /// Get detailed usage info with app names
  Future<List<AppUsageInfo>> getDetailedUsageStats(
      DateTime startDate, DateTime endDate) async {
    try {
      List<AppUsageInfo> appUsage =
          await AppUsage().getAppUsage(startDate, endDate);

      // Filter out system apps and sort by usage time
      appUsage = appUsage
          .where((app) => !_isSystemApp(app.packageName))
          .toList()
        ..sort((a, b) => b.usage.compareTo(a.usage));

      return appUsage;
    } catch (e) {
      print('Failed to get detailed usage stats: $e');
      return [];
    }
  }

  /// Get total usage time for a period
  Future<Duration> getTotalUsageForPeriod(
      DateTime startDate, DateTime endDate) async {
    try {
      Map<String, Duration> usageMap =
          await getUsageStatsForRange(startDate, endDate);

      Duration total = Duration.zero;
      for (var duration in usageMap.values) {
        total += duration;
      }

      return total;
    } catch (e) {
      print('Error calculating total usage: $e');
      return Duration.zero;
    }
  }

  /// Get usage statistics from local database
  Future<Duration> getTotalUsageFromLocal(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      List<UsageLogModel> logs =
          await _usageLogDao.getUsageLogsForPeriod(userId, startDate, endDate);

      Duration total = Duration.zero;
      for (var log in logs) {
        total += log.duration;
      }

      return total;
    } catch (e) {
      print('Error getting usage from local DB: $e');
      return Duration.zero;
    }
  }

  /// Get comprehensive usage summary
  Future<Map<String, dynamic>> getUsageSummary(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final summary =
          await _usageLogDao.getUsageSummary(userId, startDate, endDate);

      // Add additional calculated metrics
      final totalDuration = summary['totalDuration'] as Duration;
      final activeDays = summary['activeDays'] as int;
      final totalLogs = summary['totalLogs'] as int;

      return {
        ...summary,
        'averageSessionDuration': totalLogs > 0
            ? Duration(milliseconds: totalDuration.inMilliseconds ~/ totalLogs)
            : Duration.zero,
        'screenTimePercentage': activeDays > 0
            ? (totalDuration.inHours / (activeDays * 24)) * 100
            : 0.0,
        'productivity_score': _calculateProductivityScore(summary),
      };
    } catch (e) {
      print('Error getting usage summary: $e');
      return {
        'totalLogs': 0,
        'totalDuration': Duration.zero,
        'totalOpens': 0,
        'blockedSessions': 0,
        'uniqueApps': 0,
        'activeDays': 0,
        'averageSessionDuration': Duration.zero,
        'screenTimePercentage': 0.0,
        'productivity_score': 0.0,
      };
    }
  }

  /// Calculate productivity score (0-100)
  double _calculateProductivityScore(Map<String, dynamic> summary) {
    final totalDuration = (summary['totalDuration'] as Duration).inHours;
    final blockedSessions = summary['blockedSessions'] as int;
    final totalLogs = summary['totalLogs'] as int;

    if (totalLogs == 0) return 100.0;

    // Base score from blocked sessions ratio
    final blockedRatio = blockedSessions / totalLogs;
    double score = blockedRatio * 50; // Max 50 points for blocking

    // Calculate daily average usage
    final activeDays = summary['activeDays'] as int;
    final dailyAverage =
        activeDays > 0 ? totalDuration / activeDays : totalDuration;

    // Penalty for excessive usage (>8 hours daily average)
    if (dailyAverage > 8) {
      score -= (dailyAverage - 8) * 5; // -5 points per hour over 8
    } else {
      score += (8 - dailyAverage) * 2; // +2 points per hour under 8
    }

    return score.clamp(0.0, 100.0);
  }

  /// Get daily average usage for a period
  Future<Duration> getDailyAverageUsage(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      Duration totalUsage =
          await getTotalUsageFromLocal(userId, startDate, endDate);
      int daysDifference = endDate.difference(startDate).inDays + 1;

      if (daysDifference > 0) {
        return Duration(
            milliseconds: totalUsage.inMilliseconds ~/ daysDifference);
      }

      return Duration.zero;
    } catch (e) {
      print('Error calculating daily average: $e');
      return Duration.zero;
    }
  }

  /// Get most used apps for a period
  Future<List<Map<String, dynamic>>> getMostUsedApps(
      String userId, DateTime startDate, DateTime endDate,
      {int limit = 10}) async {
    try {
      List<UsageLogModel> logs =
          await _usageLogDao.getUsageLogsForPeriod(userId, startDate, endDate);

      Map<String, Duration> appUsageMap = {};
      Map<String, String> appNameMap = {};
      Map<String, int> openCountMap = {};

      for (var log in logs) {
        final key = log.appPackageName ?? log.appId;
        appUsageMap[key] = (appUsageMap[key] ?? Duration.zero) + log.duration;
        appNameMap[key] = log.appName ?? key;
        openCountMap[key] = (openCountMap[key] ?? 0) + log.openCount;
      }

      var sortedApps = appUsageMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedApps.take(limit).map((entry) {
        final packageName = entry.key;
        final usageTime = entry.value;
        final openCount = openCountMap[packageName] ?? 0;

        return {
          'packageName': packageName,
          'appName': appNameMap[packageName] ?? packageName,
          'usageTime': usageTime,
          'openCount': openCount,
          'averageSessionTime': openCount > 0
              ? Duration(milliseconds: usageTime.inMilliseconds ~/ openCount)
              : Duration.zero,
          'category': _getCategoryForPackage(packageName),
        };
      }).toList();
    } catch (e) {
      print('Error getting most used apps: $e');
      return [];
    }
  }

  /// Get screen pickup count (estimated from app usage patterns)
  Future<int> getScreenPickupsCount(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      List<UsageLogModel> logs =
          await _usageLogDao.getUsageLogsForPeriod(userId, startDate, endDate);

      // Sort by date
      logs.sort((a, b) => a.date.compareTo(b.date));

      int pickups = 0;
      String? lastApp;
      DateTime? lastTime;

      for (var log in logs) {
        final currentApp = log.appPackageName ?? log.appId;
        final currentTime = log.date;

        if (lastApp != null && lastTime != null) {
          // Count as new pickup if:
          // 1. Different app, OR
          // 2. Same app but >30 minutes gap (likely phone was put down)
          if (currentApp != lastApp ||
              currentTime.difference(lastTime).inMinutes > 30) {
            pickups++;
          }
        } else {
          pickups = 1; // First usage of the period
        }

        // Add open count as additional pickups within the same app
        pickups += log.openCount;

        lastApp = currentApp;
        lastTime = currentTime;
      }

      return pickups;
    } catch (e) {
      print('Error calculating screen pickups: $e');
      return 0;
    }
  }

  // ===== REAL-TIME MONITORING =====

  /// Check if app is currently in foreground
  Future<bool> isAppInForeground(String packageName) async {
    try {
      final now = DateTime.now();
      final recent = now.subtract(const Duration(seconds: 30));

      List<AppUsageInfo> recentUsage =
          await AppUsage().getAppUsage(recent, now);

      for (var usage in recentUsage) {
        if (usage.packageName == packageName && usage.usage.inSeconds > 0) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking foreground app: $e');
      return false;
    }
  }

  /// Get currently active app
  Future<String?> getCurrentActiveApp() async {
    try {
      final now = DateTime.now();
      final recent = now.subtract(const Duration(seconds: 10));

      List<AppUsageInfo> recentUsage =
          await AppUsage().getAppUsage(recent, now);

      if (recentUsage.isNotEmpty) {
        // Sort by usage time and get the most recent
        recentUsage.sort((a, b) => b.usage.compareTo(a.usage));
        return recentUsage.first.packageName;
      }

      return null;
    } catch (e) {
      print('Error getting current active app: $e');
      return null;
    }
  }

  // ===== APP MANAGEMENT =====

  /// Get installed apps
  Future<List<AppModel>> getInstalledApps({bool forceRefresh = false}) async {
    try {
      // Check if cache needs refresh
      if (forceRefresh ||
          DateTime.now().difference(_lastCacheUpdate).inHours > 24 ||
          _appCache.isEmpty) {
        await _loadAppCache();
      }

      // If cache is still empty, load from device
      if (_appCache.isEmpty) {
        List<Application> deviceApps =
            await DeviceApps.getInstalledApplications(
          includeAppIcons: true,
          includeSystemApps: false,
          onlyAppsWithLaunchIntent: true,
        );

        for (final deviceApp in deviceApps) {
          await _getOrCreateAppModel(deviceApp.packageName, deviceApp.appName);
        }
      }

      return _appCache.values.toList();
    } catch (e) {
      print('Error getting installed apps: $e');
      return [];
    }
  }

  /// Get app info by package name
  Future<AppModel?> getAppInfo(String packageName) async {
    try {
      if (_appCache.containsKey(packageName)) {
        return _appCache[packageName];
      }

      // Try to get app name from device
      final deviceApps = await DeviceApps.getInstalledApplications();
      final deviceApp = deviceApps.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => throw StateError('Not found'),
      );

      return await _getOrCreateAppModel(packageName, deviceApp.appName);
    } catch (e) {
      print('Error getting app info for $packageName: $e');
      return null;
    }
  }

  // ===== SYNC & MAINTENANCE =====

  /// Sync usage data with cloud/backend
  Future<void> syncUsageData(String userId) async {
    try {
      final success = await _usageLogDao.syncLogsToCloud(userId);
      if (success) {
        print('Successfully synced usage data for user: $userId');
      } else {
        print('Failed to sync usage data for user: $userId');
      }
    } catch (e) {
      print('Error syncing usage data: $e');
    }
  }

  /// Clean old usage data
  Future<void> cleanOldUsageData({int daysToKeep = 90}) async {
    try {
      final deletedCount = await _usageLogDao.cleanupOldLogs();
      print('Cleaned $deletedCount usage records older than $daysToKeep days');
    } catch (e) {
      print('Error cleaning old usage data: $e');
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      return await _usageLogDao.getDatabaseStats();
    } catch (e) {
      print('Error getting database stats: $e');
      return {};
    }
  }

  // ===== UTILITY METHODS =====

  /// Format duration to human readable string
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Format short duration (for quick display)
  String formatShortDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '<1m';
    }
  }

  /// Get usage color based on duration
  Color getUsageColor(Duration duration) {
    final hours = duration.inHours;

    if (hours < 1) return Colors.green;
    if (hours < 3) return Colors.orange;
    if (hours < 6) return Colors.red;
    return Colors.purple;
  }

  /// Export usage data as JSON
  Future<String> exportUsageData(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final logs =
          await _usageLogDao.getUsageLogsForPeriod(userId, startDate, endDate);
      final summary = await getUsageSummary(userId, startDate, endDate);

      final exportData = {
        'user_id': userId,
        'export_date': DateTime.now().toIso8601String(),
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'summary': summary,
        'usage_logs': logs.map((log) => log.toJsonMap()).toList(),
      };

      return json.encode(exportData);
    } catch (e) {
      print('Error exporting usage data: $e');
      return '{}';
    }
  }

  // ===== ADVANCED ANALYTICS =====

  /// Get usage trends for the past week
  Future<List<Map<String, dynamic>>> getWeeklyUsageTrends(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      List<Map<String, dynamic>> trends = [];

      for (int i = 0; i < 7; i++) {
        final day = weekAgo.add(Duration(days: i));
        final startOfDay = DateTime(day.year, day.month, day.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final dailyUsage =
            await getTotalUsageFromLocal(userId, startOfDay, endOfDay);
        final logs = await _usageLogDao.getUsageLogsForPeriod(
            userId, startOfDay, endOfDay);

        trends.add({
          'date': startOfDay,
          'totalUsage': dailyUsage,
          'sessionCount': logs.length,
          'averageSession': logs.isNotEmpty
              ? Duration(milliseconds: dailyUsage.inMilliseconds ~/ logs.length)
              : Duration.zero,
          'dayOfWeek': _getDayOfWeek(startOfDay.weekday),
        });
      }

      return trends;
    } catch (e) {
      print('Error getting weekly trends: $e');
      return [];
    }
  }

  /// Get category-wise usage breakdown
  Future<Map<String, Duration>> getCategoryUsageBreakdown(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final logs =
          await _usageLogDao.getUsageLogsForPeriod(userId, startDate, endDate);
      Map<String, Duration> categoryUsage = {};

      for (final log in logs) {
        final category =
            _getCategoryForPackage(log.appPackageName ?? log.appId);
        categoryUsage[category] =
            (categoryUsage[category] ?? Duration.zero) + log.duration;
      }

      return categoryUsage;
    } catch (e) {
      print('Error getting category breakdown: $e');
      return {};
    }
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // ===== LIFECYCLE MANAGEMENT =====

  /// Dispose of resources
  void dispose() {
    stopUsageTracking();
    _appCache.clear();
    _isInitialized = false;
    _currentUserId = null;
    print('UsageStatsService disposed');
  }

  /// Reset service (for testing or user logout)
  Future<void> reset() async {
    dispose();
    _isInitialized = false;
  }

  /// Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'isInitialized': _isInitialized,
      'isTracking': _isTracking,
      'currentUserId': _currentUserId,
      'appCacheSize': _appCache.length,
      'lastCacheUpdate': _lastCacheUpdate,
    };
  }
}
