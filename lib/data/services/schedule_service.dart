// features/schedule/services/schedule_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/local/models/schedule_model.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference for schedules
  CollectionReference get _schedulesCollection =>
      _firestore.collection('schedules');

  // Create a new schedule
  Future<void> createSchedule(ScheduleModel schedule, String userId) async {
    try {
      final scheduleData = {
        'id': schedule.id,
        'userId': userId,
        'title': schedule.title,
        'iconCodePoint': schedule.icon.codePoint,
        'iconFontFamily': schedule.icon.fontFamily ?? 'MaterialIcons',
        'iconColor': schedule.iconColor.value,
        'days': schedule.days,
        'startTimeHour': schedule.startTime.hour,
        'startTimeMinute': schedule.startTime.minute,
        'endTimeHour': schedule.endTime.hour,
        'endTimeMinute': schedule.endTime.minute,
        'blockedApps': schedule.blockedApps,
        'isActive': schedule.isActive,
        'createdAt': Timestamp.fromDate(schedule.createdAt),
        'lastTriggered': schedule.lastTriggered != null
            ? Timestamp.fromDate(schedule.lastTriggered!)
            : null,
        'updatedAt': Timestamp.now(),
      };

      await _schedulesCollection.doc(schedule.id).set(scheduleData);

      print('Schedule created successfully in Firebase: ${schedule.title}');
    } catch (e) {
      print('Error creating schedule in Firebase: $e');
      throw Exception('Failed to create schedule: $e');
    }
  }

  // Update an existing schedule
  Future<void> updateSchedule(ScheduleModel schedule, String userId) async {
    try {
      final scheduleData = {
        'title': schedule.title,
        'iconCodePoint': schedule.icon.codePoint,
        'iconFontFamily': schedule.icon.fontFamily ?? 'MaterialIcons',
        'iconColor': schedule.iconColor.value,
        'days': schedule.days,
        'startTimeHour': schedule.startTime.hour,
        'startTimeMinute': schedule.startTime.minute,
        'endTimeHour': schedule.endTime.hour,
        'endTimeMinute': schedule.endTime.minute,
        'blockedApps': schedule.blockedApps,
        'isActive': schedule.isActive,
        'lastTriggered': schedule.lastTriggered != null
            ? Timestamp.fromDate(schedule.lastTriggered!)
            : null,
        'updatedAt': Timestamp.now(),
      };

      // Check if the schedule exists and belongs to the user
      final doc = await _schedulesCollection.doc(schedule.id).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Schedule not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        throw Exception('Unauthorized: Schedule does not belong to user');
      }

      await _schedulesCollection.doc(schedule.id).update(scheduleData);

      print('Schedule updated successfully in Firebase: ${schedule.title}');
    } catch (e) {
      print('Error updating schedule in Firebase: $e');
      throw Exception('Failed to update schedule: $e');
    }
  }

  // Delete a schedule
  Future<void> deleteSchedule(String scheduleId, String userId) async {
    try {
      // Check if the schedule exists and belongs to the user
      final doc = await _schedulesCollection.doc(scheduleId).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Schedule not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        throw Exception('Unauthorized: Schedule does not belong to user');
      }

      await _schedulesCollection.doc(scheduleId).delete();

      print('Schedule deleted successfully from Firebase: $scheduleId');
    } catch (e) {
      print('Error deleting schedule from Firebase: $e');
      throw Exception('Failed to delete schedule: $e');
    }
  }

  // Toggle schedule active state
  Future<void> toggleScheduleActive(
      String scheduleId, bool isActive, String userId) async {
    try {
      // Check if the schedule exists and belongs to the user
      final doc = await _schedulesCollection.doc(scheduleId).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Schedule not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        throw Exception('Unauthorized: Schedule does not belong to user');
      }

      await _schedulesCollection.doc(scheduleId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });

      print(
          'Schedule active state updated in Firebase: $scheduleId - $isActive');
    } catch (e) {
      print('Error toggling schedule active state in Firebase: $e');
      throw Exception('Failed to toggle schedule active state: $e');
    }
  }

  // Get all schedules for a user
  Future<List<ScheduleModel>> getAllSchedules(String userId) async {
    try {
      final querySnapshot = await _schedulesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final schedules = querySnapshot.docs.map((doc) {
        return _mapToScheduleModel(doc.data() as Map<String, dynamic>);
      }).toList();

      print(
          'Retrieved ${schedules.length} schedules from Firebase for user: $userId');
      return schedules;
    } catch (e) {
      print('Error getting schedules from Firebase: $e');
      throw Exception('Failed to get schedules: $e');
    }
  }

  // Get schedule by ID
  Future<ScheduleModel?> getScheduleById(
      String scheduleId, String userId) async {
    try {
      final doc = await _schedulesCollection.doc(scheduleId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        return null; // Don't return schedules from other users
      }

      return _mapToScheduleModel(data);
    } catch (e) {
      print('Error getting schedule by ID from Firebase: $e');
      return null;
    }
  }

  // Helper method to convert Firebase data to ScheduleModel
  ScheduleModel _mapToScheduleModel(Map<String, dynamic> data) {
    try {
      final days = List<int>.from(data['days'] ?? []);
      final blockedApps = List<String>.from(data['blockedApps'] ?? []);

      return ScheduleModel(
        id: data['id'] ?? '',
        title: data['title'] ?? '',
        icon: IconData(
          data['iconCodePoint'] ?? Icons.schedule.codePoint,
          fontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
        ),
        iconColor: Color(data['iconColor'] ?? Colors.blue.value),
        days: days,
        startTime: TimeOfDay(
          hour: data['startTimeHour'] ?? 8,
          minute: data['startTimeMinute'] ?? 0,
        ),
        endTime: TimeOfDay(
          hour: data['endTimeHour'] ?? 17,
          minute: data['endTimeMinute'] ?? 0,
        ),
        blockedApps: blockedApps,
        isActive: data['isActive'] ?? false,
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastTriggered: (data['lastTriggered'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      print('Error mapping schedule data from Firebase: $e');
      rethrow;
    }
  }

  // Get active schedules
  Future<List<ScheduleModel>> getActiveSchedules(String userId) async {
    try {
      final querySnapshot = await _schedulesCollection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final schedules = querySnapshot.docs.map((doc) {
        return _mapToScheduleModel(doc.data() as Map<String, dynamic>);
      }).toList();

      return schedules;
    } catch (e) {
      print('Error getting active schedules from Firebase: $e');
      throw Exception('Failed to get active schedules: $e');
    }
  }

  // Check if any schedule is currently active
  Future<ScheduleModel?> getCurrentlyActiveSchedule(String userId) async {
    try {
      final activeSchedules = await getActiveSchedules(userId);
      final now = DateTime.now();
      final currentDay = now.weekday;
      final currentTime = TimeOfDay.now();

      for (final schedule in activeSchedules) {
        if (schedule.days.contains(currentDay)) {
          if (_isTimeInRange(
              currentTime, schedule.startTime, schedule.endTime)) {
            return schedule;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error checking currently active schedule in Firebase: $e');
      return null;
    }
  }

  // Get schedules for a specific day
  Future<List<ScheduleModel>> getSchedulesForDay(String userId, int day) async {
    try {
      final allSchedules = await getAllSchedules(userId);
      return allSchedules
          .where((schedule) => schedule.days.contains(day))
          .toList();
    } catch (e) {
      print('Error getting schedules for day from Firebase: $e');
      throw Exception('Failed to get schedules for day: $e');
    }
  }

  // Update last triggered time
  Future<void> updateLastTriggered(String scheduleId, String userId) async {
    try {
      // Check if the schedule exists and belongs to the user
      final doc = await _schedulesCollection.doc(scheduleId).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Schedule not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        throw Exception('Unauthorized: Schedule does not belong to user');
      }

      await _schedulesCollection.doc(scheduleId).update({
        'lastTriggered': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      print(
          'Updated last triggered time for schedule in Firebase: $scheduleId');
    } catch (e) {
      print('Error updating last triggered time in Firebase: $e');
    }
  }

  // Check if an app is currently blocked by any schedule
  Future<bool> isAppBlockedBySchedule(
      String userId, String appPackageName) async {
    try {
      final currentSchedule = await getCurrentlyActiveSchedule(userId);
      if (currentSchedule == null) {
        return false;
      }

      return currentSchedule.blockedApps.contains(appPackageName);
    } catch (e) {
      print('Error checking if app is blocked in Firebase: $e');
      return false;
    }
  }

  // Get all blocked apps from active schedules
  Future<Set<String>> getAllBlockedApps(String userId) async {
    try {
      final activeSchedules = await getActiveSchedules(userId);
      final blockedApps = <String>{};

      final now = DateTime.now();
      final currentDay = now.weekday;
      final currentTime = TimeOfDay.now();

      for (final schedule in activeSchedules) {
        if (schedule.days.contains(currentDay)) {
          if (_isTimeInRange(
              currentTime, schedule.startTime, schedule.endTime)) {
            blockedApps.addAll(schedule.blockedApps);
          }
        }
      }

      return blockedApps;
    } catch (e) {
      print('Error getting all blocked apps from Firebase: $e');
      return {};
    }
  }

  // Helper method to check if time is in range
  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    // Handle overnight schedules (e.g., 22:00 to 06:00)
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }

    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  // Validate schedule conflicts
  Future<bool> hasScheduleConflict(
      String userId, List<int> days, TimeOfDay startTime, TimeOfDay endTime,
      {String? excludeScheduleId}) async {
    try {
      final existingSchedules = await getAllSchedules(userId);

      for (final schedule in existingSchedules) {
        // Skip if this is the schedule being edited
        if (excludeScheduleId != null && schedule.id == excludeScheduleId) {
          continue;
        }

        // Skip inactive schedules
        if (!schedule.isActive) {
          continue;
        }

        // Check for day overlap
        final hasCommonDays = days.any((day) => schedule.days.contains(day));
        if (!hasCommonDays) {
          continue;
        }

        // Check for time overlap
        if (_hasTimeOverlap(
            startTime, endTime, schedule.startTime, schedule.endTime)) {
          return true; // Conflict found
        }
      }

      return false; // No conflicts
    } catch (e) {
      print('Error checking schedule conflicts in Firebase: $e');
      return false;
    }
  }

  // Helper method to check time overlap
  bool _hasTimeOverlap(
      TimeOfDay start1, TimeOfDay end1, TimeOfDay start2, TimeOfDay end2) {
    final start1Minutes = start1.hour * 60 + start1.minute;
    final end1Minutes = end1.hour * 60 + end1.minute;
    final start2Minutes = start2.hour * 60 + start2.minute;
    final end2Minutes = end2.hour * 60 + end2.minute;

    // Handle overnight schedules
    bool overlap1 = false;
    bool overlap2 = false;

    if (start1Minutes > end1Minutes) {
      // First schedule is overnight
      overlap1 = (start2Minutes >= start1Minutes || end2Minutes <= end1Minutes);
    } else {
      // First schedule is same day
      overlap1 = (start2Minutes < end1Minutes && end2Minutes > start1Minutes);
    }

    if (start2Minutes > end2Minutes) {
      // Second schedule is overnight
      overlap2 = (start1Minutes >= start2Minutes || end1Minutes <= end2Minutes);
    } else {
      // Second schedule is same day
      overlap2 = (start1Minutes < end2Minutes && end1Minutes > start2Minutes);
    }

    return overlap1 || overlap2;
  }

  // Real-time schedule updates stream
  Stream<List<ScheduleModel>> getSchedulesStream(String userId) {
    return _schedulesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _mapToScheduleModel(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get schedule stream by ID for real-time updates
  Stream<ScheduleModel?> getScheduleStream(String scheduleId, String userId) {
    return _schedulesCollection.doc(scheduleId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        return null;
      }

      return _mapToScheduleModel(data);
    });
  }

  // Batch operations for better performance
  Future<void> batchUpdateSchedules(
      List<ScheduleModel> schedules, String userId) async {
    try {
      final batch = _firestore.batch();

      for (final schedule in schedules) {
        final scheduleData = {
          'title': schedule.title,
          'iconCodePoint': schedule.icon.codePoint,
          'iconFontFamily': schedule.icon.fontFamily ?? 'MaterialIcons',
          'iconColor': schedule.iconColor.value,
          'days': schedule.days,
          'startTimeHour': schedule.startTime.hour,
          'startTimeMinute': schedule.startTime.minute,
          'endTimeHour': schedule.endTime.hour,
          'endTimeMinute': schedule.endTime.minute,
          'blockedApps': schedule.blockedApps,
          'isActive': schedule.isActive,
          'lastTriggered': schedule.lastTriggered != null
              ? Timestamp.fromDate(schedule.lastTriggered!)
              : null,
          'updatedAt': Timestamp.now(),
        };

        batch.update(_schedulesCollection.doc(schedule.id), scheduleData);
      }

      await batch.commit();
      print('Batch updated ${schedules.length} schedules in Firebase');
    } catch (e) {
      print('Error in batch update schedules: $e');
      throw Exception('Failed to batch update schedules: $e');
    }
  }
}
