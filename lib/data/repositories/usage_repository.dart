import '../local/models/usage_log_model.dart';
import '../local/daos/usage_log_dao.dart';
import '../services/usage_stats_service.dart';

class UsageRepository {
  final UsageLogDao _usageLogDao = UsageLogDao();
  final UsageStatsService _usageStatsService = UsageStatsService();

  // Get total usage time for a specific period
  Future<Duration> getTotalUsageForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get usage logs from local database
      List<UsageLogModel> logs = await _usageLogDao.getUsageLogsForPeriod(
        userId,
        startDate,
        endDate,
      );

      int totalMinutes = 0;
      for (var log in logs) {
        totalMinutes += log.totalUsageMinutes!;
      }

      return Duration(minutes: totalMinutes);
    } catch (e) {
      print('Error getting total usage: $e');
      return Duration.zero;
    }
  }

  // Get usage logs for a specific period
  Future<List<UsageLogModel>> getUsageLogsForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    int? limit,
  }) async {
    try {
      return await _usageLogDao.getUsageLogsForPeriod(
        userId,
        startDate,
        endDate,
        limit: limit,
      );
    } catch (e) {
      print('Error getting usage logs: $e');
      return [];
    }
  }

  // Get screen pickups count
  Future<int> getScreenPickupsCount(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _usageStatsService.getScreenPickupsCount(
        userId,
        startDate,
        endDate,
      );
    } catch (e) {
      print('Error getting screen pickups: $e');
      return 0;
    }
  }

  // Get daily average usage
  Future<Duration> getDailyAverageUsage(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _usageStatsService.getDailyAverageUsage(
        userId,
        startDate,
        endDate,
      );
    } catch (e) {
      print('Error getting daily average: $e');
      return Duration.zero;
    }
  }

  // Get most used apps
  Future<List<Map<String, dynamic>>> getMostUsedApps(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    int limit = 10,
  }) async {
    try {
      return await _usageStatsService.getMostUsedApps(
        userId,
        startDate,
        endDate,
        limit: limit,
      );
    } catch (e) {
      print('Error getting most used apps: $e');
      return [];
    }
  }

  // Record usage session
  Future<void> recordUsageSession(
    String userId,
    String packageName,
    String appName,
    Duration usageTime,
  ) async {
    try {
      final today = DateTime.now();
      final dayStart = DateTime(today.year, today.month, today.day);

      // Check if log exists for today
      List<UsageLogModel> existingLogs =
          await _usageLogDao.getUsageLogsForPeriod(
        userId,
        dayStart,
        dayStart.add(const Duration(days: 1)),
      );

      UsageLogModel? todayLog = existingLogs.firstWhere(
        (log) => log.appPackageName == packageName,
        orElse: () =>
            UsageLogModel.createForToday(userId, packageName, appName),
      );

      // Create new session
      final session = UsageSessionModel(
        startTime: today.subtract(usageTime),
        endTime: today,
        durationMinutes: usageTime.inMinutes,
      );

      // Add session to log
      final updatedLog = todayLog.addSession(session);

      // Save to database
      await _usageLogDao.insertOrUpdateUsageLog(updatedLog);
    } catch (e) {
      print('Error recording usage session: $e');
    }
  }

  // Sync usage data
  Future<void> syncUsageData(String userId) async {
    try {
      await _usageStatsService.syncUsageData(userId);
    } catch (e) {
      print('Error syncing usage data: $e');
    }
  }

  // Clean old usage data
  Future<void> cleanOldUsageData({int daysToKeep = 90}) async {
    try {
      await _usageStatsService.cleanOldUsageData(daysToKeep: daysToKeep);
    } catch (e) {
      print('Error cleaning old usage data: $e');
    }
  }
}
