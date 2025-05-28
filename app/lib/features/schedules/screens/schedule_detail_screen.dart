// features/schedule/screens/schedule_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/local/models/schedule_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';
import '../controllers/schedule_controller.dart';
import 'create_schedule_screen.dart';

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
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete Schedule',
                onPressed: () => _confirmDelete(),
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
    // try {
    //   print('Preparing to edit schedule: ${currentSchedule.id}');

    //   // Reset form first to ensure clean state
    //   scheduleController.resetForm();

    //   // Wait a moment for the reset to complete
    //   await Future.delayed(const Duration(milliseconds: 100));

    //   // Prepare form for editing
    //   scheduleController.prepareForEdit(currentSchedule);

    //   print('Edit mode set: ${scheduleController.isEditMode.value}');
    //   print(
    //       'Editing schedule ID: ${scheduleController.editingScheduleId.value}');

    //   // Navigate to create/edit screen
    //   final result = await Get.to(
    //     () => const CreateScheduleScreen(),
    //     transition: Transition.rightToLeft,
    //     duration: const Duration(milliseconds: 300),
    //     preventDuplicates: true,
    //   );

    //   // Refresh the current schedule data when returning
    //   if (result == true) {
    //     await _refreshScheduleData();
    //   }
    // } catch (e) {
    //   print('Error navigating to edit screen: $e');

    //   // Show error message
    //   Get.snackbar(
    //     'Error',
    //     'Failed to open edit screen. Please try again.',
    //     snackPosition: SnackPosition.TOP,
    //     backgroundColor: Colors.red,
    //     colorText: Colors.white,
    //     duration: const Duration(seconds: 3),
    //   );
    // }
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

        // Delete Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete),
            label: const Text(
              'Delete Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
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
