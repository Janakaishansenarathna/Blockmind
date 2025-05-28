// services/firebase_app_blocker_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../local/models/app_model.dart';
import '../local/models/schedule_model.dart';
import '../local/models/usage_log_model.dart';

class FirebaseAppBlockerService {
  static final FirebaseAppBlockerService _instance =
      FirebaseAppBlockerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  String? _currentUserId;

  // Factory constructor
  factory FirebaseAppBlockerService() {
    return _instance;
  }

  FirebaseAppBlockerService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Wait for Firebase Auth to initialize
      final user = _auth.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        await _ensureUserDocument();
      }

      _isInitialized = true;
      print('FirebaseAppBlockerService: Initialized successfully');
    } catch (e) {
      print('FirebaseAppBlockerService: Initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _ensureUserDocument() async {
    if (_currentUserId == null) return;

    try {
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId!).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(_currentUserId!).set({
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('users').doc(_currentUserId!).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('FirebaseAppBlockerService: Error ensuring user document: $e');
    }
  }

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    _ensureUserDocument();
  }

  // ===== APP-RELATED METHODS =====

  Future<List<AppModel>> getInstalledApps() async {
    // Return fallback apps for demo purposes
    // In a real app, this would integrate with device_apps package
    return [
      AppModel(
        id: 'com.facebook.katana',
        name: 'Facebook',
        packageName: 'com.facebook.katana',
        icon: Icons.facebook,
        iconColor: const Color(0xFF1877F2),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.instagram.android',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        icon: Icons.camera_alt,
        iconColor: const Color(0xFFE4405F),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.whatsapp',
        name: 'WhatsApp',
        packageName: 'com.whatsapp',
        icon: Icons.chat,
        iconColor: const Color(0xFF25D366),
        category: 'Communication',
      ),
      AppModel(
        id: 'com.google.android.youtube',
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        icon: Icons.play_circle_fill,
        iconColor: const Color(0xFFFF0000),
        category: 'Entertainment',
      ),
      AppModel(
        id: 'com.zhiliaoapp.musically',
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        icon: Icons.music_note,
        iconColor: const Color(0xFF000000),
        category: 'Entertainment',
      ),
      AppModel(
        id: 'com.twitter.android',
        name: 'Twitter',
        packageName: 'com.twitter.android',
        icon: Icons.alternate_email,
        iconColor: const Color(0xFF1DA1F2),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.snapchat.android',
        name: 'Snapchat',
        packageName: 'com.snapchat.android',
        icon: Icons.camera,
        iconColor: const Color(0xFFFFFC00),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.netflix.mediaclient',
        name: 'Netflix',
        packageName: 'com.netflix.mediaclient',
        icon: Icons.tv,
        iconColor: const Color(0xFFE50914),
        category: 'Entertainment',
      ),
    ];
  }

  Future<List<AppModel>> getBlockedApps() async {
    if (_currentUserId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('blocked_apps')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return AppModel(
          id: doc.id,
          name: data['name'] ?? '',
          packageName: data['packageName'] ?? '',
          icon: IconData(
            data['iconCodePoint'] ?? Icons.android.codePoint,
            fontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
          ),
          iconColor: Color(data['iconColor'] ?? Colors.blue.value),
          category: data['category'] ?? 'Other',
          isSystemApp: data['isSystemApp'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('FirebaseAppBlockerService: Error getting blocked apps: $e');
      return [];
    }
  }

  Future<void> addBlockedApp(AppModel app, {bool isQuickBlock = false}) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('blocked_apps')
          .doc(app.id)
          .set({
        'name': app.name,
        'packageName': app.packageName,
        'iconCodePoint': app.icon.codePoint,
        'iconFontFamily': app.icon.fontFamily,
        'iconColor': app.iconColor.value,
        'category': app.category,
        'isSystemApp': app.isSystemApp,
        'isQuickBlock': isQuickBlock,
        'blockedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('FirebaseAppBlockerService: Error adding blocked app: $e');
      rethrow;
    }
  }

  Future<void> removeBlockedApp(String appId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('blocked_apps')
          .doc(appId)
          .delete();
    } catch (e) {
      print('FirebaseAppBlockerService: Error removing blocked app: $e');
      rethrow;
    }
  }

  Future<void> removeAllBlockedApps({bool onlyQuickBlocks = false}) async {
    if (_currentUserId == null) return;

    try {
      Query query = _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('blocked_apps');

      if (onlyQuickBlocks) {
        query = query.where('isQuickBlock', isEqualTo: true);
      }

      final querySnapshot = await query.get();
      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('FirebaseAppBlockerService: Error removing blocked apps: $e');
      rethrow;
    }
  }

  // ===== QUICK BLOCK MODE METHODS =====

  Future<String> startQuickMode({
    required List<String> appIds,
    required int durationMinutes,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    try {
      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: durationMinutes));

      final quickModeData = {
        'userId': _currentUserId!,
        'blockedAppIds': appIds,
        'durationMinutes': durationMinutes,
        'startTime': Timestamp.fromDate(now),
        'endTime': Timestamp.fromDate(endTime),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .add(quickModeData);

      return docRef.id;
    } catch (e) {
      print('FirebaseAppBlockerService: Error starting quick mode: $e');
      rethrow;
    }
  }

  Future<void> stopQuickMode(String quickModeId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .doc(quickModeId)
          .update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('FirebaseAppBlockerService: Error stopping quick mode: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getActiveQuickMode() async {
    if (_currentUserId == null) return null;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final endTime = (data['endTime'] as Timestamp).toDate();

        if (DateTime.now().isBefore(endTime)) {
          return {
            'id': doc.id,
            ...data,
            'remainingTime': endTime.difference(DateTime.now()).inMilliseconds,
            'blockedApps': data['blockedAppIds'] ?? [],
          };
        } else {
          // Quick mode has expired, deactivate it
          await stopQuickMode(doc.id);
          return null;
        }
      }

      return null;
    } catch (e) {
      print('FirebaseAppBlockerService: Error getting active quick mode: $e');
      return null;
    }
  }

  // ===== SCHEDULE-RELATED METHODS =====

  Future<List<ScheduleModel>> getSchedules() async {
    if (_currentUserId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('schedules')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ScheduleModel(
          id: doc.id,
          title: data['title'] ?? '',
          icon: IconData(
            data['iconCodePoint'] ?? Icons.schedule.codePoint,
            fontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
          ),
          iconColor: Color(data['iconColor'] ?? Colors.blue.value),
          days: List<int>.from(data['days'] ?? []),
          startTime: TimeOfDay(
            hour: data['startHour'] ?? 0,
            minute: data['startMinute'] ?? 0,
          ),
          endTime: TimeOfDay(
            hour: data['endHour'] ?? 23,
            minute: data['endMinute'] ?? 59,
          ),
          blockedApps: List<String>.from(data['blockedApps'] ?? []),
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('FirebaseAppBlockerService: Error getting schedules: $e');
      return [];
    }
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('schedules')
          .doc(schedule.id)
          .set({
        'title': schedule.title,
        'iconCodePoint': schedule.icon.codePoint,
        'iconFontFamily': schedule.icon.fontFamily,
        'iconColor': schedule.iconColor.value,
        'days': schedule.days,
        'startHour': schedule.startTime.hour,
        'startMinute': schedule.startTime.minute,
        'endHour': schedule.endTime.hour,
        'endMinute': schedule.endTime.minute,
        'blockedApps': schedule.blockedApps,
        'isActive': schedule.isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('FirebaseAppBlockerService: Error adding schedule: $e');
      rethrow;
    }
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('schedules')
          .doc(schedule.id)
          .update({
        'title': schedule.title,
        'iconCodePoint': schedule.icon.codePoint,
        'iconFontFamily': schedule.icon.fontFamily,
        'iconColor': schedule.iconColor.value,
        'days': schedule.days,
        'startHour': schedule.startTime.hour,
        'startMinute': schedule.startTime.minute,
        'endHour': schedule.endTime.hour,
        'endMinute': schedule.endTime.minute,
        'blockedApps': schedule.blockedApps,
        'isActive': schedule.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('FirebaseAppBlockerService: Error updating schedule: $e');
      rethrow;
    }
  }

  Future<void> toggleScheduleActive(String scheduleId, bool isActive) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('schedules')
          .doc(scheduleId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('FirebaseAppBlockerService: Error toggling schedule: $e');
      rethrow;
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('schedules')
          .doc(scheduleId)
          .delete();
    } catch (e) {
      print('FirebaseAppBlockerService: Error deleting schedule: $e');
      rethrow;
    }
  }

  // ===== USAGE LOG METHODS =====

  Future<void> logAppUsage(UsageLogModel log) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('usage_logs')
          .doc(log.id)
          .set({
        'appId': log.appId,
        'date': Timestamp.fromDate(log.date),
        'durationSeconds': log.duration.inSeconds,
        'wasBlocked': log.wasBlocked,
        'scheduleId': log.scheduleId,
        'openCount': log.openCount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('FirebaseAppBlockerService: Error logging app usage: $e');
      rethrow;
    }
  }

  Future<Map<String, Duration>> getTodayUsageStats() async {
    if (_currentUserId == null) return {};

    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('usage_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .get();

      final Map<String, int> appDurations = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final appId = data['appId'] as String;
        final duration = data['durationSeconds'] as int;

        appDurations[appId] = (appDurations[appId] ?? 0) + duration;
      }

      return appDurations
          .map((appId, seconds) => MapEntry(appId, Duration(seconds: seconds)));
    } catch (e) {
      print('FirebaseAppBlockerService: Error getting usage stats: $e');
      return {};
    }
  }

  Future<int> getUnblockCount() async {
    if (_currentUserId == null) return 0;

    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('usage_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .where('wasBlocked', isEqualTo: true)
          .get();

      int totalUnblocks = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        totalUnblocks += (data['openCount'] as int? ?? 1);
      }

      return totalUnblocks;
    } catch (e) {
      print('FirebaseAppBlockerService: Error getting unblock count: $e');
      return 0;
    }
  }

  Future<Duration> getTotalSavedTime() async {
    if (_currentUserId == null) return Duration.zero;

    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('usage_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .where('wasBlocked', isEqualTo: true)
          .get();

      int totalSeconds = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        totalSeconds += (data['durationSeconds'] as int? ?? 0);
      }

      return Duration(seconds: totalSeconds);
    } catch (e) {
      print('FirebaseAppBlockerService: Error getting saved time: $e');
      return Duration.zero;
    }
  }

  // ===== MOOD TRACKING METHODS =====

  Future<void> saveMood({
    required int moodLevel,
    String? notes,
    DateTime? date,
  }) async {
    if (_currentUserId == null) return;

    try {
      final moodDate = date ?? DateTime.now();
      final dateOnly = DateTime(moodDate.year, moodDate.month, moodDate.day);
      final dateId =
          '${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('moods')
          .doc(dateId)
          .set({
        'moodLevel': moodLevel,
        'notes': notes ?? '',
        'date': Timestamp.fromDate(dateOnly),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('FirebaseAppBlockerService: Error saving mood: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getMoodForDate(DateTime date) async {
    if (_currentUserId == null) return null;

    try {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final dateId =
          '${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('moods')
          .doc(dateId)
          .get();

      if (doc.exists) {
        return doc.data();
      }

      return null;
    } catch (e) {
      print('FirebaseAppBlockerService: Error getting mood for date: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMoodHistory({int days = 30}) async {
    if (_currentUserId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('moods')
          .orderBy('date', descending: true)
          .limit(days)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'date': (data['date'] as Timestamp).millisecondsSinceEpoch,
        };
      }).toList();
    } catch (e) {
      print('FirebaseAppBlockerService: Error getting mood history: $e');
      return [];
    }
  }

  Future<void> resetMoodData() async {
    if (_currentUserId == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('moods')
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('FirebaseAppBlockerService: Error resetting mood data: $e');
      rethrow;
    }
  }

  // ===== APP BLOCKING LOGIC =====

  Future<bool> shouldBlockApp(String packageName) async {
    if (_currentUserId == null) return false;

    try {
      // Check if app is currently blocked
      final blockedAppDoc = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('blocked_apps')
          .doc(packageName)
          .get();

      if (blockedAppDoc.exists) {
        return true;
      }

      // Check active schedules
      final now = DateTime.now();
      final currentDay = now.weekday;
      final currentMinutes = now.hour * 60 + now.minute;

      final schedulesQuery = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('schedules')
          .where('isActive', isEqualTo: true)
          .where('blockedApps', arrayContains: packageName)
          .get();

      for (final scheduleDoc in schedulesQuery.docs) {
        final data = scheduleDoc.data();
        final days = List<int>.from(data['days'] ?? []);

        if (days.contains(currentDay)) {
          final startMinutes =
              (data['startHour'] ?? 0) * 60 + (data['startMinute'] ?? 0);
          final endMinutes =
              (data['endHour'] ?? 23) * 60 + (data['endMinute'] ?? 59);

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

          if (isInTimeRange) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print(
          'FirebaseAppBlockerService: Error checking if app should be blocked: $e');
      return false;
    }
  }

  // ===== STREAM METHODS FOR REAL-TIME UPDATES =====

  Stream<List<ScheduleModel>> watchSchedules() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('schedules')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ScheduleModel(
          id: doc.id,
          title: data['title'] ?? '',
          icon: IconData(
            data['iconCodePoint'] ?? Icons.schedule.codePoint,
            fontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
          ),
          iconColor: Color(data['iconColor'] ?? Colors.blue.value),
          days: List<int>.from(data['days'] ?? []),
          startTime: TimeOfDay(
            hour: data['startHour'] ?? 0,
            minute: data['startMinute'] ?? 0,
          ),
          endTime: TimeOfDay(
            hour: data['endHour'] ?? 23,
            minute: data['endMinute'] ?? 59,
          ),
          blockedApps: List<String>.from(data['blockedApps'] ?? []),
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    });
  }

  Stream<List<AppModel>> watchBlockedApps() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('blocked_apps')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppModel(
          id: doc.id,
          name: data['name'] ?? '',
          packageName: data['packageName'] ?? '',
          icon: IconData(
            data['iconCodePoint'] ?? Icons.android.codePoint,
            fontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
          ),
          iconColor: Color(data['iconColor'] ?? Colors.blue.value),
          category: data['category'] ?? 'Other',
          isSystemApp: data['isSystemApp'] ?? false,
        );
      }).toList();
    });
  }

  Stream<Map<String, dynamic>?> watchActiveQuickMode() {
    if (_currentUserId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('quick_modes')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final endTime = (data['endTime'] as Timestamp).toDate();

        if (DateTime.now().isBefore(endTime)) {
          return {
            'id': doc.id,
            ...data,
            'remainingTime': endTime.difference(DateTime.now()).inMilliseconds,
            'blockedApps': data['blockedAppIds'] ?? [],
          };
        }
      }
      return null;
    });
  }
}
