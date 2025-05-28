import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

import '../local/models/app_model.dart';
import '../local/models/schedule_model.dart';
import '../local/models/usage_log_model.dart';

class AppBlockerService {
  static final AppBlockerService _instance = AppBlockerService._internal();
  late Database _database;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Factory constructor
  factory AppBlockerService() {
    return _instance;
  }

  AppBlockerService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Initialize SQLite database
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'app_blocker.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create tables
        await db.execute('''
          CREATE TABLE blocked_apps (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            package_name TEXT NOT NULL,
            icon_data TEXT NOT NULL,
            icon_color INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE schedules (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            icon_data TEXT NOT NULL,
            icon_color INTEGER NOT NULL,
            days TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            blocked_apps TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE usage_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            app_id TEXT NOT NULL,
            date TEXT NOT NULL,
            duration INTEGER NOT NULL,
            was_blocked INTEGER NOT NULL,
            schedule_id TEXT
          )
        ''');
      },
    );

    _isInitialized = true;
  }

  // App-related methods
  Future<List<AppModel>> getInstalledApps() async {
    // In a real app, this would use platform-specific code to get the actual installed apps
    // For this example, we'll return a mock list
    return [
      AppModel(
        id: '1',
        name: 'Facebook',
        packageName: 'com.facebook.katana',
        icon: Icons.facebook,
        iconColor: Colors.blue,
      ),
      AppModel(
        id: '2',
        name: 'WhatsApp',
        packageName: 'com.whatsapp',
        icon: Icons.chat,
        iconColor: Colors.green,
      ),
      AppModel(
        id: '3',
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        icon: Icons.play_circle_fill,
        iconColor: Colors.red,
      ),
      AppModel(
        id: '4',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        icon: Icons.camera_alt,
        iconColor: Colors.purple,
      ),
      AppModel(
        id: '5',
        name: 'Twitter',
        packageName: 'com.twitter.android',
        icon: Icons.public,
        iconColor: Colors.lightBlue,
      ),
      AppModel(
        id: '6',
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        icon: Icons.music_note,
        iconColor: Colors.black,
      ),
      AppModel(
        id: '7',
        name: 'Snapchat',
        packageName: 'com.snapchat.android',
        icon: Icons.camera,
        iconColor: Colors.yellow,
      ),
      AppModel(
        id: '8',
        name: 'Pinterest',
        packageName: 'com.pinterest',
        icon: Icons.push_pin,
        iconColor: Colors.red,
      ),
    ];
  }

  Future<List<AppModel>> getBlockedApps() async {
    final List<Map<String, dynamic>> maps =
        await _database.query('blocked_apps');

    return List.generate(maps.length, (i) {
      final iconData = IconData(
        int.parse(maps[i]['icon_data']),
        fontFamily: 'MaterialIcons',
      );

      return AppModel(
        id: maps[i]['id'],
        name: maps[i]['name'],
        packageName: maps[i]['package_name'],
        icon: iconData,
        iconColor: Color(maps[i]['icon_color']),
      );
    });
  }

  Future<void> addBlockedApp(AppModel app) async {
    await _database.insert(
      'blocked_apps',
      {
        'id': app.id,
        'name': app.name,
        'package_name': app.packageName,
        'icon_data': app.icon.codePoint.toString(),
        'icon_color': app.iconColor.value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBlockedApp(String appId) async {
    await _database.delete(
      'blocked_apps',
      where: 'id = ?',
      whereArgs: [appId],
    );
  }

  // Quick Block mode methods
  Future<void> setQuickBlockActive(bool isActive) async {
    await _prefs.setBool('quick_block_active', isActive);
    if (isActive) {
      await _prefs.setInt(
          'quick_block_start_time', DateTime.now().millisecondsSinceEpoch);
    }
  }

  bool isQuickBlockActive() {
    return _prefs.getBool('quick_block_active') ?? false;
  }

  Future<void> setQuickBlockDuration(Duration duration) async {
    await _prefs.setInt('quick_block_duration', duration.inSeconds);
  }

  Duration getQuickBlockDuration() {
    final seconds =
        _prefs.getInt('quick_block_duration') ?? 3600; // Default: 1 hour
    return Duration(seconds: seconds);
  }

  DateTime? getQuickBlockEndTime() {
    if (!isQuickBlockActive()) return null;

    final startTimeMillis = _prefs.getInt('quick_block_start_time') ?? 0;
    if (startTimeMillis == 0) return null;

    final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    final durationSeconds = _prefs.getInt('quick_block_duration') ?? 3600;

    return startTime.add(Duration(seconds: durationSeconds));
  }

  // Schedule-related methods
  Future<List<ScheduleModel>> getSchedules() async {
    final List<Map<String, dynamic>> maps = await _database.query('schedules');

    return List.generate(maps.length, (i) {
      final iconData = IconData(
        int.parse(maps[i]['icon_data']),
        fontFamily: 'MaterialIcons',
      );

      final daysJson = jsonDecode(maps[i]['days']) as List;
      final days = daysJson.map((day) => day as int).toList();

      final startTimeParts = maps[i]['start_time'].split(':');
      final startTime = TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      );

      final endTimeParts = maps[i]['end_time'].split(':');
      final endTime = TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      );

      final blockedAppsJson = jsonDecode(maps[i]['blocked_apps']) as List;
      final blockedApps = blockedAppsJson.map((app) => app as String).toList();

      return ScheduleModel(
        id: maps[i]['id'],
        title: maps[i]['title'],
        icon: iconData,
        iconColor: Color(maps[i]['icon_color']),
        days: days,
        startTime: startTime,
        endTime: endTime,
        blockedApps: blockedApps,
      );
    });
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    await _database.insert(
      'schedules',
      {
        'id': schedule.id,
        'title': schedule.title,
        'icon_data': schedule.icon.codePoint.toString(),
        'icon_color': schedule.iconColor.value,
        'days': jsonEncode(schedule.days),
        'start_time': '${schedule.startTime.hour}:${schedule.startTime.minute}',
        'end_time': '${schedule.endTime.hour}:${schedule.endTime.minute}',
        'blocked_apps': jsonEncode(schedule.blockedApps),
        'is_active': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    await _database.update(
      'schedules',
      {
        'title': schedule.title,
        'icon_data': schedule.icon.codePoint.toString(),
        'icon_color': schedule.iconColor.value,
        'days': jsonEncode(schedule.days),
        'start_time': '${schedule.startTime.hour}:${schedule.startTime.minute}',
        'end_time': '${schedule.endTime.hour}:${schedule.endTime.minute}',
        'blocked_apps': jsonEncode(schedule.blockedApps),
      },
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<void> toggleScheduleActive(String scheduleId, bool isActive) async {
    await _database.update(
      'schedules',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _database.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  // Usage log methods
  Future<void> logAppUsage(UsageLogModel log) async {
    await _database.insert(
      'usage_logs',
      {
        'app_id': log.appId,
        'date': log.date.toIso8601String(),
        'duration': log.duration.inSeconds,
        'was_blocked': log.wasBlocked ? 1 : 0,
        'schedule_id': log.scheduleId,
      },
    );
  }

  Future<Map<String, Duration>> getTodayUsageStats() async {
    final today = DateTime.now();
    final dateString = DateTime(today.year, today.month, today.day)
        .toIso8601String()
        .split('T')[0];

    final List<Map<String, dynamic>> maps = await _database.rawQuery('''
      SELECT app_id, SUM(duration) as total_duration
      FROM usage_logs
      WHERE date LIKE '$dateString%'
      GROUP BY app_id
    ''');

    final Map<String, Duration> result = {};
    for (var map in maps) {
      result[map['app_id']] = Duration(seconds: map['total_duration']);
    }

    return result;
  }

  Future<int> getUnblockCount() async {
    final today = DateTime.now();
    final dateString = DateTime(today.year, today.month, today.day)
        .toIso8601String()
        .split('T')[0];

    final result = await _database.rawQuery('''
      SELECT COUNT(*) as count
      FROM usage_logs
      WHERE date LIKE '$dateString%' AND was_blocked = 1
    ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Duration> getTotalSavedTime() async {
    final today = DateTime.now();
    final dateString = DateTime(today.year, today.month, today.day)
        .toIso8601String()
        .split('T')[0];

    final result = await _database.rawQuery('''
      SELECT SUM(duration) as total_duration
      FROM usage_logs
      WHERE date LIKE '$dateString%' AND was_blocked = 1
    ''');

    final seconds = Sqflite.firstIntValue(result) ?? 0;
    return Duration(seconds: seconds);
  }

  // Check if app should be blocked
  bool shouldBlockApp(String packageName) {
    // Check if Quick Block is active
    if (isQuickBlockActive()) {
      final endTime = getQuickBlockEndTime();
      if (endTime != null && DateTime.now().isBefore(endTime)) {
        // Quick Block is still active
        return true;
      } else {
        // Quick Block has expired, deactivate it
        setQuickBlockActive(false);
      }
    }

    // TODO: Check if app is blocked by any active schedule
    // This would require checking the current day and time against all active schedules

    return false;
  }
}
