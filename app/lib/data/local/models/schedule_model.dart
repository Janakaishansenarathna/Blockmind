import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ScheduleModel {
  final String id;
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<int> days;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<String> blockedApps;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTriggered;
  final DateTime? updatedAt;
  final String? name; // For backward compatibility

  ScheduleModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.blockedApps,
    this.isActive = true,
    DateTime? createdAt,
    this.lastTriggered,
    this.updatedAt,
    this.name,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a copy of this schedule with some properties changed
  ScheduleModel copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? iconColor,
    List<int>? days,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<String>? blockedApps,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastTriggered,
    DateTime? updatedAt,
    String? name,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      days: days ?? this.days,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      blockedApps: blockedApps ?? this.blockedApps,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
    );
  }

  // Convert to map for database storage (your original format)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'name': name ?? title, // backward compatibility
      'icon_data': icon.codePoint,
      'iconCodePoint': icon.codePoint, // compatibility
      'icon_color': iconColor.value,
      'iconColor': iconColor.value, // compatibility
      'days': json.encode(days),
      'start_time': '${startTime.hour}:${startTime.minute}',
      'end_time': '${endTime.hour}:${endTime.minute}',
      'startTime': '${startTime.hour}:${startTime.minute}', // compatibility
      'endTime': '${endTime.hour}:${endTime.minute}', // compatibility
      'blocked_apps': json.encode(blockedApps),
      'blockedApps': json.encode(blockedApps), // compatibility
      'is_active': isActive ? 1 : 0,
      'isActive': isActive, // compatibility
      'created_at': createdAt.millisecondsSinceEpoch,
      'createdAt': createdAt.toIso8601String(), // compatibility
      'last_triggered': lastTriggered?.millisecondsSinceEpoch,
      'lastTriggered': lastTriggered?.toIso8601String(), // compatibility
      'updated_at': (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
      'updatedAt':
          (updatedAt ?? DateTime.now()).toIso8601String(), // compatibility
    };
  }

  // Convert to JSON string
  String toJson() => json.encode(toJsonMap());

  // Convert to JSON map
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'title': title,
      'name': name ?? title,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily ?? 'MaterialIcons',
      'iconColor': iconColor.value,
      'days': days,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'endTimeHour': endTime.hour,
      'endTimeMinute': endTime.minute,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'blockedApps': blockedApps,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  // Firebase compatibility
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'name': name ?? title,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily ?? 'MaterialIcons',
      'iconColor': iconColor.value,
      'days': days,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'endTimeHour': endTime.hour,
      'endTimeMinute': endTime.minute,
      'blockedApps': blockedApps,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastTriggered':
          lastTriggered != null ? Timestamp.fromDate(lastTriggered!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  // Create a schedule from map (your original format)
  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    List<int> daysList;
    try {
      if (map['days'] is String) {
        daysList = List<int>.from(json.decode(map['days']));
      } else {
        daysList = List<int>.from(map['days'] ?? []);
      }
    } catch (e) {
      daysList = [];
    }

    List<String> appsList;
    try {
      if (map['blocked_apps'] is String) {
        appsList = List<String>.from(json.decode(map['blocked_apps']));
      } else if (map['blockedApps'] is String) {
        appsList = List<String>.from(json.decode(map['blockedApps']));
      } else {
        appsList =
            List<String>.from(map['blocked_apps'] ?? map['blockedApps'] ?? []);
      }
    } catch (e) {
      appsList = [];
    }

    TimeOfDay parseStartTime;
    TimeOfDay parseEndTime;

    try {
      if (map['start_time'] != null) {
        final startTimeParts = map['start_time'].split(':');
        parseStartTime = TimeOfDay(
          hour: int.parse(startTimeParts[0]),
          minute: int.parse(startTimeParts[1]),
        );
      } else {
        parseStartTime = TimeOfDay(
          hour: map['startTimeHour'] ?? 0,
          minute: map['startTimeMinute'] ?? 0,
        );
      }

      if (map['end_time'] != null) {
        final endTimeParts = map['end_time'].split(':');
        parseEndTime = TimeOfDay(
          hour: int.parse(endTimeParts[0]),
          minute: int.parse(endTimeParts[1]),
        );
      } else {
        parseEndTime = TimeOfDay(
          hour: map['endTimeHour'] ?? 23,
          minute: map['endTimeMinute'] ?? 59,
        );
      }
    } catch (e) {
      parseStartTime = const TimeOfDay(hour: 0, minute: 0);
      parseEndTime = const TimeOfDay(hour: 23, minute: 59);
    }

    return ScheduleModel(
      id: map['id'] ?? '',
      title: map['title'] ?? map['name'] ?? '',
      icon: IconData(
        map['icon_data'] ?? map['iconCodePoint'] ?? Icons.schedule.codePoint,
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
      ),
      iconColor:
          Color(map['icon_color'] ?? map['iconColor'] ?? Colors.blue.value),
      days: daysList,
      startTime: parseStartTime,
      endTime: parseEndTime,
      blockedApps: appsList,
      isActive: (map['is_active'] ?? map['isActive']) == 1 ||
          (map['is_active'] ?? map['isActive']) == true,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : (map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now()),
      lastTriggered: map['last_triggered'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_triggered'])
          : (map['lastTriggered'] != null
              ? DateTime.parse(map['lastTriggered'])
              : null),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : (map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'])
              : null),
      name: map['name'],
    );
  }

  // Create from JSON string
  factory ScheduleModel.fromJson(String jsonString) {
    final Map<String, dynamic> map = json.decode(jsonString);
    return ScheduleModel.fromJsonMap(map);
  }

  // Create from JSON map
  factory ScheduleModel.fromJsonMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] ?? '',
      title: map['title'] ?? map['name'] ?? '',
      icon: IconData(
        map['iconCodePoint'] ?? Icons.schedule.codePoint,
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
      ),
      iconColor: Color(map['iconColor'] ?? Colors.blue.value),
      days: List<int>.from(map['days'] ?? []),
      startTime: TimeOfDay(
        hour: map['startTimeHour'] ?? 0,
        minute: map['startTimeMinute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['endTimeHour'] ?? 23,
        minute: map['endTimeMinute'] ?? 59,
      ),
      blockedApps: List<String>.from(map['blockedApps'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastTriggered: map['lastTriggered'] != null
          ? DateTime.parse(map['lastTriggered'])
          : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      name: map['name'],
    );
  }

  // Firebase compatibility
  factory ScheduleModel.fromFirestore(
      DocumentSnapshot doc, Map<String, dynamic> data) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleModel(
      id: doc.id,
      title: data['title'] ?? data['name'] ?? '',
      icon: IconData(
        data['iconCodePoint'] ?? Icons.schedule.codePoint,
        fontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
      ),
      iconColor: Color(data['iconColor'] ?? Colors.blue.value),
      days: List<int>.from(data['days'] ?? []),
      startTime: TimeOfDay(
        hour: data['startTimeHour'] ?? 0,
        minute: data['startTimeMinute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: data['endTimeHour'] ?? 23,
        minute: data['endTimeMinute'] ?? 59,
      ),
      blockedApps: List<String>.from(data['blockedApps'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastTriggered: data['lastTriggered'] != null
          ? (data['lastTriggered'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      name: data['name'],
    );
  }

  // Helper method to check if a specific day is selected
  bool containsDay(int day) {
    return days.contains(day);
  }

  // Helper method to get a formatted string of days
  String getFormattedDays() {
    final List<String> dayNames = [];

    if (containsDay(DateTime.monday)) dayNames.add('Mon');
    if (containsDay(DateTime.tuesday)) dayNames.add('Tue');
    if (containsDay(DateTime.wednesday)) dayNames.add('Wed');
    if (containsDay(DateTime.thursday)) dayNames.add('Thu');
    if (containsDay(DateTime.friday)) dayNames.add('Fri');
    if (containsDay(DateTime.saturday)) dayNames.add('Sat');
    if (containsDay(DateTime.sunday)) dayNames.add('Sun');

    if (dayNames.length == 7) {
      return 'Every day';
    } else if (dayNames.length == 5 &&
        containsDay(DateTime.monday) &&
        containsDay(DateTime.tuesday) &&
        containsDay(DateTime.wednesday) &&
        containsDay(DateTime.thursday) &&
        containsDay(DateTime.friday)) {
      return 'Weekdays';
    } else if (dayNames.length == 2 &&
        containsDay(DateTime.saturday) &&
        containsDay(DateTime.sunday)) {
      return 'Weekends';
    } else {
      return dayNames.join(', ');
    }
  }

  // Helper method to get formatted time range
  String getFormattedTimeRange() {
    String formatTime(TimeOfDay time) {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
    }

    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  // Helper method to check if schedule is currently active
  bool get isCurrentlyActive {
    if (!isActive) return false;

    final now = DateTime.now();
    final currentDay = now.weekday;
    final currentTime = TimeOfDay.fromDateTime(now);

    if (!containsDay(currentDay)) return false;

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes <= endMinutes) {
      // Same day schedule
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight schedule
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  // Equality operators
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // For debugging
  @override
  String toString() {
    return 'ScheduleModel(id: $id, title: $title, days: $days, timeRange: ${getFormattedTimeRange()}, isActive: $isActive)';
  }
}
