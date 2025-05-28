// features/schedule/controllers/schedule_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/local/models/app_model.dart';
import '../../../data/local/models/schedule_model.dart';
import '../../../data/services/schedule_service.dart';
import '../../dashboard/controllers/app_controller.dart';
import '../../../utils/constants/app_colors.dart';

class ScheduleController extends GetxController {
  final ScheduleService _scheduleService = ScheduleService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final AppController _appController;

  // Observable lists and variables
  final RxList<ScheduleModel> schedules = <ScheduleModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  // Form controllers
  final TextEditingController titleController = TextEditingController();
  final RxList<int> selectedDays = <int>[].obs;
  final Rx<TimeOfDay> startTime = const TimeOfDay(hour: 8, minute: 0).obs;
  final Rx<TimeOfDay> endTime = const TimeOfDay(hour: 17, minute: 0).obs;
  final RxList<String> selectedAppIds = <String>[].obs;
  final Rx<IconData> selectedIcon = Icons.school.obs;
  final Rx<Color> selectedIconColor = Colors.blue.obs;

  // Editing state
  final RxnString editingScheduleId = RxnString();
  final RxBool isEditMode = false.obs;

  // Available apps for selection
  final RxList<AppModel> availableApps = <AppModel>[].obs;
  final RxList<AppModel> filteredApps = <AppModel>[].obs;
  final RxString searchQuery = ''.obs;

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
      _appController = Get.find<AppController>();
    } catch (e) {
      _appController = Get.put(AppController());
    }

    _checkAuthAndLoadData();
  }

  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }

  Future<void> _checkAuthAndLoadData() async {
    if (!isUserAuthenticated) {
      errorMessage.value = 'User not authenticated';
      return;
    }

    loadSchedules();
    loadAvailableApps();
  }

  Future<void> loadSchedules() async {
    try {
      if (!isUserAuthenticated) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final loadedSchedules = await _scheduleService.getAllSchedules(userId);
      schedules.value = loadedSchedules;

      print('Loaded ${schedules.length} schedules for user: $userId');
    } catch (e) {
      errorMessage.value = 'Failed to load schedules: $e';
      print('Error loading schedules: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAvailableApps() async {
    try {
      final apps = await _appController.getAllApps();
      availableApps.value = apps;
      filteredApps.value = apps;
    } catch (e) {
      print('Error loading available apps: $e');
      availableApps.value = [
        AppModel(
          id: 'com.facebook.katana',
          name: 'Facebook',
          packageName: 'com.facebook.katana',
          icon: Icons.facebook,
          iconColor: Colors.blue,
        ),
        AppModel(
          id: 'com.instagram.android',
          name: 'Instagram',
          packageName: 'com.instagram.android',
          icon: Icons.camera_alt,
          iconColor: Colors.pink,
        ),
        AppModel(
          id: 'com.twitter.android',
          name: 'Twitter',
          packageName: 'com.twitter.android',
          icon: Icons.alternate_email,
          iconColor: Colors.lightBlue,
        ),
        AppModel(
          id: 'com.whatsapp',
          name: 'WhatsApp',
          packageName: 'com.whatsapp',
          icon: Icons.chat,
          iconColor: Colors.green,
        ),
        AppModel(
          id: 'com.snapchat.android',
          name: 'Snapchat',
          packageName: 'com.snapchat.android',
          icon: Icons.camera,
          iconColor: Colors.yellow,
        ),
      ];
      filteredApps.value = availableApps;
    }
  }

  // Custom Modern Snackbar - Safe version
  void _showCustomSnackbar({
    required String title,
    required String message,
    required bool isSuccess,
    IconData? icon,
  }) {
    // Use try-catch to prevent errors
    try {
      // Check if we have a valid context
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
                color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
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
    } catch (e) {
      print('Error showing snackbar: $e');
      print('Message was: $title - $message');
    }
  }

  void searchApps(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredApps.value = availableApps;
    } else {
      filteredApps.value = availableApps
          .where((app) =>
              app.name.toLowerCase().contains(query.toLowerCase()) ||
              app.packageName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  void toggleAppSelection(String appId) {
    if (selectedAppIds.contains(appId)) {
      selectedAppIds.remove(appId);
    } else {
      selectedAppIds.add(appId);
    }
  }

  bool isAppSelected(String appId) {
    return selectedAppIds.contains(appId);
  }

  void toggleDay(int day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
      selectedDays.sort();
    }
  }

  bool isDaySelected(int day) {
    return selectedDays.contains(day);
  }

  void selectAllDays() {
    selectedDays.value = [1, 2, 3, 4, 5, 6, 7];
  }

  void selectWeekdays() {
    selectedDays.value = [1, 2, 3, 4, 5];
  }

  void selectWeekends() {
    selectedDays.value = [6, 7];
  }

  void clearSelectedDays() {
    selectedDays.clear();
  }

  void setStartTime(TimeOfDay time) {
    startTime.value = time;
  }

  void setEndTime(TimeOfDay time) {
    endTime.value = time;
  }

  void setSelectedIcon(IconData icon, Color color) {
    selectedIcon.value = icon;
    selectedIconColor.value = color;
  }

  void resetForm() {
    titleController.clear();
    selectedDays.clear();
    startTime.value = const TimeOfDay(hour: 8, minute: 0);
    endTime.value = const TimeOfDay(hour: 17, minute: 0);
    selectedAppIds.clear();
    selectedIcon.value = Icons.school;
    selectedIconColor.value = Colors.blue;
    isEditMode.value = false;
    editingScheduleId.value = null;
    searchQuery.value = '';
    filteredApps.value = availableApps;
    errorMessage.value = '';
    successMessage.value = '';
  }

  void prepareForEdit(ScheduleModel schedule) {
    isEditMode.value = true;
    editingScheduleId.value = schedule.id;

    titleController.text = schedule.title;
    selectedDays.value = List<int>.from(schedule.days);
    startTime.value = schedule.startTime;
    endTime.value = schedule.endTime;
    selectedAppIds.value = List<String>.from(schedule.blockedApps);
    selectedIcon.value = schedule.icon;
    selectedIconColor.value = schedule.iconColor;
  }

  String? validateForm() {
    if (!isUserAuthenticated) {
      return 'Please log in to create schedules';
    }

    if (titleController.text.trim().isEmpty) {
      return 'Please enter a schedule title';
    }
    if (selectedDays.isEmpty) {
      return 'Please select at least one day';
    }
    if (selectedAppIds.isEmpty) {
      return 'Please select at least one app to block';
    }

    final startMinutes = startTime.value.hour * 60 + startTime.value.minute;
    final endMinutes = endTime.value.hour * 60 + endTime.value.minute;

    if (startMinutes >= endMinutes) {
      return 'End time must be after start time';
    }

    return null;
  }

  Future<bool> checkForConflicts() async {
    try {
      if (!isUserAuthenticated) return false;

      return await _scheduleService.hasScheduleConflict(
        userId,
        selectedDays.toList(),
        startTime.value,
        endTime.value,
        excludeScheduleId: editingScheduleId.value,
      );
    } catch (e) {
      print('Error checking conflicts: $e');
      return false;
    }
  }

  Future<bool> createSchedule() async {
    try {
      final validationError = validateForm();
      if (validationError != null) {
        _showCustomSnackbar(
          title: 'Validation Error',
          message: validationError,
          isSuccess: false,
          icon: Icons.warning,
        );
        return false;
      }

      final hasConflict = await checkForConflicts();
      if (hasConflict) {
        _showCustomSnackbar(
          title: 'Schedule Conflict',
          message: 'This schedule conflicts with an existing active schedule',
          isSuccess: false,
          icon: Icons.error,
        );
        return false;
      }

      isLoading.value = true;

      final schedule = ScheduleModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleController.text.trim(),
        icon: selectedIcon.value,
        iconColor: selectedIconColor.value,
        days: List<int>.from(selectedDays),
        startTime: startTime.value,
        endTime: endTime.value,
        blockedApps: List<String>.from(selectedAppIds),
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _scheduleService.createSchedule(schedule, userId);

      // Update local state immediately
      schedules.add(schedule);

      // Reload from Firebase to ensure consistency
      await loadSchedules();

      _showCustomSnackbar(
        title: 'Success!',
        message: 'Schedule "${schedule.title}" created successfully',
        isSuccess: true,
        icon: Icons.schedule,
      );

      // Navigate back safely without conflicts
      Future.delayed(const Duration(milliseconds: 800), () {
        try {
          if (Get.isRegistered<ScheduleController>() && Get.context != null) {
            Get.back();
          }
        } catch (e) {
          print('Navigation error: $e');
        }
      });

      return true;
    } catch (e) {
      _showCustomSnackbar(
        title: 'Error',
        message: 'Failed to create schedule: ${e.toString()}',
        isSuccess: false,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateSchedule() async {
    try {
      if (editingScheduleId.value == null) {
        return false;
      }

      final validationError = validateForm();
      if (validationError != null) {
        _showCustomSnackbar(
          title: 'Validation Error',
          message: validationError,
          isSuccess: false,
          icon: Icons.warning,
        );
        return false;
      }

      final hasConflict = await checkForConflicts();
      if (hasConflict) {
        _showCustomSnackbar(
          title: 'Schedule Conflict',
          message: 'This schedule conflicts with an existing active schedule',
          isSuccess: false,
          icon: Icons.error,
        );
        return false;
      }

      isLoading.value = true;

      final originalSchedule = schedules.firstWhereOrNull(
        (s) => s.id == editingScheduleId.value,
      );

      final updatedSchedule = ScheduleModel(
        id: editingScheduleId.value!,
        title: titleController.text.trim(),
        icon: selectedIcon.value,
        iconColor: selectedIconColor.value,
        days: List<int>.from(selectedDays),
        startTime: startTime.value,
        endTime: endTime.value,
        blockedApps: List<String>.from(selectedAppIds),
        isActive: originalSchedule?.isActive ?? true,
        createdAt: originalSchedule?.createdAt ?? DateTime.now(),
        lastTriggered: originalSchedule?.lastTriggered,
      );

      await _scheduleService.updateSchedule(updatedSchedule, userId);

      // Update local state immediately
      final index =
          schedules.indexWhere((s) => s.id == editingScheduleId.value);
      if (index != -1) {
        schedules[index] = updatedSchedule;
      }

      // Reload from Firebase to ensure consistency
      await loadSchedules();

      _showCustomSnackbar(
        title: 'Updated!',
        message: 'Schedule "${updatedSchedule.title}" updated successfully',
        isSuccess: true,
        icon: Icons.edit,
      );

      // Navigate back safely without conflicts
      Future.delayed(const Duration(milliseconds: 800), () {
        try {
          if (Get.isRegistered<ScheduleController>() && Get.context != null) {
            Get.back();
          }
        } catch (e) {
          print('Navigation error: $e');
        }
      });

      return true;
    } catch (e) {
      _showCustomSnackbar(
        title: 'Error',
        message: 'Failed to update schedule: ${e.toString()}',
        isSuccess: false,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleScheduleActive(String scheduleId, bool isActive) async {
    try {
      if (!isUserAuthenticated) {
        _showCustomSnackbar(
          title: 'Authentication Required',
          message: 'Please log in to manage schedules',
          isSuccess: false,
          icon: Icons.login,
        );
        return;
      }

      // Update local state immediately for instant UI feedback
      final index = schedules.indexWhere((s) => s.id == scheduleId);
      if (index != -1) {
        final originalSchedule = schedules[index];
        final updatedSchedule = ScheduleModel(
          id: originalSchedule.id,
          title: originalSchedule.title,
          icon: originalSchedule.icon,
          iconColor: originalSchedule.iconColor,
          days: originalSchedule.days,
          startTime: originalSchedule.startTime,
          endTime: originalSchedule.endTime,
          blockedApps: originalSchedule.blockedApps,
          isActive: isActive,
          createdAt: originalSchedule.createdAt,
          lastTriggered: originalSchedule.lastTriggered,
        );
        schedules[index] = updatedSchedule;
      }

      await _scheduleService.toggleScheduleActive(scheduleId, isActive, userId);

      _showCustomSnackbar(
        title: isActive ? 'Activated' : 'Deactivated',
        message:
            'Schedule ${isActive ? 'activated' : 'deactivated'} successfully',
        isSuccess: true,
        icon: isActive ? Icons.play_circle : Icons.pause_circle,
      );
    } catch (e) {
      // Revert local state if Firebase update fails
      await loadSchedules();
      _showCustomSnackbar(
        title: 'Error',
        message: 'Failed to update schedule status',
        isSuccess: false,
      );
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      if (!isUserAuthenticated) {
        _showCustomSnackbar(
          title: 'Authentication Required',
          message: 'Please log in to manage schedules',
          isSuccess: false,
          icon: Icons.login,
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Schedule',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this schedule? This action cannot be undone.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isLoading.value = true;

      // Get schedule name for confirmation message
      final schedule = schedules.firstWhereOrNull((s) => s.id == scheduleId);
      final scheduleName = schedule?.title ?? 'Schedule';

      // Remove from local state immediately
      schedules.removeWhere((s) => s.id == scheduleId);

      await _scheduleService.deleteSchedule(scheduleId, userId);

      _showCustomSnackbar(
        title: 'Deleted!',
        message: '"$scheduleName" deleted successfully',
        isSuccess: true,
        icon: Icons.delete_sweep,
      );
    } catch (e) {
      // Reload schedules if deletion fails
      await loadSchedules();
      _showCustomSnackbar(
        title: 'Error',
        message: 'Failed to delete schedule',
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onUserAuthChanged() {
    if (isUserAuthenticated) {
      loadSchedules();
      loadAvailableApps();
    } else {
      schedules.clear();
      errorMessage.value = 'User not authenticated';
    }
  }

  String? get userEmail => _auth.currentUser?.email;
  String? get userDisplayName => _auth.currentUser?.displayName;

  int get activeSchedulesCount {
    return schedules.where((s) => s.isActive).length;
  }

  int get totalBlockedAppsCount {
    final Set<String> uniqueApps = {};
    for (final schedule in schedules.where((s) => s.isActive)) {
      uniqueApps.addAll(schedule.blockedApps);
    }
    return uniqueApps.length;
  }

  bool isAnyScheduleActiveNow() {
    final now = DateTime.now();
    final currentDay = now.weekday;
    final currentTime = TimeOfDay.now();

    for (final schedule in schedules.where((s) => s.isActive)) {
      if (schedule.days.contains(currentDay)) {
        if (_isTimeInRange(currentTime, schedule.startTime, schedule.endTime)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }

    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  ScheduleModel? getCurrentlyActiveSchedule() {
    final now = DateTime.now();
    final currentDay = now.weekday;
    final currentTime = TimeOfDay.now();

    for (final schedule in schedules.where((s) => s.isActive)) {
      if (schedule.days.contains(currentDay)) {
        if (_isTimeInRange(currentTime, schedule.startTime, schedule.endTime)) {
          return schedule;
        }
      }
    }

    return null;
  }

  String formatTimeOfDay(TimeOfDay time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String formatDays(List<int> days) {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && days.every((d) => d >= 1 && d <= 5))
      return 'Weekdays';
    if (days.length == 2 && days.contains(6) && days.contains(7))
      return 'Weekends';

    final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d]).join(', ');
  }
}
