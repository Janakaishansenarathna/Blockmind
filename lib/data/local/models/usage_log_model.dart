// models/usage_log_model.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class UsageSessionModel {
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String? blockingPlanId;
  final bool wasBlocked;

  UsageSessionModel({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.blockingPlanId,
    this.wasBlocked = false,
  });

  factory UsageSessionModel.fromMap(Map<String, dynamic> map) {
    return UsageSessionModel(
      startTime: map['startTime'] is Timestamp
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] is Timestamp
          ? (map['endTime'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['endTime']),
      durationMinutes: map['durationMinutes'] ?? 0,
      blockingPlanId: map['blockingPlanId'],
      wasBlocked: map['wasBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'blockingPlanId': blockingPlanId,
      'wasBlocked': wasBlocked,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'blockingPlanId': blockingPlanId,
      'wasBlocked': wasBlocked,
    };
  }

  factory UsageSessionModel.fromJson(Map<String, dynamic> json) {
    return UsageSessionModel(
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
      durationMinutes: json['durationMinutes'] ?? 0,
      blockingPlanId: json['blockingPlanId'],
      wasBlocked: json['wasBlocked'] ?? false,
    );
  }
}

class UsageLogModel {
  final String id;
  final String? userId; // Made optional for backward compatibility
  final String appId;
  final String? appPackageName; // For compatibility with your existing code
  final String? appName; // For compatibility with your existing code
  final DateTime date;
  final Duration duration;
  final bool wasBlocked;
  final String? scheduleId;
  final int openCount;
  final DateTime? firstOpenTime;
  final DateTime? lastOpenTime;
  final List<UsageSessionModel>?
      sessions; // For compatibility with your existing code
  final int? totalUsageMinutes; // For compatibility with your existing code
  final int? blockedAttempts; // For compatibility with your existing code
  final int? successfulBlocks; // For compatibility with your existing code

  UsageLogModel({
    required this.id,
    this.userId,
    required this.appId,
    this.appPackageName,
    this.appName,
    required this.date,
    required this.duration,
    required this.wasBlocked,
    this.scheduleId,
    this.openCount = 0,
    this.firstOpenTime,
    this.lastOpenTime,
    this.sessions,
    this.totalUsageMinutes,
    this.blockedAttempts,
    this.successfulBlocks,
  });

  // Create a copy of this log with some properties changed
  UsageLogModel copyWith({
    String? id,
    String? userId,
    String? appId,
    String? appPackageName,
    String? appName,
    DateTime? date,
    Duration? duration,
    bool? wasBlocked,
    String? scheduleId,
    int? openCount,
    DateTime? firstOpenTime,
    DateTime? lastOpenTime,
    List<UsageSessionModel>? sessions,
    int? totalUsageMinutes,
    int? blockedAttempts,
    int? successfulBlocks,
  }) {
    return UsageLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appId: appId ?? this.appId,
      appPackageName: appPackageName ?? this.appPackageName,
      appName: appName ?? this.appName,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      wasBlocked: wasBlocked ?? this.wasBlocked,
      scheduleId: scheduleId ?? this.scheduleId,
      openCount: openCount ?? this.openCount,
      firstOpenTime: firstOpenTime ?? this.firstOpenTime,
      lastOpenTime: lastOpenTime ?? this.lastOpenTime,
      sessions: sessions ?? this.sessions,
      totalUsageMinutes: totalUsageMinutes ?? this.totalUsageMinutes,
      blockedAttempts: blockedAttempts ?? this.blockedAttempts,
      successfulBlocks: successfulBlocks ?? this.successfulBlocks,
    );
  }

  // Convert to map for database storage (your original format)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'app_id': appId,
      'appId': appId, // compatibility
      'appPackageName': appPackageName ?? '',
      'appName': appName ?? '',
      'date': date.toIso8601String(),
      'duration': duration.inSeconds,
      'durationSeconds': duration.inSeconds, // compatibility
      'was_blocked': wasBlocked ? 1 : 0,
      'wasBlocked': wasBlocked, // compatibility
      'schedule_id': scheduleId,
      'scheduleId': scheduleId, // compatibility
      'open_count': openCount,
      'openCount': openCount, // compatibility
      'first_open_time': firstOpenTime?.toIso8601String(),
      'firstOpenTime': firstOpenTime?.toIso8601String(), // compatibility
      'last_open_time': lastOpenTime?.toIso8601String(),
      'lastOpenTime': lastOpenTime?.toIso8601String(), // compatibility
      'totalUsageMinutes': totalUsageMinutes ?? duration.inMinutes,
      'blockedAttempts': blockedAttempts ?? (wasBlocked ? 1 : 0),
      'successfulBlocks': successfulBlocks ?? (wasBlocked ? 1 : 0),
      'sessions': sessions?.map((s) => s.toJson()).toList() ?? [],
    };
  }

  // Convert to JSON string
  String toJson() => json.encode(toJsonMap());

  // Convert to JSON map
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'userId': userId,
      'appId': appId,
      'appPackageName': appPackageName,
      'appName': appName,
      'date': date.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'wasBlocked': wasBlocked,
      'scheduleId': scheduleId,
      'openCount': openCount,
      'firstOpenTime': firstOpenTime?.toIso8601String(),
      'lastOpenTime': lastOpenTime?.toIso8601String(),
      'totalUsageMinutes': totalUsageMinutes ?? duration.inMinutes,
      'blockedAttempts': blockedAttempts ?? (wasBlocked ? 1 : 0),
      'successfulBlocks': successfulBlocks ?? (wasBlocked ? 1 : 0),
      'sessions': sessions?.map((s) => s.toJson()).toList() ?? [],
    };
  }

  // Firebase compatibility
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'appId': appId,
      'appPackageName': appPackageName ?? '',
      'appName': appName ?? '',
      'date': Timestamp.fromDate(date),
      'durationSeconds': duration.inSeconds,
      'wasBlocked': wasBlocked,
      'scheduleId': scheduleId,
      'openCount': openCount,
      'firstOpenTime':
          firstOpenTime != null ? Timestamp.fromDate(firstOpenTime!) : null,
      'lastOpenTime':
          lastOpenTime != null ? Timestamp.fromDate(lastOpenTime!) : null,
      'totalUsageMinutes': totalUsageMinutes ?? duration.inMinutes,
      'blockedAttempts': blockedAttempts ?? (wasBlocked ? 1 : 0),
      'successfulBlocks': successfulBlocks ?? (wasBlocked ? 1 : 0),
      'sessions': sessions?.map((s) => s.toMap()).toList() ?? [],
    };
  }

  // Create a log from map (your original format)
  factory UsageLogModel.fromMap(Map<String, dynamic> map) {
    return UsageLogModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? map['userId'],
      appId: map['app_id'] ?? map['appId'] ?? '',
      appPackageName: map['appPackageName'] ?? '',
      appName: map['appName'] ?? '',
      date: map['date'] is String
          ? DateTime.parse(map['date'])
          : DateTime.fromMillisecondsSinceEpoch(map['date']),
      duration:
          Duration(seconds: map['duration'] ?? map['durationSeconds'] ?? 0),
      wasBlocked: (map['was_blocked'] ?? map['wasBlocked']) == 1 ||
          (map['was_blocked'] ?? map['wasBlocked']) == true,
      scheduleId: map['schedule_id'] ?? map['scheduleId'],
      openCount: map['open_count'] ?? map['openCount'] ?? 0,
      firstOpenTime: map['first_open_time'] != null
          ? (map['first_open_time'] is String
              ? DateTime.parse(map['first_open_time'])
              : DateTime.fromMillisecondsSinceEpoch(map['first_open_time']))
          : (map['firstOpenTime'] != null
              ? DateTime.parse(map['firstOpenTime'])
              : null),
      lastOpenTime: map['last_open_time'] != null
          ? (map['last_open_time'] is String
              ? DateTime.parse(map['last_open_time'])
              : DateTime.fromMillisecondsSinceEpoch(map['last_open_time']))
          : (map['lastOpenTime'] != null
              ? DateTime.parse(map['lastOpenTime'])
              : null),
      totalUsageMinutes: map['totalUsageMinutes'],
      blockedAttempts: map['blockedAttempts'],
      successfulBlocks: map['successfulBlocks'],
      sessions: map['sessions'] != null
          ? List<Map<String, dynamic>>.from(map['sessions'])
              .map((s) => UsageSessionModel.fromJson(s))
              .toList()
          : null,
    );
  }

  // Create from JSON string
  factory UsageLogModel.fromJson(String jsonString) {
    final Map<String, dynamic> map = json.decode(jsonString);
    return UsageLogModel.fromJsonMap(map);
  }

  // Create from JSON map
  factory UsageLogModel.fromJsonMap(Map<String, dynamic> map) {
    return UsageLogModel(
      id: map['id'] ?? '',
      userId: map['userId'],
      appId: map['appId'] ?? '',
      appPackageName: map['appPackageName'],
      appName: map['appName'],
      date: DateTime.parse(map['date']),
      duration: Duration(seconds: map['durationSeconds'] ?? 0),
      wasBlocked: map['wasBlocked'] ?? false,
      scheduleId: map['scheduleId'],
      openCount: map['openCount'] ?? 0,
      firstOpenTime: map['firstOpenTime'] != null
          ? DateTime.parse(map['firstOpenTime'])
          : null,
      lastOpenTime: map['lastOpenTime'] != null
          ? DateTime.parse(map['lastOpenTime'])
          : null,
      totalUsageMinutes: map['totalUsageMinutes'],
      blockedAttempts: map['blockedAttempts'],
      successfulBlocks: map['successfulBlocks'],
      sessions: map['sessions'] != null
          ? List<Map<String, dynamic>>.from(map['sessions'])
              .map((s) => UsageSessionModel.fromJson(s))
              .toList()
          : null,
    );
  }

  // Firebase compatibility
  factory UsageLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<UsageSessionModel> sessionsList = [];
    if (data['sessions'] != null) {
      sessionsList = List<Map<String, dynamic>>.from(data['sessions'])
          .map((sessionMap) => UsageSessionModel.fromMap(sessionMap))
          .toList();
    }

    return UsageLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      appId: data['appId'] ?? '',
      appPackageName: data['appPackageName'] ?? '',
      appName: data['appName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      duration: Duration(seconds: data['durationSeconds'] ?? 0),
      wasBlocked: data['wasBlocked'] ?? false,
      scheduleId: data['scheduleId'],
      openCount: data['openCount'] ?? 0,
      firstOpenTime: data['firstOpenTime'] != null
          ? (data['firstOpenTime'] as Timestamp).toDate()
          : null,
      lastOpenTime: data['lastOpenTime'] != null
          ? (data['lastOpenTime'] as Timestamp).toDate()
          : null,
      sessions: sessionsList,
      totalUsageMinutes: data['totalUsageMinutes'] ?? 0,
      blockedAttempts: data['blockedAttempts'] ?? 0,
      successfulBlocks: data['successfulBlocks'] ?? 0,
    );
  }

  // Add a session to the daily usage (compatibility method)
  UsageLogModel addSession(UsageSessionModel session) {
    List<UsageSessionModel> updatedSessions = List.from(sessions ?? [])
      ..add(session);

    int newTotalMinutes = (totalUsageMinutes ?? 0) + session.durationMinutes;
    int newBlockedAttempts =
        (blockedAttempts ?? 0) + (session.wasBlocked ? 1 : 0);
    int newSuccessfulBlocks =
        (successfulBlocks ?? 0) + (session.wasBlocked ? 1 : 0);

    return copyWith(
      sessions: updatedSessions,
      totalUsageMinutes: newTotalMinutes,
      blockedAttempts: newBlockedAttempts,
      successfulBlocks: newSuccessfulBlocks,
    );
  }

  // Create a new usage log for today (compatibility method)
  factory UsageLogModel.createForToday(
      String userId, String packageName, String appName) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return UsageLogModel(
      id: '${userId}_${packageName}_${today.millisecondsSinceEpoch}',
      userId: userId,
      appId: packageName,
      appPackageName: packageName,
      appName: appName,
      date: today,
      duration: Duration.zero,
      wasBlocked: false,
      sessions: [],
      totalUsageMinutes: 0,
      blockedAttempts: 0,
      successfulBlocks: 0,
    );
  }

  // Helper method to get formatted duration
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Helper method to check if this is today's log
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(date.year, date.month, date.day);
    return logDate.isAtSameMomentAs(today);
  }

  // Equality operators
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageLogModel &&
        other.id == id &&
        other.appId == appId &&
        other.date == date;
  }

  @override
  int get hashCode => id.hashCode ^ appId.hashCode ^ date.hashCode;

  // For debugging
  @override
  String toString() {
    return 'UsageLogModel(id: $id, appId: $appId, date: $date, duration: $duration, wasBlocked: $wasBlocked)';
  }
}
