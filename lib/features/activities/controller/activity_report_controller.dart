// features/activity/controllers/activity_report_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/local/models/app_model.dart';
import '../../../data/local/models/schedule_model.dart';
import '../../../data/services/schedule_service.dart';
import '../../../utils/constants/app_colors.dart';
import '../../dashboard/controllers/quick_mood_controller.dart';

// Model for activity data
class ActivityData {
  final String id;
  final String scheduleTitle;
  final String scheduleName;
  final DateTime activityDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<String> blockedAppIds;
  final List<AppModel> blockedApps;
  final bool wasActive;
  final IconData scheduleIcon;
  final Color scheduleIconColor;
  final ActivityType activityType;
  final Duration totalBlockedDuration;

  ActivityData({
    required this.id,
    required this.scheduleTitle,
    required this.scheduleName,
    required this.activityDate,
    required this.startTime,
    required this.endTime,
    required this.blockedAppIds,
    required this.blockedApps,
    required this.wasActive,
    required this.scheduleIcon,
    required this.scheduleIconColor,
    required this.activityType,
    required this.totalBlockedDuration,
  });

  // Helper getters
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDay =
        DateTime(activityDate.year, activityDate.month, activityDate.day);

    if (activityDay == today) {
      return 'Today';
    } else if (activityDay == yesterday) {
      return 'Yesterday';
    } else {
      return '${activityDate.day}/${activityDate.month}/${activityDate.year}';
    }
  }

  String get formattedTimeRange {
    final startHour = startTime.hour == 0
        ? 12
        : (startTime.hour > 12 ? startTime.hour - 12 : startTime.hour);
    final startPeriod = startTime.hour < 12 ? 'AM' : 'PM';
    final endHour = endTime.hour == 0
        ? 12
        : (endTime.hour > 12 ? endTime.hour - 12 : endTime.hour);
    final endPeriod = endTime.hour < 12 ? 'AM' : 'PM';

    return '$startHour:${startTime.minute.toString().padLeft(2, '0')} $startPeriod - $endHour:${endTime.minute.toString().padLeft(2, '0')} $endPeriod';
  }

  String get formattedDuration {
    final hours = totalBlockedDuration.inHours;
    final minutes = totalBlockedDuration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get activityDescription {
    switch (activityType) {
      case ActivityType.completed:
        return 'Blocked ${blockedApps.length} apps for $formattedDuration';
      case ActivityType.skipped:
        return 'Schedule was skipped';
      case ActivityType.active:
        return 'Currently blocking ${blockedApps.length} apps';
      case ActivityType.scheduled:
        return 'Scheduled to block ${blockedApps.length} apps';
    }
  }
}

enum ActivityType {
  completed,
  skipped,
  active,
  scheduled,
}

enum DateFilter {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  all,
}

class ActivityReportController extends GetxController {
  final ScheduleService _scheduleService = ScheduleService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final QuickModeController _quickModeController;

  // Observable lists and variables
  final RxList<ActivityData> activities = <ActivityData>[].obs;
  final RxList<ActivityData> filteredActivities = <ActivityData>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Filter and sorting options
  final Rx<DateFilter> selectedDateFilter = DateFilter.today.obs;
  final RxString searchQuery = ''.obs;
  final RxBool showOnlyActive = false.obs;
  final RxBool showOnlyCompleted = false.obs;

  // Statistics
  final RxInt totalActivitiesCount = 0.obs;
  final RxInt completedActivitiesCount = 0.obs;
  final RxInt activeActivitiesCount = 0.obs;
  final RxInt totalBlockedAppsCount = 0.obs;
  final Rx<Duration> totalBlockedTime = Duration.zero.obs;

  // Date selection
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool showDatePicker = false.obs;

  // Get current user ID from Firebase
  String get userId {
    final user = _auth.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      return 'default_user';
    }
  }

  // Check if user is authenticated
  bool get isUserAuthenticated {
    return _auth.currentUser != null;
  }

  @override
  void onInit() {
    super.onInit();
    try {
      _quickModeController = Get.find<QuickModeController>();
    } catch (e) {
      _quickModeController = Get.put(QuickModeController());
    }

    _checkAuthAndLoadData();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to date filter changes
    selectedDateFilter.listen((_) => _applyFilters());

    // Listen to search query changes
    searchQuery.listen((_) => _applyFilters());

    // Listen to filter toggles
    showOnlyActive.listen((_) => _applyFilters());
    showOnlyCompleted.listen((_) => _applyFilters());

    // Listen to selected date changes
    selectedDate.listen((_) => _applyFilters());
  }

  Future<void> _checkAuthAndLoadData() async {
    if (!isUserAuthenticated) {
      errorMessage.value = 'User not authenticated';
      return;
    }

    // Set user ID for QuickModeController if needed
    if (isUserAuthenticated) {
      _quickModeController.setUserId(userId);
    }

    await loadActivities();
  }

  Future<void> loadActivities() async {
    try {
      if (!isUserAuthenticated) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      isLoading.value = true;
      errorMessage.value = '';

      // Get user schedules
      final schedules = await _scheduleService.getAllSchedules(userId);

      // Get available apps from QuickModeController
      final availableApps = _quickModeController.availableApps.toList();

      // Convert schedules to activities
      final activityList = <ActivityData>[];

      for (final schedule in schedules) {
        // Create activities based on schedule history and current state
        final activityData =
            await _createActivityFromSchedule(schedule, availableApps);
        if (activityData != null) {
          activityList.add(activityData);
        }

        // If schedule is currently active, add current activity
        if (_isScheduleActiveNow(schedule)) {
          final currentActivity =
              _createCurrentActivity(schedule, availableApps);
          if (currentActivity != null) {
            activityList.add(currentActivity);
          }
        }

        // Create historical activities based on schedule pattern
        final historicalActivities =
            _createHistoricalActivities(schedule, availableApps);
        activityList.addAll(historicalActivities);
      }

      // Sort activities by date (newest first)
      activityList.sort((a, b) => b.activityDate.compareTo(a.activityDate));

      activities.value = activityList;
      _applyFilters();
      _updateStatistics();

      print('Loaded ${activities.length} activities for user: $userId');
    } catch (e) {
      errorMessage.value = 'Failed to load activities: $e';
      print('Error loading activities: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<ActivityData?> _createActivityFromSchedule(
      ScheduleModel schedule, List<AppModel> availableApps) async {
    try {
      // Get blocked apps for this schedule
      final blockedApps = <AppModel>[];
      for (final appId in schedule.blockedApps) {
        final app = availableApps.firstWhereOrNull((a) => a.id == appId);
        if (app != null) {
          blockedApps.add(app);
        }
      }

      // Calculate duration
      final startMinutes =
          schedule.startTime.hour * 60 + schedule.startTime.minute;
      final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;
      final durationMinutes = endMinutes > startMinutes
          ? endMinutes - startMinutes
          : (24 * 60) - startMinutes + endMinutes;

      final duration = Duration(minutes: durationMinutes);

      // Determine activity type
      ActivityType activityType;
      if (_isScheduleActiveNow(schedule)) {
        activityType = ActivityType.active;
      } else if (schedule.lastTriggered != null) {
        activityType = ActivityType.completed;
      } else {
        activityType = ActivityType.scheduled;
      }

      return ActivityData(
        id: '${schedule.id}_main',
        scheduleTitle: schedule.title,
        scheduleName: schedule.title,
        activityDate: schedule.lastTriggered ?? schedule.createdAt,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        blockedAppIds: schedule.blockedApps,
        blockedApps: blockedApps,
        wasActive: schedule.isActive,
        scheduleIcon: schedule.icon,
        scheduleIconColor: schedule.iconColor,
        activityType: activityType,
        totalBlockedDuration: duration,
      );
    } catch (e) {
      print('Error creating activity from schedule: $e');
      return null;
    }
  }

  ActivityData? _createCurrentActivity(
      ScheduleModel schedule, List<AppModel> availableApps) {
    try {
      if (!schedule.isActive) return null;

      // Get blocked apps for this schedule
      final blockedApps = <AppModel>[];
      for (final appId in schedule.blockedApps) {
        final app = availableApps.firstWhereOrNull((a) => a.id == appId);
        if (app != null) {
          blockedApps.add(app);
        }
      }

      // Calculate remaining duration
      final now = TimeOfDay.now();
      final nowMinutes = now.hour * 60 + now.minute;
      final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;
      final remainingMinutes =
          endMinutes > nowMinutes ? endMinutes - nowMinutes : 0;

      final duration = Duration(minutes: remainingMinutes);

      return ActivityData(
        id: '${schedule.id}_current',
        scheduleTitle: '${schedule.title} (Active)',
        scheduleName: schedule.title,
        activityDate: DateTime.now(),
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        blockedAppIds: schedule.blockedApps,
        blockedApps: blockedApps,
        wasActive: true,
        scheduleIcon: schedule.icon,
        scheduleIconColor: schedule.iconColor,
        activityType: ActivityType.active,
        totalBlockedDuration: duration,
      );
    } catch (e) {
      print('Error creating current activity: $e');
      return null;
    }
  }

  List<ActivityData> _createHistoricalActivities(
      ScheduleModel schedule, List<AppModel> availableApps) {
    final historicalActivities = <ActivityData>[];

    try {
      if (!schedule.isActive) return historicalActivities;

      // Create activities for the past week based on schedule days
      final now = DateTime.now();

      for (int daysBack = 1; daysBack <= 7; daysBack++) {
        final date = now.subtract(Duration(days: daysBack));
        final dayOfWeek = date.weekday;

        // Check if schedule was supposed to run on this day
        if (schedule.days.contains(dayOfWeek)) {
          // Get blocked apps for this schedule
          final blockedApps = <AppModel>[];
          for (final appId in schedule.blockedApps) {
            final app = availableApps.firstWhereOrNull((a) => a.id == appId);
            if (app != null) {
              blockedApps.add(app);
            }
          }

          // Calculate duration
          final startMinutes =
              schedule.startTime.hour * 60 + schedule.startTime.minute;
          final endMinutes =
              schedule.endTime.hour * 60 + schedule.endTime.minute;
          final durationMinutes = endMinutes > startMinutes
              ? endMinutes - startMinutes
              : (24 * 60) - startMinutes + endMinutes;

          final duration = Duration(minutes: durationMinutes);

          historicalActivities.add(
            ActivityData(
              id: '${schedule.id}_history_$daysBack',
              scheduleTitle: schedule.title,
              scheduleName: schedule.title,
              activityDate: date,
              startTime: schedule.startTime,
              endTime: schedule.endTime,
              blockedAppIds: schedule.blockedApps,
              blockedApps: blockedApps,
              wasActive: true,
              scheduleIcon: schedule.icon,
              scheduleIconColor: schedule.iconColor,
              activityType: ActivityType.completed,
              totalBlockedDuration: duration,
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating historical activities: $e');
    }

    return historicalActivities;
  }

  bool _isScheduleActiveNow(ScheduleModel schedule) {
    if (!schedule.isActive) return false;

    final now = DateTime.now();
    final currentDay = now.weekday;
    final currentTime = TimeOfDay.now();

    if (!schedule.days.contains(currentDay)) return false;

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes =
        schedule.startTime.hour * 60 + schedule.startTime.minute;
    final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;

    if (startMinutes > endMinutes) {
      // Schedule spans midnight
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }

    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  void _applyFilters() {
    var filtered = activities.toList();

    // Apply date filter
    switch (selectedDateFilter.value) {
      case DateFilter.today:
        final today = DateTime.now();
        filtered = filtered.where((activity) {
          return activity.activityDate.day == today.day &&
              activity.activityDate.month == today.month &&
              activity.activityDate.year == today.year;
        }).toList();
        break;
      case DateFilter.yesterday:
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        filtered = filtered.where((activity) {
          return activity.activityDate.day == yesterday.day &&
              activity.activityDate.month == yesterday.month &&
              activity.activityDate.year == yesterday.year;
        }).toList();
        break;
      case DateFilter.thisWeek:
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        filtered = filtered.where((activity) {
          return activity.activityDate
              .isAfter(startOfWeek.subtract(const Duration(days: 1)));
        }).toList();
        break;
      case DateFilter.thisMonth:
        final now = DateTime.now();
        filtered = filtered.where((activity) {
          return activity.activityDate.month == now.month &&
              activity.activityDate.year == now.year;
        }).toList();
        break;
      case DateFilter.all:
        // No filtering by date
        break;
    }

    // Apply activity type filters
    if (showOnlyActive.value) {
      filtered = filtered
          .where((activity) => activity.activityType == ActivityType.active)
          .toList();
    }

    if (showOnlyCompleted.value) {
      filtered = filtered
          .where((activity) => activity.activityType == ActivityType.completed)
          .toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((activity) {
        return activity.scheduleTitle.toLowerCase().contains(query) ||
            activity.blockedApps
                .any((app) => app.name.toLowerCase().contains(query));
      }).toList();
    }

    filteredActivities.value = filtered;
  }

  void _updateStatistics() {
    totalActivitiesCount.value = activities.length;
    completedActivitiesCount.value = activities
        .where((a) => a.activityType == ActivityType.completed)
        .length;
    activeActivitiesCount.value =
        activities.where((a) => a.activityType == ActivityType.active).length;

    final uniqueApps = <String>{};
    var totalDuration = Duration.zero;

    for (final activity in activities) {
      uniqueApps.addAll(activity.blockedAppIds);
      if (activity.activityType == ActivityType.completed) {
        totalDuration += activity.totalBlockedDuration;
      }
    }

    totalBlockedAppsCount.value = uniqueApps.length;
    totalBlockedTime.value = totalDuration;
  }

  // Public methods for UI interaction

  void setDateFilter(DateFilter filter) {
    selectedDateFilter.value = filter;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void toggleShowOnlyActive() {
    showOnlyActive.value = !showOnlyActive.value;
    if (showOnlyActive.value) {
      showOnlyCompleted.value = false;
    }
  }

  void toggleShowOnlyCompleted() {
    showOnlyCompleted.value = !showOnlyCompleted.value;
    if (showOnlyCompleted.value) {
      showOnlyActive.value = false;
    }
  }

  void clearAllFilters() {
    selectedDateFilter.value = DateFilter.today;
    searchQuery.value = '';
    showOnlyActive.value = false;
    showOnlyCompleted.value = false;
  }

  Future<void> refreshActivities() async {
    await loadActivities();
    _showCustomSnackbar(
      title: 'Refreshed!',
      message: 'Activity report has been updated',
      isSuccess: true,
      icon: Icons.refresh,
    );
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    showDatePicker.value = false;
  }

  void toggleDatePicker() {
    showDatePicker.value = !showDatePicker.value;
  }

  // Navigation methods
  void navigateToPreviousDate() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
  }

  void navigateToNextDate() {
    if (selectedDate.value.isBefore(DateTime.now())) {
      selectedDate.value = selectedDate.value.add(const Duration(days: 1));
    }
  }

  void navigateToToday() {
    selectedDate.value = DateTime.now();
    selectedDateFilter.value = DateFilter.today;
  }

  // Helper methods

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String getFilterDisplayName(DateFilter filter) {
    switch (filter) {
      case DateFilter.today:
        return 'Today';
      case DateFilter.yesterday:
        return 'Yesterday';
      case DateFilter.thisWeek:
        return 'This Week';
      case DateFilter.thisMonth:
        return 'This Month';
      case DateFilter.all:
        return 'All Time';
    }
  }

  Color getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.completed:
        return Colors.green;
      case ActivityType.active:
        return Colors.blue;
      case ActivityType.skipped:
        return Colors.orange;
      case ActivityType.scheduled:
        return Colors.grey;
    }
  }

  IconData getActivityTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.completed:
        return Icons.check_circle;
      case ActivityType.active:
        return Icons.play_circle;
      case ActivityType.skipped:
        return Icons.skip_next;
      case ActivityType.scheduled:
        return Icons.schedule;
    }
  }

  // FIXED: Safer Snackbar Implementation
  void _showCustomSnackbar({
    required String title,
    required String message,
    required bool isSuccess,
    IconData? icon,
  }) {
    try {
      // Close any existing snackbar safely
      _safeCloseSnackbar();

      // Wait a bit before showing new snackbar
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.context == null) {
          print('No context available for snackbar: $title - $message');
          return;
        }

        Get.snackbar(
          '',
          '',
          titleText: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon ?? (isSuccess ? Icons.check_circle : Icons.error),
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSuccess ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          messageText: const SizedBox.shrink(),
          backgroundColor: AppColors.containerBackground,
          borderRadius: 16,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: isSuccess ? 2 : 4),
          isDismissible: true,
          dismissDirection: DismissDirection.horizontal,
          animationDuration: const Duration(milliseconds: 600),
          boxShadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        );
      });
    } catch (e) {
      print('Error showing snackbar: $e');
      print('Message was: $title - $message');
    }
  }

  // FIXED: Safe method to close existing snackbar
  void _safeCloseSnackbar() {
    try {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
    } catch (e) {
      print('Error closing snackbar: $e');
      // Ignore the error and continue
    }
  }
}
