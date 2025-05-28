// data/repositories/database_helper.dart
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_model.dart';
import '../models/schedule_model.dart';
import '../models/usage_log_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initDatabase() async {
    try {
      _database = await _initDatabase();
      print('Database initialized successfully');
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'app_blocker.db');

      print('Database path: $path');

      return await openDatabase(
        path,
        version: 6, // Increased version to force recreation
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          print('Database opened successfully');
          await _verifyTables(db);
        },
      );
    } catch (e) {
      print('Error creating database: $e');
      rethrow;
    }
  }

  Future<void> _verifyTables(Database db) async {
    try {
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      print('Tables in database: ${tables.map((t) => t['name']).toList()}');

      // Check if apps table exists and has correct structure
      final appsTableInfo = await db.rawQuery("PRAGMA table_info(apps)");
      print('Apps table structure: $appsTableInfo');
    } catch (e) {
      print('Error verifying tables: $e');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    print('Creating database tables...');

    try {
      // Create users table (existing + enhanced)
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          photoUrl TEXT,
          isPremium INTEGER NOT NULL DEFAULT 0,
          premiumExpiryDate INTEGER,
          maxPlansAllowed INTEGER NOT NULL DEFAULT 5,
          maxAppsPerPlan INTEGER NOT NULL DEFAULT 3,
          createdAt INTEGER NOT NULL,
          lastLoginAt INTEGER,
          updatedAt INTEGER NOT NULL,
          totalBlockedTime INTEGER DEFAULT 0,
          streakDays INTEGER DEFAULT 0,
          totalDownloads INTEGER DEFAULT 100
        )
      ''');
      print('Users table created');

      // Create usage logs table (fallback creation)
      await db.execute('''
        CREATE TABLE usage_logs (
          id TEXT PRIMARY KEY,
          appId TEXT NOT NULL,
          date INTEGER NOT NULL,
          durationSeconds INTEGER NOT NULL,
          wasBlocked INTEGER NOT NULL DEFAULT 0,
          scheduleId TEXT,
          openCount INTEGER DEFAULT 0,
          firstOpenTime INTEGER,
          lastOpenTime INTEGER,
          createdAt INTEGER NOT NULL
        )
      ''');
      print('Usage logs table created');

      // Create apps table - THIS IS THE CRITICAL TABLE
      await db.execute('''
        CREATE TABLE apps (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          packageName TEXT NOT NULL UNIQUE,
          iconCodePoint INTEGER NOT NULL,
          iconFontFamily TEXT DEFAULT 'MaterialIcons',
          iconColor INTEGER NOT NULL,
          isBlocked INTEGER DEFAULT 0,
          lastUsed INTEGER,
          dailyUsageSeconds INTEGER,
          isSystemApp INTEGER DEFAULT 0,
          category TEXT DEFAULT 'Other',
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
        )
      ''');
      print('Apps table created');

      // Create blocked apps table (existing + enhanced)
      await db.execute('''
        CREATE TABLE blocked_apps (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          appId TEXT NOT NULL,
          packageName TEXT NOT NULL,
          appName TEXT NOT NULL,
          isBlocked INTEGER NOT NULL DEFAULT 1,
          blockedAt INTEGER NOT NULL,
          blockDuration INTEGER,
          scheduleId TEXT,
          isQuickBlock INTEGER DEFAULT 0,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (appId) REFERENCES apps (id) ON DELETE CASCADE
        )
      ''');
      print('Blocked apps table created');

      // Create schedules table (existing + enhanced)
      await db.execute('''
        CREATE TABLE schedules (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          name TEXT,
          iconCodePoint INTEGER NOT NULL,
          iconFontFamily TEXT DEFAULT 'MaterialIcons',
          iconColor INTEGER NOT NULL,
          days TEXT NOT NULL,
          daysOfWeek TEXT,
          startTime TEXT,
          endTime TEXT,
          startTimeHour INTEGER NOT NULL,
          startTimeMinute INTEGER NOT NULL,
          endTimeHour INTEGER NOT NULL,
          endTimeMinute INTEGER NOT NULL,
          blockedApps TEXT NOT NULL,
          isActive INTEGER DEFAULT 1,
          createdAt INTEGER NOT NULL,
          lastTriggered INTEGER,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      print('Schedules table created');

      // Create quick blocks table (existing + enhanced)
      await db.execute('''
        CREATE TABLE quick_blocks (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          duration INTEGER NOT NULL,
          startTime INTEGER NOT NULL,
          endTime INTEGER NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1,
          blockedApps TEXT NOT NULL DEFAULT '[]',
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      print('Quick blocks table created');

      // Create subscriptions table (existing)
      await db.execute('''
        CREATE TABLE subscriptions (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          planType TEXT NOT NULL,
          status TEXT NOT NULL,
          startDate INTEGER NOT NULL,
          endDate INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      print('Subscriptions table created');

      // Create usage_logs_v2 table (enhanced version)
      await db.execute('''
        CREATE TABLE usage_logs_v2 (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          appId TEXT NOT NULL,
          date INTEGER NOT NULL,
          durationSeconds INTEGER NOT NULL,
          wasBlocked INTEGER NOT NULL,
          scheduleId TEXT,
          openCount INTEGER DEFAULT 0,
          firstOpenTime INTEGER,
          lastOpenTime INTEGER,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (appId) REFERENCES apps (id) ON DELETE CASCADE
        )
      ''');
      print('Usage logs v2 table created');

      // Create settings table
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          type TEXT NOT NULL,
          userId TEXT,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      print('Settings table created');

      // Create app categories table (for better organization)
      await db.execute('''
        CREATE TABLE app_categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          iconCodePoint INTEGER NOT NULL,
          iconColor INTEGER NOT NULL,
          isDefault INTEGER DEFAULT 0,
          createdAt INTEGER NOT NULL
        )
      ''');
      print('App categories table created');

      // Create notification logs table
      await db.execute('''
        CREATE TABLE notification_logs (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          isRead INTEGER DEFAULT 0,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      print('Notification logs table created');

      // Create mood tracking table
      await db.execute('''
        CREATE TABLE mood_logs (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          moodLevel INTEGER NOT NULL CHECK (moodLevel >= 1 AND moodLevel <= 5),
          notes TEXT,
          date INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      print('Mood logs table created');

      // Create indexes for better performance
      await db.execute(
          'CREATE INDEX idx_usage_logs_v2_date ON usage_logs_v2(date)');
      await db.execute(
          'CREATE INDEX idx_usage_logs_v2_user_app ON usage_logs_v2(userId, appId)');
      await db.execute(
          'CREATE INDEX idx_blocked_apps_user ON blocked_apps(userId)');
      await db.execute(
          'CREATE INDEX idx_blocked_apps_app_id ON blocked_apps(appId)');
      await db
          .execute('CREATE INDEX idx_schedules_active ON schedules(isActive)');
      await db.execute('CREATE INDEX idx_schedules_user ON schedules(userId)');
      await db.execute(
          'CREATE INDEX idx_quick_blocks_active ON quick_blocks(isActive)');
      await db.execute(
          'CREATE INDEX idx_quick_blocks_user ON quick_blocks(userId)');
      await db.execute('CREATE INDEX idx_apps_package ON apps(packageName)');
      await db.execute('CREATE INDEX idx_settings_user ON settings(userId)');
      await db.execute(
          'CREATE INDEX idx_mood_logs_user_date ON mood_logs(userId, date)');
      print('Indexes created');

      // Insert default app categories
      await _insertDefaultCategories(db);

      print('Database tables created successfully with version $version');
    } catch (e) {
      print('Error creating tables: $e');
      rethrow;
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final categories = [
        {
          'id': 'social_media',
          'name': 'Social Media',
          'iconCodePoint': Icons.people.codePoint,
          'iconColor': Colors.blue.value,
          'isDefault': 1,
          'createdAt': now,
        },
        {
          'id': 'entertainment',
          'name': 'Entertainment',
          'iconCodePoint': Icons.tv.codePoint,
          'iconColor': Colors.purple.value,
          'isDefault': 1,
          'createdAt': now,
        },
        {
          'id': 'games',
          'name': 'Games',
          'iconCodePoint': Icons.games.codePoint,
          'iconColor': Colors.red.value,
          'isDefault': 1,
          'createdAt': now,
        },
        {
          'id': 'productivity',
          'name': 'Productivity',
          'iconCodePoint': Icons.work.codePoint,
          'iconColor': Colors.green.value,
          'isDefault': 1,
          'createdAt': now,
        },
        {
          'id': 'communication',
          'name': 'Communication',
          'iconCodePoint': Icons.chat.codePoint,
          'iconColor': Colors.orange.value,
          'isDefault': 1,
          'createdAt': now,
        },
      ];

      for (final category in categories) {
        await db.insert('app_categories', category,
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      print('Default categories inserted');
    } catch (e) {
      print('Error inserting default categories: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    try {
      // For major schema changes, recreate all tables
      if (oldVersion < 6) {
        // Drop all existing tables
        await db.execute('DROP TABLE IF EXISTS mood_logs');
        await db.execute('DROP TABLE IF EXISTS notification_logs');
        await db.execute('DROP TABLE IF EXISTS app_categories');
        await db.execute('DROP TABLE IF EXISTS settings');
        await db.execute('DROP TABLE IF EXISTS usage_logs_v2');
        await db.execute('DROP TABLE IF EXISTS subscriptions');
        await db.execute('DROP TABLE IF EXISTS quick_blocks');
        await db.execute('DROP TABLE IF EXISTS schedules');
        await db.execute('DROP TABLE IF EXISTS blocked_apps');
        await db.execute('DROP TABLE IF EXISTS usage_logs');
        await db.execute('DROP TABLE IF EXISTS apps');
        await db.execute('DROP TABLE IF EXISTS users');

        // Recreate all tables
        await _createTables(db, newVersion);
      }
    } catch (e) {
      print('Error during database upgrade: $e');
      rethrow;
    }
  }

  // ===== QUICK MODE OPERATIONS =====

  Future<String> startQuickMode({
    required String userId,
    required int durationMinutes,
    required List<String> blockedAppIds,
  }) async {
    final db = await database;

    try {
      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: durationMinutes));
      final quickBlockId = 'quick_${now.millisecondsSinceEpoch}';

      await db.insert(
        'quick_blocks',
        {
          'id': quickBlockId,
          'userId': userId,
          'duration': durationMinutes,
          'startTime': now.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
          'isActive': 1,
          'blockedApps': jsonEncode(blockedAppIds),
          'createdAt': now.millisecondsSinceEpoch,
          'updatedAt': now.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('Quick Mode started successfully: $quickBlockId');
      return quickBlockId;
    } catch (e) {
      print('Error starting Quick Mode: $e');
      rethrow;
    }
  }

  Future<void> stopQuickMode(String quickBlockId) async {
    final db = await database;

    try {
      await db.update(
        'quick_blocks',
        {
          'isActive': 0,
          'endTime': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [quickBlockId],
      );

      print('Quick Mode stopped: $quickBlockId');
    } catch (e) {
      print('Error stopping Quick Mode: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getActiveQuickMode(String userId) async {
    final db = await database;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'quick_blocks',
        where: 'userId = ? AND isActive = 1 AND endTime > ?',
        whereArgs: [userId, now],
        orderBy: 'createdAt DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final quickBlock = maps.first;
        return {
          'id': quickBlock['id'],
          'duration': quickBlock['duration'],
          'startTime': quickBlock['startTime'],
          'endTime': quickBlock['endTime'],
          'blockedApps':
              List<String>.from(jsonDecode(quickBlock['blockedApps'] ?? '[]')),
          'remainingTime': quickBlock['endTime'] - now,
        };
      }

      return null;
    } catch (e) {
      print('Error getting active Quick Mode: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getQuickModeHistory(String userId,
      {int? limit}) async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'quick_blocks',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
        limit: limit,
      );

      return maps
          .map((map) => {
                'id': map['id'],
                'duration': map['duration'],
                'startTime': map['startTime'],
                'endTime': map['endTime'],
                'isActive': map['isActive'] == 1,
                'blockedApps':
                    List<String>.from(jsonDecode(map['blockedApps'] ?? '[]')),
                'createdAt': map['createdAt'],
              })
          .toList();
    } catch (e) {
      print('Error getting Quick Mode history: $e');
      return [];
    }
  }

  // ===== MOOD TRACKING OPERATIONS =====

  Future<void> saveMood({
    required String userId,
    required int moodLevel,
    String? notes,
    DateTime? date,
  }) async {
    final db = await database;

    try {
      final moodDate = date ?? DateTime.now();
      final dayStart = DateTime(moodDate.year, moodDate.month, moodDate.day);

      await db.insert(
        'mood_logs',
        {
          'id': '${userId}_${dayStart.millisecondsSinceEpoch}',
          'userId': userId,
          'moodLevel': moodLevel,
          'notes': notes,
          'date': dayStart.millisecondsSinceEpoch,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('Mood saved: Level $moodLevel for $userId');
    } catch (e) {
      print('Error saving mood: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getMoodForDate(
      String userId, DateTime date) async {
    final db = await database;

    try {
      final dayStart = DateTime(date.year, date.month, date.day);

      final List<Map<String, dynamic>> maps = await db.query(
        'mood_logs',
        where: 'userId = ? AND date = ?',
        whereArgs: [userId, dayStart.millisecondsSinceEpoch],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return {
          'moodLevel': maps.first['moodLevel'],
          'notes': maps.first['notes'],
          'date': maps.first['date'],
        };
      }

      return null;
    } catch (e) {
      print('Error getting mood for date: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMoodHistory(String userId,
      {int? days}) async {
    final db = await database;

    try {
      String whereClause = 'userId = ?';
      List<dynamic> whereArgs = [userId];

      if (days != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: days));
        final dayStart =
            DateTime(cutoffDate.year, cutoffDate.month, cutoffDate.day);
        whereClause += ' AND date >= ?';
        whereArgs.add(dayStart.millisecondsSinceEpoch);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'mood_logs',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'date DESC',
      );

      return maps;
    } catch (e) {
      print('Error getting mood history: $e');
      return [];
    }
  }

  Future<void> resetMoodData(String userId) async {
    final db = await database;

    try {
      await db.delete(
        'mood_logs',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      print('Mood data reset for user: $userId');
    } catch (e) {
      print('Error resetting mood data: $e');
      rethrow;
    }
  }

  // ===== USER OPERATIONS (Firebase + Local) =====

  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      // Save to Firestore (commented out for now to avoid Firebase dependency)
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(user.id)
      //     .set(user.toFirestore());

      // Save to local database
      final db = await database;
      await db.insert(
        'users',
        _userToMap(user),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('User saved to local database: ${user.name}');
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      // For now, just use local database
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (maps.isNotEmpty) {
        return _mapToUser(maps.first);
      }

      return null;
    } catch (e) {
      print('Error getting user from local database: $e');
      return null;
    }
  }

  Future<bool> userExists(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return maps.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // ===== APP OPERATIONS =====

  Future<void> insertApp(AppModel app) async {
    final db = await database;

    try {
      await db.insert(
        'apps',
        {
          'id': app.id,
          'name': app.name,
          'packageName': app.packageName,
          'iconCodePoint': app.icon.codePoint,
          'iconFontFamily': app.icon.fontFamily ?? 'MaterialIcons',
          'iconColor': app.iconColor.value,
          'isBlocked': app.isBlocked ? 1 : 0,
          'lastUsed': app.lastUsed?.millisecondsSinceEpoch,
          'dailyUsageSeconds': app.dailyUsage?.inSeconds,
          'isSystemApp': app.isSystemApp ? 1 : 0,
          'category': app.category ?? 'Other',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('App inserted: ${app.name}');
    } catch (e) {
      print('Error inserting app: $e');
      rethrow;
    }
  }

  Future<List<AppModel>> getAllApps() async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query('apps');

      return maps.map((map) {
        return AppModel(
          id: map['id'],
          name: map['name'],
          packageName: map['packageName'],
          icon: IconData(
            map['iconCodePoint'],
            fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
          ),
          iconColor: Color(map['iconColor']),
          isBlocked: map['isBlocked'] == 1,
          lastUsed: map['lastUsed'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastUsed'])
              : null,
          dailyUsage: map['dailyUsageSeconds'] != null
              ? Duration(seconds: map['dailyUsageSeconds'])
              : null,
          isSystemApp: map['isSystemApp'] == 1,
          category: map['category'] ?? 'Other',
        );
      }).toList();
    } catch (e) {
      print('Error getting all apps: $e');
      return [];
    }
  }

  Future<AppModel?> getAppByPackageName(String packageName) async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'apps',
        where: 'packageName = ?',
        whereArgs: [packageName],
      );

      if (maps.isNotEmpty) {
        final map = maps.first;
        return AppModel(
          id: map['id'],
          name: map['name'],
          packageName: map['packageName'],
          icon: IconData(
            map['iconCodePoint'],
            fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
          ),
          iconColor: Color(map['iconColor']),
          isBlocked: map['isBlocked'] == 1,
          lastUsed: map['lastUsed'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastUsed'])
              : null,
          dailyUsage: map['dailyUsageSeconds'] != null
              ? Duration(seconds: map['dailyUsageSeconds'])
              : null,
          isSystemApp: map['isSystemApp'] == 1,
          category: map['category'] ?? 'Other',
        );
      }
      return null;
    } catch (e) {
      print('Error getting app by package name: $e');
      return null;
    }
  }

  // ===== BLOCKED APPS OPERATIONS =====

  Future<void> insertBlockedApp(AppModel app,
      {String? userId, String? scheduleId, bool isQuickBlock = false}) async {
    final db = await database;

    try {
      // First ensure the app exists in apps table
      await insertApp(app);

      // Then add to blocked_apps table
      await db.insert(
        'blocked_apps',
        {
          'id': '${app.id}_${DateTime.now().millisecondsSinceEpoch}',
          'userId': userId ?? 'default_user',
          'appId': app.id,
          'packageName': app.packageName,
          'appName': app.name,
          'isBlocked': 1,
          'blockedAt': DateTime.now().millisecondsSinceEpoch,
          'scheduleId': scheduleId,
          'isQuickBlock': isQuickBlock ? 1 : 0,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Blocked app inserted: ${app.name}');
    } catch (e) {
      print('Error inserting blocked app: $e');
      rethrow;
    }
  }

  Future<void> removeBlockedApp(String appId, {String? userId}) async {
    final db = await database;

    try {
      String whereClause = 'appId = ?';
      List<dynamic> whereArgs = [appId];

      if (userId != null) {
        whereClause += ' AND userId = ?';
        whereArgs.add(userId);
      }

      await db.delete(
        'blocked_apps',
        where: whereClause,
        whereArgs: whereArgs,
      );
      print('Blocked app removed: $appId');
    } catch (e) {
      print('Error removing blocked app: $e');
      rethrow;
    }
  }

  // ===== SCHEDULE OPERATIONS =====

  Future<List<ScheduleModel>> getAllSchedules({String? userId}) async {
    final db = await database;

    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        whereClause = 'WHERE userId = ?';
        whereArgs = [userId];
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM schedules $whereClause ORDER BY createdAt DESC',
        whereArgs,
      );

      return maps.map((map) {
        final days = List<int>.from(jsonDecode(map['days']));
        final blockedApps = List<String>.from(jsonDecode(map['blockedApps']));

        return ScheduleModel(
          id: map['id'],
          title: map['title'],
          icon: IconData(
            map['iconCodePoint'],
            fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
          ),
          iconColor: Color(map['iconColor']),
          days: days,
          startTime: TimeOfDay(
            hour: map['startTimeHour'],
            minute: map['startTimeMinute'],
          ),
          endTime: TimeOfDay(
            hour: map['endTimeHour'],
            minute: map['endTimeMinute'],
          ),
          blockedApps: blockedApps,
          isActive: map['isActive'] == 1,
          createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
          lastTriggered: map['lastTriggered'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastTriggered'])
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error getting schedules: $e');
      return [];
    }
  }

  // ===== USAGE LOG OPERATIONS =====

  Future<void> insertUsageLog(UsageLogModel log, {String? userId}) async {
    final db = await database;

    try {
      await db.insert(
        'usage_logs_v2',
        {
          'id': log.id,
          'userId': userId ?? 'default_user',
          'appId': log.appId,
          'date': log.date.millisecondsSinceEpoch,
          'durationSeconds': log.duration.inSeconds,
          'wasBlocked': log.wasBlocked ? 1 : 0,
          'scheduleId': log.scheduleId,
          'openCount': log.openCount,
          'firstOpenTime': log.firstOpenTime?.millisecondsSinceEpoch,
          'lastOpenTime': log.lastOpenTime?.millisecondsSinceEpoch,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting usage log: $e');
      rethrow;
    }
  }

  Future<List<UsageLogModel>> getUsageLogsForDate(DateTime date,
      {String? userId}) async {
    final db = await database;

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      String whereClause = 'date >= ? AND date < ?';
      List<dynamic> whereArgs = [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch
      ];

      if (userId != null) {
        whereClause += ' AND userId = ?';
        whereArgs.add(userId);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'usage_logs_v2',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'date DESC',
      );

      return maps.map((map) {
        return UsageLogModel(
          id: map['id'],
          appId: map['appId'],
          date: DateTime.fromMillisecondsSinceEpoch(map['date']),
          duration: Duration(seconds: map['durationSeconds']),
          wasBlocked: map['wasBlocked'] == 1,
          scheduleId: map['scheduleId'],
          openCount: map['openCount'] ?? 0,
          firstOpenTime: map['firstOpenTime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['firstOpenTime'])
              : null,
          lastOpenTime: map['lastOpenTime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastOpenTime'])
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error getting usage logs for date: $e');
      return [];
    }
  }

  // ===== UTILITY METHODS =====

  Map<String, dynamic> _userToMap(UserModel user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'photoUrl': user.photoUrl,
      'isPremium': user.isPremium ? 1 : 0,
      'premiumExpiryDate': user.premiumExpiryDate?.millisecondsSinceEpoch,
      'maxPlansAllowed': user.maxPlansAllowed,
      'maxAppsPerPlan': user.maxAppsPerPlan,
      'createdAt': user.createdAt.millisecondsSinceEpoch,
      'lastLoginAt': user.lastLoginAt?.millisecondsSinceEpoch,
      'updatedAt': user.updatedAt.millisecondsSinceEpoch,
      'totalBlockedTime': user.totalBlockedTime?.inSeconds ?? 0,
      'streakDays': user.streakDays ?? 0,
      'totalDownloads': user.totalDownloads ?? 100,
    };
  }

  UserModel _mapToUser(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      isPremium: map['isPremium'] == 1,
      premiumExpiryDate: map['premiumExpiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['premiumExpiryDate'])
          : null,
      maxPlansAllowed: map['maxPlansAllowed'] ?? 5,
      maxAppsPerPlan: map['maxAppsPerPlan'] ?? 3,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'])
          : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      totalBlockedTime: map['totalBlockedTime'] != null
          ? Duration(seconds: map['totalBlockedTime'])
          : null,
      streakDays: map['streakDays'] ?? 0,
      totalDownloads: map['totalDownloads'] ?? 100,
    );
  }

  // ===== DATABASE MANAGEMENT =====

  Future<void> clearAllData() async {
    final db = await database;

    try {
      // Get all table names
      List<Map<String, dynamic>> tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");

      // Delete all data from each table
      for (var table in tables) {
        await db.delete(table['name']);
      }

      print('All data cleared from local database');
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('Database closed');
    }
  }

  Future<void> printDatabaseStats() async {
    try {
      final db = await database;

      final userCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM users')) ??
          0;
      final appCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM apps')) ??
          0;
      final blockedAppCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM blocked_apps')) ??
          0;
      final scheduleCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM schedules')) ??
          0;
      final quickBlockCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM quick_blocks')) ??
          0;
      final moodLogCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM mood_logs')) ??
          0;

      print('=== Database Stats ===');
      print('Users: $userCount');
      print('Apps: $appCount');
      print('Blocked Apps: $blockedAppCount');
      print('Schedules: $scheduleCount');
      print('Quick Blocks: $quickBlockCount');
      print('Mood Logs: $moodLogCount');
      print('=====================');
    } catch (e) {
      print('Error printing database stats: $e');
    }
  }

  // ===== HELPER METHODS =====

  Future<bool> tableExists(String tableName) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]);
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if table exists: $e');
      return false;
    }
  }

  Future<void> recreateDatabase() async {
    try {
      await closeDatabase();

      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'app_blocker.db');

      await deleteDatabase(path);
      print('Database deleted, will be recreated on next access');

      // Initialize database again
      await initDatabase();
    } catch (e) {
      print('Error recreating database: $e');
      rethrow;
    }
  }
}
