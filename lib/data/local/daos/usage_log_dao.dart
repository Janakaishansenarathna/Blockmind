// data/daos/usage_log_dao.dart
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/usage_log_model.dart';

class UsageLogDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Table names
  static const String tableName = 'usage_logs';
  static const String sessionsTableName = 'usage_sessions';
  static const String tableNameV2 = 'usage_logs_v2';

  // Legacy table schema (for backward compatibility)
  static String get createUsageLogsTable => '''
    CREATE TABLE $tableName (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      appPackageName TEXT NOT NULL,
      appName TEXT NOT NULL,
      date INTEGER NOT NULL,
      totalUsageMinutes INTEGER NOT NULL DEFAULT 0,
      blockedAttempts INTEGER NOT NULL DEFAULT 0,
      successfulBlocks INTEGER NOT NULL DEFAULT 0,
      isSynced INTEGER NOT NULL DEFAULT 0,
      createdAt INTEGER NOT NULL,
      updatedAt INTEGER NOT NULL
    )
  ''';

  static String get createUsageSessionsTable => '''
    CREATE TABLE $sessionsTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usageLogId TEXT NOT NULL,
      startTime INTEGER NOT NULL,
      endTime INTEGER NOT NULL,
      durationMinutes INTEGER NOT NULL,
      blockingPlanId TEXT,
      wasBlocked INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (usageLogId) REFERENCES $tableName (id) ON DELETE CASCADE
    )
  ''';

  // Enhanced table schema (used by DatabaseHelper)
  static String get createUsageLogsV2Table => '''
    CREATE TABLE $tableNameV2 (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      appId TEXT NOT NULL,
      appPackageName TEXT,
      appName TEXT,
      date INTEGER NOT NULL,
      durationSeconds INTEGER NOT NULL,
      wasBlocked INTEGER NOT NULL,
      scheduleId TEXT,
      openCount INTEGER DEFAULT 0,
      firstOpenTime INTEGER,
      lastOpenTime INTEGER,
      totalUsageMinutes INTEGER DEFAULT 0,
      blockedAttempts INTEGER DEFAULT 0,
      successfulBlocks INTEGER DEFAULT 0,
      isSynced INTEGER DEFAULT 0,
      createdAt INTEGER NOT NULL,
      FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
    )
  ''';

  // ===== MAIN CRUD OPERATIONS =====

  /// Insert or update usage log (supports both table formats)
  Future<void> insertOrUpdateUsageLog(UsageLogModel usageLog,
      {bool useV2 = true}) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      if (useV2) {
        // Use enhanced table format
        await txn.insert(
          tableNameV2,
          _usageLogToMapV2(usageLog),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        // Use legacy table format
        await txn.insert(
          tableName,
          _usageLogToMap(usageLog),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Handle sessions for legacy format
        if (usageLog.sessions != null && usageLog.sessions!.isNotEmpty) {
          // Delete existing sessions for this log
          await txn.delete(
            sessionsTableName,
            where: 'usageLogId = ?',
            whereArgs: [usageLog.id],
          );

          // Insert sessions
          for (var session in usageLog.sessions!) {
            await txn.insert(
              sessionsTableName,
              _sessionToMap(session, usageLog.id),
            );
          }
        }
      }
    });
  }

  /// Insert usage log (for backward compatibility)
  Future<void> insertUsageLog(UsageLogModel usageLog) async {
    await insertOrUpdateUsageLog(usageLog);
  }

  /// Update usage log
  Future<void> updateUsageLog(UsageLogModel usageLog) async {
    await insertOrUpdateUsageLog(usageLog);
  }

  /// Batch insert multiple usage logs
  Future<void> batchInsertUsageLogs(List<UsageLogModel> usageLogs,
      {bool useV2 = true}) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final usageLog in usageLogs) {
        if (useV2) {
          batch.insert(
            tableNameV2,
            _usageLogToMapV2(usageLog),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          batch.insert(
            tableName,
            _usageLogToMap(usageLog),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit(noResult: true);
    });
  }

  // ===== QUERY OPERATIONS =====

  /// Get usage logs for a specific period
  Future<List<UsageLogModel>> getUsageLogsForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    int? limit,
    bool useV2 = true,
    String? appId,
  }) async {
    final db = await _databaseHelper.database;

    final startMillis = startDate.millisecondsSinceEpoch;
    final endMillis = endDate.millisecondsSinceEpoch;

    String query;
    List<dynamic> args;

    if (useV2) {
      query = '''
        SELECT * FROM $tableNameV2 
        WHERE userId = ? AND date >= ? AND date <= ?
      ''';
      args = [userId, startMillis, endMillis];

      if (appId != null) {
        query += ' AND appId = ?';
        args.add(appId);
      }
    } else {
      query = '''
        SELECT * FROM $tableName 
        WHERE userId = ? AND date >= ? AND date <= ?
      ''';
      args = [userId, startMillis, endMillis];
    }

    query += ' ORDER BY date DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    List<UsageLogModel> usageLogs = [];
    for (var map in maps) {
      if (useV2) {
        usageLogs.add(_mapToUsageLogV2(map));
      } else {
        // Get sessions for legacy format
        final sessions = await _getSessionsForUsageLog(db, map['id']);
        usageLogs.add(_mapToUsageLog(map, sessions));
      }
    }

    return usageLogs;
  }

  /// Get today's usage logs for a user
  Future<List<UsageLogModel>> getTodayUsageLogs(String userId,
      {bool useV2 = true}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return getUsageLogsForPeriod(userId, today, tomorrow, useV2: useV2);
  }

  /// Get usage logs for a specific app
  Future<List<UsageLogModel>> getUsageLogsForApp(
    String userId,
    String appId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool useV2 = true,
  }) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    return getUsageLogsForPeriod(
      userId,
      start,
      end,
      limit: limit,
      useV2: useV2,
      appId: appId,
    );
  }

  /// Get usage summary for a period
  Future<Map<String, dynamic>> getUsageSummary(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    bool useV2 = true,
  }) async {
    final db = await _databaseHelper.database;

    final startMillis = startDate.millisecondsSinceEpoch;
    final endMillis = endDate.millisecondsSinceEpoch;

    String query;
    if (useV2) {
      query = '''
        SELECT 
          COUNT(*) as totalLogs,
          SUM(durationSeconds) as totalSeconds,
          SUM(openCount) as totalOpens,
          SUM(CASE WHEN wasBlocked = 1 THEN 1 ELSE 0 END) as blockedSessions,
          COUNT(DISTINCT appId) as uniqueApps,
          COUNT(DISTINCT DATE(date/1000, 'unixepoch')) as activeDays
        FROM $tableNameV2 
        WHERE userId = ? AND date >= ? AND date <= ?
      ''';
    } else {
      query = '''
        SELECT 
          COUNT(*) as totalLogs,
          SUM(totalUsageMinutes) as totalMinutes,
          SUM(blockedAttempts) as blockedAttempts,
          SUM(successfulBlocks) as successfulBlocks,
          COUNT(DISTINCT appPackageName) as uniqueApps,
          COUNT(DISTINCT DATE(date/1000, 'unixepoch')) as activeDays
        FROM $tableName 
        WHERE userId = ? AND date >= ? AND date <= ?
      ''';
    }

    final List<Map<String, dynamic>> result = await db.rawQuery(
      query,
      [userId, startMillis, endMillis],
    );

    if (result.isNotEmpty) {
      final data = result.first;
      if (useV2) {
        return {
          'totalLogs': data['totalLogs'] ?? 0,
          'totalDuration': Duration(seconds: data['totalSeconds'] ?? 0),
          'totalOpens': data['totalOpens'] ?? 0,
          'blockedSessions': data['blockedSessions'] ?? 0,
          'uniqueApps': data['uniqueApps'] ?? 0,
          'activeDays': data['activeDays'] ?? 0,
          'averageDailyUsage': data['activeDays'] > 0
              ? Duration(
                  seconds: (data['totalSeconds'] ?? 0) ~/ data['activeDays'])
              : Duration.zero,
        };
      } else {
        return {
          'totalLogs': data['totalLogs'] ?? 0,
          'totalDuration': Duration(minutes: data['totalMinutes'] ?? 0),
          'blockedAttempts': data['blockedAttempts'] ?? 0,
          'successfulBlocks': data['successfulBlocks'] ?? 0,
          'uniqueApps': data['uniqueApps'] ?? 0,
          'activeDays': data['activeDays'] ?? 0,
          'averageDailyUsage': data['activeDays'] > 0
              ? Duration(
                  minutes: (data['totalMinutes'] ?? 0) ~/ data['activeDays'])
              : Duration.zero,
        };
      }
    }

    return {
      'totalLogs': 0,
      'totalDuration': Duration.zero,
      'totalOpens': 0,
      'blockedSessions': 0,
      'uniqueApps': 0,
      'activeDays': 0,
      'averageDailyUsage': Duration.zero,
    };
  }

  /// Get top blocked apps
  Future<List<Map<String, dynamic>>> getTopBlockedApps(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
    bool useV2 = true,
  }) async {
    final db = await _databaseHelper.database;

    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now();
    final startMillis = start.millisecondsSinceEpoch;
    final endMillis = end.millisecondsSinceEpoch;

    String query;
    if (useV2) {
      query = '''
        SELECT 
          appId,
          appPackageName,
          appName,
          COUNT(*) as blockCount,
          SUM(durationSeconds) as totalBlocked,
          SUM(openCount) as totalAttempts
        FROM $tableNameV2 
        WHERE userId = ? AND date >= ? AND date <= ? AND wasBlocked = 1
        GROUP BY appId
        ORDER BY blockCount DESC, totalBlocked DESC
        LIMIT ?
      ''';
    } else {
      query = '''
        SELECT 
          appPackageName,
          appName,
          SUM(successfulBlocks) as blockCount,
          SUM(totalUsageMinutes) as totalBlocked,
          SUM(blockedAttempts) as totalAttempts
        FROM $tableName 
        WHERE userId = ? AND date >= ? AND date <= ?
        GROUP BY appPackageName
        ORDER BY blockCount DESC, totalBlocked DESC
        LIMIT ?
      ''';
    }

    final List<Map<String, dynamic>> result = await db.rawQuery(
      query,
      [userId, startMillis, endMillis, limit],
    );

    return result.map((row) {
      if (useV2) {
        return {
          'appId': row['appId'],
          'appPackageName': row['appPackageName'],
          'appName': row['appName'],
          'blockCount': row['blockCount'] ?? 0,
          'totalBlocked': Duration(seconds: row['totalBlocked'] ?? 0),
          'totalAttempts': row['totalAttempts'] ?? 0,
        };
      } else {
        return {
          'appPackageName': row['appPackageName'],
          'appName': row['appName'],
          'blockCount': row['blockCount'] ?? 0,
          'totalBlocked': Duration(minutes: row['totalBlocked'] ?? 0),
          'totalAttempts': row['totalAttempts'] ?? 0,
        };
      }
    }).toList();
  }

  // ===== SYNC OPERATIONS =====

  /// Get unsynced logs
  Future<List<UsageLogModel>> getUnsyncedLogs(String userId,
      {bool useV2 = true}) async {
    final db = await _databaseHelper.database;

    String tableName = useV2 ? tableNameV2 : UsageLogDao.tableName;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'userId = ? AND isSynced = ?',
      whereArgs: [userId, 0],
      orderBy: 'createdAt DESC',
    );

    List<UsageLogModel> usageLogs = [];
    for (var map in maps) {
      if (useV2) {
        usageLogs.add(_mapToUsageLogV2(map));
      } else {
        final sessions = await _getSessionsForUsageLog(db, map['id']);
        usageLogs.add(_mapToUsageLog(map, sessions));
      }
    }

    return usageLogs;
  }

  /// Mark logs as synced
  Future<void> markLogsAsSynced(List<String> logIds,
      {bool useV2 = true}) async {
    final db = await _databaseHelper.database;

    String tableName = useV2 ? tableNameV2 : UsageLogDao.tableName;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final logId in logIds) {
        batch.update(
          tableName,
          {'isSynced': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [logId],
        );
      }

      await batch.commit(noResult: true);
    });
  }

  /// Sync logs to cloud (placeholder for Firebase sync)
  Future<bool> syncLogsToCloud(String userId) async {
    try {
      final unsyncedLogs = await getUnsyncedLogs(userId);

      if (unsyncedLogs.isEmpty) {
        return true;
      }

      // TODO: Implement Firebase sync here
      // Example:
      // for (final log in unsyncedLogs) {
      //   await FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(userId)
      //       .collection('usage_logs')
      //       .doc(log.id)
      //       .set(log.toFirestore());
      // }

      // Mark as synced
      final logIds = unsyncedLogs.map((log) => log.id).toList();
      await markLogsAsSynced(logIds);

      return true;
    } catch (e) {
      print('Error syncing logs to cloud: $e');
      return false;
    }
  }

  // ===== MAINTENANCE OPERATIONS =====

  /// Delete old logs (older than specified date)
  Future<int> deleteOldLogs(DateTime cutoffDate, {bool useV2 = true}) async {
    final db = await _databaseHelper.database;

    String tableName = useV2 ? tableNameV2 : UsageLogDao.tableName;

    final deletedCount = await db.delete(
      tableName,
      where: 'date < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );

    print('Deleted $deletedCount old usage logs');
    return deletedCount;
  }

  /// Clean up logs (delete logs older than 90 days)
  Future<int> cleanupOldLogs({bool useV2 = true}) async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    return deleteOldLogs(cutoffDate, useV2: useV2);
  }

  /// Delete all logs for a user
  Future<void> deleteUserLogs(String userId, {bool useV2 = true}) async {
    final db = await _databaseHelper.database;

    String tableName = useV2 ? tableNameV2 : UsageLogDao.tableName;

    await db.delete(
      tableName,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats({bool useV2 = true}) async {
    final db = await _databaseHelper.database;

    String tableName = useV2 ? tableNameV2 : UsageLogDao.tableName;

    final totalLogs = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $tableName')) ??
        0;

    final unsyncedLogs = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM $tableName WHERE isSynced = 0')) ??
        0;

    final oldestLog =
        await db.rawQuery('SELECT MIN(date) as oldest FROM $tableName');

    final newestLog =
        await db.rawQuery('SELECT MAX(date) as newest FROM $tableName');

    return {
      'totalLogs': totalLogs,
      'unsyncedLogs': unsyncedLogs,
      'syncedLogs': totalLogs - unsyncedLogs,
      'oldestLog': oldestLog.isNotEmpty && oldestLog.first['oldest'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              oldestLog.first['oldest'] as int)
          : null,
      'newestLog': newestLog.isNotEmpty && newestLog.first['newest'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              newestLog.first['newest'] as int)
          : null,
    };
  }

  // ===== HELPER METHODS =====

  /// Get sessions for a usage log (legacy format)
  Future<List<UsageSessionModel>> _getSessionsForUsageLog(
    Database db,
    String usageLogId,
  ) async {
    final List<Map<String, dynamic>> sessionMaps = await db.query(
      sessionsTableName,
      where: 'usageLogId = ?',
      whereArgs: [usageLogId],
      orderBy: 'startTime ASC',
    );

    return sessionMaps.map((map) => _mapToSession(map)).toList();
  }

  // ===== CONVERSION METHODS =====

  /// Convert UsageLogModel to Map (legacy format)
  Map<String, dynamic> _usageLogToMap(UsageLogModel usageLog) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': usageLog.id,
      'userId': usageLog.userId ?? '',
      'appPackageName': usageLog.appPackageName ?? '',
      'appName': usageLog.appName ?? '',
      'date': usageLog.date.millisecondsSinceEpoch,
      'totalUsageMinutes':
          usageLog.totalUsageMinutes ?? usageLog.duration.inMinutes,
      'blockedAttempts':
          usageLog.blockedAttempts ?? (usageLog.wasBlocked ? 1 : 0),
      'successfulBlocks':
          usageLog.successfulBlocks ?? (usageLog.wasBlocked ? 1 : 0),
      'isSynced': 0, // false
      'createdAt': now,
      'updatedAt': now,
    };
  }

  /// Convert UsageLogModel to Map (enhanced V2 format)
  Map<String, dynamic> _usageLogToMapV2(UsageLogModel usageLog) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': usageLog.id,
      'userId': usageLog.userId ?? '',
      'appId': usageLog.appId,
      'appPackageName': usageLog.appPackageName,
      'appName': usageLog.appName,
      'date': usageLog.date.millisecondsSinceEpoch,
      'durationSeconds': usageLog.duration.inSeconds,
      'wasBlocked': usageLog.wasBlocked ? 1 : 0,
      'scheduleId': usageLog.scheduleId,
      'openCount': usageLog.openCount,
      'firstOpenTime': usageLog.firstOpenTime?.millisecondsSinceEpoch,
      'lastOpenTime': usageLog.lastOpenTime?.millisecondsSinceEpoch,
      'totalUsageMinutes':
          usageLog.totalUsageMinutes ?? usageLog.duration.inMinutes,
      'blockedAttempts':
          usageLog.blockedAttempts ?? (usageLog.wasBlocked ? 1 : 0),
      'successfulBlocks':
          usageLog.successfulBlocks ?? (usageLog.wasBlocked ? 1 : 0),
      'isSynced': 0, // false
      'createdAt': now,
    };
  }

  /// Convert session to Map
  Map<String, dynamic> _sessionToMap(
      UsageSessionModel session, String usageLogId) {
    return {
      'usageLogId': usageLogId,
      'startTime': session.startTime.millisecondsSinceEpoch,
      'endTime': session.endTime.millisecondsSinceEpoch,
      'durationMinutes': session.durationMinutes,
      'blockingPlanId': session.blockingPlanId,
      'wasBlocked': session.wasBlocked ? 1 : 0,
    };
  }

  /// Convert Map to UsageLogModel (legacy format)
  UsageLogModel _mapToUsageLog(
    Map<String, dynamic> map,
    List<UsageSessionModel> sessions,
  ) {
    return UsageLogModel(
      id: map['id'],
      userId: map['userId'],
      appId: map['appPackageName'], // Use package name as app ID for legacy
      appPackageName: map['appPackageName'],
      appName: map['appName'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      duration: Duration(minutes: map['totalUsageMinutes'] ?? 0),
      wasBlocked: (map['successfulBlocks'] ?? 0) > 0,
      sessions: sessions,
      totalUsageMinutes: map['totalUsageMinutes'] ?? 0,
      blockedAttempts: map['blockedAttempts'] ?? 0,
      successfulBlocks: map['successfulBlocks'] ?? 0,
    );
  }

  /// Convert Map to UsageLogModel (enhanced V2 format)
  UsageLogModel _mapToUsageLogV2(Map<String, dynamic> map) {
    return UsageLogModel(
      id: map['id'],
      userId: map['userId'],
      appId: map['appId'],
      appPackageName: map['appPackageName'],
      appName: map['appName'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      duration: Duration(seconds: map['durationSeconds'] ?? 0),
      wasBlocked: map['wasBlocked'] == 1,
      scheduleId: map['scheduleId'],
      openCount: map['openCount'] ?? 0,
      firstOpenTime: map['firstOpenTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['firstOpenTime'])
          : null,
      lastOpenTime: map['lastOpenTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastOpenTime'])
          : null,
      totalUsageMinutes: map['totalUsageMinutes'] ?? 0,
      blockedAttempts: map['blockedAttempts'] ?? 0,
      successfulBlocks: map['successfulBlocks'] ?? 0,
    );
  }

  /// Convert Map to UsageSessionModel
  UsageSessionModel _mapToSession(Map<String, dynamic> map) {
    return UsageSessionModel(
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime']),
      durationMinutes: map['durationMinutes'],
      blockingPlanId: map['blockingPlanId'],
      wasBlocked: map['wasBlocked'] == 1,
    );
  }

  // ===== MIGRATION HELPERS =====

  /// Migrate data from legacy table to V2 table
  Future<void> migrateLegacyToV2() async {
    final db = await _databaseHelper.database;

    try {
      // Check if V2 table exists
      final v2TableExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableNameV2'");

      if (v2TableExists.isEmpty) {
        // Create V2 table
        await db.execute(createUsageLogsV2Table);
      }

      // Get all legacy data
      final legacyData = await db.query(tableName);

      // Migrate each record
      for (final record in legacyData) {
        final v2Record = {
          'id': record['id'],
          'userId': record['userId'],
          'appId': record['appPackageName'],
          'appPackageName': record['appPackageName'],
          'appName': record['appName'],
          'date': record['date'],
          'durationSeconds': ((record['totalUsageMinutes'] ?? 0) as int) * 60,
          'wasBlocked': ((record['successfulBlocks'] ?? 0) as int) > 0 ? 1 : 0,
          'scheduleId': null,
          'openCount': record['blockedAttempts'] ?? 0,
          'firstOpenTime': null,
          'lastOpenTime': null,
          'totalUsageMinutes': record['totalUsageMinutes'],
          'blockedAttempts': record['blockedAttempts'],
          'successfulBlocks': record['successfulBlocks'],
          'isSynced': record['isSynced'],
          'createdAt': record['createdAt'],
        };

        await db.insert(
          tableNameV2,
          v2Record,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      print('Successfully migrated ${legacyData.length} records to V2 table');
    } catch (e) {
      print('Error migrating legacy data: $e');
    }
  }
}
