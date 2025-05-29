// features/schedule/screens/schedule_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/local/models/schedule_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';
import '../controllers/schedule_controller.dart';
import 'edit_shedule_screen.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final ScheduleModel schedule;

  const ScheduleDetailScreen({
    super.key,
    required this.schedule,
  });

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  final ScheduleController scheduleController = Get.find<ScheduleController>();
  List<String> appNames = [];
  bool isLoadingApps = true;
  late ScheduleModel currentSchedule;

  @override
  void initState() {
    super.initState();
    currentSchedule = widget.schedule;
    _loadAppNames();
    _listenToScheduleUpdates();
  }

  void _listenToScheduleUpdates() {
    // Listen for schedule updates
    ever(scheduleController.schedules, (List<ScheduleModel> schedules) {
      final updatedSchedule = schedules.firstWhereOrNull(
        (s) => s.id == widget.schedule.id,
      );
      if (updatedSchedule != null && mounted) {
        setState(() {
          currentSchedule = updatedSchedule;
        });
        _loadAppNames(); // Reload app names if schedule changed
      }
    });
  }

  Future<void> _loadAppNames() async {
    try {
      setState(() {
        isLoadingApps = true;
      });

      // Wait for apps to be loaded if they're not available yet
      if (scheduleController.availableApps.isEmpty) {
        await scheduleController.loadAvailableApps();
        // Give it a moment to load
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final names = <String>[];
      for (final appId in currentSchedule.blockedApps) {
        final app = scheduleController.getAppById(appId);
        if (app != null) {
          names.add(app.name);
        } else {
          // Try to find by package name as fallback
          final appByPackage =
              scheduleController.availableApps.firstWhereOrNull(
            (app) => app.packageName == appId || app.id == appId,
          );
          if (appByPackage != null) {
            names.add(appByPackage.name);
          } else {
            // Extract app name from package if possible
            String appName = appId;
            if (appId.contains('.')) {
              final parts = appId.split('.');
              appName = parts.last
                  .replaceAllMapped(
                    RegExp(r'([A-Z])'),
                    (match) => ' ${match.group(1)}',
                  )
                  .trim();
              appName = appName.isEmpty ? 'Unknown App' : appName;
            }
            names.add(appName);
          }
        }
      }

      if (mounted) {
        setState(() {
          appNames = names;
          isLoadingApps = false;
        });
      }
    } catch (e) {
      print('Error loading app names: $e');
      if (mounted) {
        setState(() {
          isLoadingApps = false;
          // Add fallback names
          appNames =
              currentSchedule.blockedApps.map((id) => 'App ($id)').toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Just go back normally
        return true;
      },
      child: GradientScaffold(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
            actions: [
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Schedule',
                onPressed: () => _editSchedule(),
              ),
              // More options menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                color: AppColors.cardBackground,
                onSelected: (value) {
                  switch (value) {
                    case 'duplicate':
                      _duplicateSchedule();
                      break;
                    case 'delete':
                      _confirmDelete();
                      break;
                    case 'share':
                      _shareSchedule();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, color: AppColors.textPrimary),
                        SizedBox(width: 12),
                        Text(
                          'Duplicate',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: AppColors.textPrimary),
                        SizedBox(width: 12),
                        Text(
                          'Share',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                _buildHeaderSection(),
                const SizedBox(height: 32),

                // Quick stats
                _buildQuickStats(),
                const SizedBox(height: 24),

                // Schedule info cards
                _buildInfoCard(
                  title: 'Schedule Days',
                  icon: Icons.calendar_today,
                  child: _buildDaysInfo(),
                ),
                const SizedBox(height: 16),

                _buildInfoCard(
                  title: 'Time Range',
                  icon: Icons.access_time,
                  child: _buildTimeInfo(),
                ),
                const SizedBox(height: 16),

                _buildInfoCard(
                  title: 'Blocked Apps',
                  icon: Icons.apps,
                  child: _buildBlockedAppsInfo(),
                ),
                const SizedBox(height: 16),

                // Active toggle
                _buildActiveToggle(),
                const SizedBox(height: 24),

                // Schedule insights
                _buildScheduleInsights(),
                const SizedBox(height: 16),

                // Additional info
                _buildAdditionalInfo(),

                // Action buttons
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editSchedule() async {
    try {
      print('Navigating to edit schedule: ${currentSchedule.id}');

      // Navigate to the dedicated edit screen
      final result = await Get.to(
        () => EditScheduleScreen(schedule: currentSchedule),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
        preventDuplicates: true,
      );

      // Refresh the current schedule data when returning
      if (result == true || result == null) {
        await _refreshScheduleData();
      }
    } catch (e) {
      print('Error navigating to edit screen: $e');

      // Show error message
      Get.snackbar(
        'Error',
        'Failed to open edit screen. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _duplicateSchedule() async {
    try {
      // Create a copy of the current schedule with a new ID and title
      final duplicatedSchedule = ScheduleModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${currentSchedule.title} (Copy)',
        icon: currentSchedule.icon,
        iconColor: currentSchedule.iconColor,
        days: List<int>.from(currentSchedule.days),
        startTime: currentSchedule.startTime,
        endTime: currentSchedule.endTime,
        blockedApps: List<String>.from(currentSchedule.blockedApps),
        isActive: false, // Start inactive by default
        createdAt: DateTime.now(),
      );

      // Navigate to edit screen for the duplicate
      final result = await Get.to(
        () => EditScheduleScreen(schedule: duplicatedSchedule),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
        preventDuplicates: true,
      );

      if (result == true) {
        // Show success message
        Get.snackbar(
          'Success',
          'Schedule duplicated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error duplicating schedule: $e');
      Get.snackbar(
        'Error',
        'Failed to duplicate schedule. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _shareSchedule() {
    final scheduleText = '''
📅 Schedule: ${currentSchedule.title}

🗓️ Days: ${scheduleController.formatDays(currentSchedule.days)}
⏰ Time: ${scheduleController.formatTimeOfDay(currentSchedule.startTime)} - ${scheduleController.formatTimeOfDay(currentSchedule.endTime)}
📱 Blocked Apps: ${currentSchedule.blockedApps.length} apps
${currentSchedule.isActive ? '✅ Active' : '⏸️ Inactive'}

${appNames.isNotEmpty ? 'Apps: ${appNames.join(', ')}' : ''}
''';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Schedule',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.containerBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                scheduleText,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      // Implement copy to clipboard
                      Get.snackbar(
                        'Copied',
                        'Schedule details copied to clipboard',
                        snackPosition: SnackPosition.TOP,
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      // Implement share functionality
                      Get.snackbar(
                        'Share',
                        'Opening share dialog...',
                        snackPosition: SnackPosition.TOP,
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshScheduleData() async {
    try {
      // Reload schedules to get updated data
      await scheduleController.loadSchedules();

      // Find the updated schedule
      final updatedSchedule = scheduleController.schedules.firstWhereOrNull(
        (s) => s.id == currentSchedule.id,
      );

      if (updatedSchedule != null && mounted) {
        setState(() {
          currentSchedule = updatedSchedule;
        });
        await _loadAppNames();
      }
    } catch (e) {
      print('Error refreshing schedule data: $e');
    }
  }

  Widget _buildQuickStats() {
    final isCurrentlyActive = _isScheduleActiveNow();
    final nextTrigger = _getNextTriggerTime();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Status',
            value: currentSchedule.isActive ? 'Active' : 'Inactive',
            icon: currentSchedule.isActive
                ? Icons.play_circle
                : Icons.pause_circle,
            color: currentSchedule.isActive
                ? AppColors.success
                : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Currently',
            value: isCurrentlyActive ? 'Running' : 'Idle',
            icon: isCurrentlyActive ? Icons.block : Icons.check_circle,
            color: isCurrentlyActive ? Colors.orange : AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Apps',
            value: '${currentSchedule.blockedApps.length}',
            icon: Icons.apps,
            color: AppColors.buttonPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInsights() {
    final nextTrigger = _getNextTriggerTime();
    final totalDuration = _getTotalDuration();
    final conflictingSchedules = _getConflictingSchedules();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.insights,
                color: AppColors.buttonPrimary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Schedule Insights',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (nextTrigger != null) ...[
            _buildInsightRow(
              Icons.schedule,
              'Next Activation',
              nextTrigger,
              AppColors.buttonPrimary,
            ),
            const SizedBox(height: 12),
          ],
          _buildInsightRow(
            Icons.timer,
            'Daily Duration',
            totalDuration,
            AppColors.success,
          ),
          if (conflictingSchedules.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInsightRow(
              Icons.warning,
              'Conflicts',
              '${conflictingSchedules.length} schedule(s)',
              Colors.orange,
            ),
          ],
          const SizedBox(height: 12),
          _buildInsightRow(
            Icons.block,
            'Block Frequency',
            '${currentSchedule.days.length} days/week',
            AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  bool _isScheduleActiveNow() {
    if (!currentSchedule.isActive) return false;

    final now = DateTime.now();
    final currentDay = now.weekday;
    final currentTime = TimeOfDay.now();

    if (currentSchedule.days.contains(currentDay)) {
      return _isTimeInRange(
          currentTime, currentSchedule.startTime, currentSchedule.endTime);
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

  String? _getNextTriggerTime() {
    if (!currentSchedule.isActive) return null;

    final now = DateTime.now();
    final currentDay = now.weekday;
    final currentTime = TimeOfDay.now();

    // Check if schedule is active today
    if (currentSchedule.days.contains(currentDay)) {
      final startMinutes = currentSchedule.startTime.hour * 60 +
          currentSchedule.startTime.minute;
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;

      if (currentMinutes < startMinutes) {
        return 'Today at ${scheduleController.formatTimeOfDay(currentSchedule.startTime)}';
      }
    }

    // Find next day
    for (int i = 1; i <= 7; i++) {
      final nextDay = ((currentDay + i - 1) % 7) + 1;
      if (currentSchedule.days.contains(nextDay)) {
        final dayNames = [
          '',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        return '${dayNames[nextDay]} at ${scheduleController.formatTimeOfDay(currentSchedule.startTime)}';
      }
    }

    return null;
  }

  String _getTotalDuration() {
    final startMinutes =
        currentSchedule.startTime.hour * 60 + currentSchedule.startTime.minute;
    final endMinutes =
        currentSchedule.endTime.hour * 60 + currentSchedule.endTime.minute;

    int duration = endMinutes - startMinutes;
    if (duration < 0) duration += 24 * 60;

    final hours = duration ~/ 60;
    final minutes = duration % 60;

    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  List<ScheduleModel> _getConflictingSchedules() {
    return scheduleController.schedules.where((schedule) {
      if (schedule.id == currentSchedule.id || !schedule.isActive) return false;

      // Check for day overlap
      final hasCommonDays =
          schedule.days.any((day) => currentSchedule.days.contains(day));
      if (!hasCommonDays) return false;

      // Check for time overlap
      final start1 = currentSchedule.startTime.hour * 60 +
          currentSchedule.startTime.minute;
      final end1 =
          currentSchedule.endTime.hour * 60 + currentSchedule.endTime.minute;
      final start2 = schedule.startTime.hour * 60 + schedule.startTime.minute;
      final end2 = schedule.endTime.hour * 60 + schedule.endTime.minute;

      return (start1 < end2 && end1 > start2);
    }).toList();
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Edit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _editSchedule,
            icon: const Icon(Icons.edit),
            label: const Text(
              'Edit Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary action buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _duplicateSchedule,
                icon: const Icon(Icons.copy),
                label: const Text(
                  'Duplicate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.buttonPrimary,
                  side: const BorderSide(color: AppColors.buttonPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete),
                label: const Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Center(
      child: Column(
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: currentSchedule.iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              currentSchedule.icon,
              size: 40,
              color: currentSchedule.iconColor,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            currentSchedule.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: currentSchedule.isActive
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.textMuted.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentSchedule.isActive
                        ? AppColors.success
                        : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currentSchedule.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: currentSchedule.isActive
                        ? AppColors.success
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.buttonPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDaysInfo() {
    final days = currentSchedule.days;
    final dayWidgets = <Widget>[];
    final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 1; i <= 7; i++) {
      final isSelected = days.contains(i);
      dayWidgets.add(
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.buttonPrimary.withOpacity(0.2)
                : AppColors.background.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? AppColors.buttonPrimary
                  : AppColors.borderColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              dayNames[i].substring(0, 1),
              style: TextStyle(
                color: isSelected
                    ? AppColors.buttonPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: dayWidgets,
        ),
        const SizedBox(height: 12),
        Text(
          scheduleController.formatDays(days),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start Time',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                scheduleController.formatTimeOfDay(currentSchedule.startTime),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward,
          color: AppColors.textSecondary,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'End Time',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                scheduleController.formatTimeOfDay(currentSchedule.endTime),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedAppsInfo() {
    if (isLoadingApps) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(
            color: AppColors.buttonPrimary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${currentSchedule.blockedApps.length} Apps Blocked',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (appNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: appNames.map((appName) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.buttonPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.buttonPrimary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  appName,
                  style: const TextStyle(
                    color: AppColors.buttonPrimary,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Text(
            'No app names available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentSchedule.isActive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.borderColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule Status',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentSchedule.isActive
                    ? 'Schedule is currently active'
                    : 'Schedule is currently inactive',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Switch(
            value: currentSchedule.isActive,
            onChanged: (value) async {
              await scheduleController.toggleScheduleActive(
                currentSchedule.id,
                value,
              );
              setState(() {
                currentSchedule = ScheduleModel(
                  id: currentSchedule.id,
                  title: currentSchedule.title,
                  icon: currentSchedule.icon,
                  iconColor: currentSchedule.iconColor,
                  days: currentSchedule.days,
                  startTime: currentSchedule.startTime,
                  endTime: currentSchedule.endTime,
                  blockedApps: currentSchedule.blockedApps,
                  isActive: value,
                  createdAt: currentSchedule.createdAt,
                  lastTriggered: currentSchedule.lastTriggered,
                );
              });
            },
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.textSecondary,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Additional Information',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Created',
            _formatDate(currentSchedule.createdAt),
          ),
          if (currentSchedule.lastTriggered != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Last Triggered',
              _formatDate(currentSchedule.lastTriggered!),
            ),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(
            'Schedule ID',
            currentSchedule.id,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
        content: Text(
          'Are you sure you want to delete "${currentSchedule.title}"? This action cannot be undone.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await scheduleController.deleteSchedule(currentSchedule.id);
              // The controller will handle navigation
            },
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
  }
}
