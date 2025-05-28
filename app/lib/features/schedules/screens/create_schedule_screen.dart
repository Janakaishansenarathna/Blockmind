// features/schedule/screens/create_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';
import '../controllers/schedule_controller.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final ScheduleController scheduleController = Get.find<ScheduleController>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBackPressed();
        return false;
      },
      child: GradientScaffold(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Obx(() => Text(
                  scheduleController.isEditMode.value
                      ? 'Edit Schedule'
                      : 'Create Schedule',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBackPressed,
            ),
          ),
          body: Obx(() => scheduleController.isOperationInProgress.value
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.buttonPrimary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon and Title Section
                      _buildIconAndTitleSection(),
                      const SizedBox(height: 32),

                      // Blocked Apps Section
                      _buildBlockedAppsSection(),
                      const SizedBox(height: 24),

                      // Schedule Days Section
                      _buildScheduleDaysSection(),
                      const SizedBox(height: 24),

                      // Time Range Section
                      _buildTimeRangeSection(),
                      const SizedBox(height: 32),

                      // Save Button
                      _buildSaveButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                )),
        ),
      ),
    );
  }

  void _handleBackPressed() {
    if (scheduleController.isOperationInProgress.value) {
      // Don't allow back navigation during operation
      return;
    }

    // Show confirmation if form has data
    if (_hasFormData()) {
      _showExitConfirmationDialog();
    } else {
      scheduleController.resetForm();
      Get.back();
    }
  }

  bool _hasFormData() {
    return scheduleController.titleController.text.trim().isNotEmpty ||
        scheduleController.selectedDays.isNotEmpty ||
        scheduleController.selectedAppIds.isNotEmpty ||
        scheduleController.startTime.value !=
            const TimeOfDay(hour: 8, minute: 0) ||
        scheduleController.endTime.value !=
            const TimeOfDay(hour: 17, minute: 0);
  }

  void _showExitConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Discard Changes?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to go back? All changes will be lost.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Stay',
              style: TextStyle(color: AppColors.buttonPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              scheduleController.resetForm();
              Get.back(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Widget _buildIconAndTitleSection() {
    return Center(
      child: Column(
        children: [
          // Icon selector
          GestureDetector(
            onTap: () => _showIconSelectionDialog(),
            child: Obx(() => Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: scheduleController.selectedIconColor.value
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scheduleController.selectedIconColor.value
                              .withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        scheduleController.selectedIcon.value,
                        size: 40,
                        color: scheduleController.selectedIconColor.value,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.buttonPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )),
          ),
          const SizedBox(height: 16),

          // Title input
          TextField(
            controller: scheduleController.titleController,
            textAlign: TextAlign.center,
            maxLength: 50,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Schedule Name',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              border: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.borderColor.withOpacity(0.3),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.buttonPrimary,
                  width: 2,
                ),
              ),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAppsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Blocked Apps',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showAppSelectionDialog(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.containerBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.buttonPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.apps,
                    color: AppColors.buttonPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scheduleController.selectedAppIds.isEmpty
                                ? 'Select apps to block'
                                : 'Apps to block',
                            style: TextStyle(
                              color: scheduleController.selectedAppIds.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (scheduleController.selectedAppIds.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${scheduleController.selectedAppIds.length} apps selected',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      )),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Days',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Quick selection buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickDayButton(
                'Every Day',
                () => scheduleController.selectAllDays(),
              ),
              const SizedBox(width: 8),
              _buildQuickDayButton(
                'Weekdays',
                () => scheduleController.selectWeekdays(),
              ),
              const SizedBox(width: 8),
              _buildQuickDayButton(
                'Weekends',
                () => scheduleController.selectWeekends(),
              ),
              const SizedBox(width: 8),
              _buildQuickDayButton(
                'Clear',
                () => scheduleController.clearSelectedDays(),
                color: AppColors.error,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Day selector
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDayButton(1, 'M'),
                _buildDayButton(2, 'T'),
                _buildDayButton(3, 'W'),
                _buildDayButton(4, 'T'),
                _buildDayButton(5, 'F'),
                _buildDayButton(6, 'S'),
                _buildDayButton(7, 'S'),
              ],
            )),
        const SizedBox(height: 8),

        // Selected days text
        Obx(() => Text(
              scheduleController.selectedDays.isEmpty
                  ? 'No days selected'
                  : scheduleController
                      .formatDays(scheduleController.selectedDays),
              style: TextStyle(
                color: scheduleController.selectedDays.isEmpty
                    ? AppColors.error
                    : AppColors.textSecondary,
                fontSize: 14,
              ),
            )),
      ],
    );
  }

  Widget _buildQuickDayButton(String label, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.buttonPrimary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (color ?? AppColors.buttonPrimary).withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color ?? AppColors.buttonPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDayButton(int day, String label) {
    final isSelected = scheduleController.isDaySelected(day);

    return GestureDetector(
      onTap: () => scheduleController.toggleDay(day),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonPrimary
              : AppColors.containerBackground,
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
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Range',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Start time
            Expanded(
              child: _buildTimeSelector(
                label: 'Start Time',
                time: scheduleController.startTime.value,
                onTap: () => _selectTime(true),
              ),
            ),
            const SizedBox(width: 16),

            // End time
            Expanded(
              child: _buildTimeSelector(
                label: 'End Time',
                time: scheduleController.endTime.value,
                onTap: () => _selectTime(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.containerBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppColors.buttonPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  scheduleController.formatTimeOfDay(time),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: scheduleController.isLoading.value ||
                    scheduleController.isOperationInProgress.value
                ? null
                : () async {
                    // Prevent multiple taps
                    if (scheduleController.isOperationInProgress.value) return;

                    if (scheduleController.isEditMode.value) {
                      await scheduleController.updateSchedule();
                    } else {
                      await scheduleController.createSchedule();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppColors.buttonPrimary.withOpacity(0.5),
            ),
            child: scheduleController.isLoading.value ||
                    scheduleController.isOperationInProgress.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    scheduleController.isEditMode.value
                        ? 'Update Schedule'
                        : 'Create Schedule',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ));
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? scheduleController.startTime.value
          : scheduleController.endTime.value,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.buttonPrimary,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStartTime) {
        scheduleController.setStartTime(picked);
      } else {
        scheduleController.setEndTime(picked);
      }
    }
  }

  void _showIconSelectionDialog() {
    final List<Map<String, dynamic>> icons = [
      {'icon': Icons.school, 'color': Colors.blue, 'name': 'Education'},
      {'icon': Icons.work, 'color': Colors.orange, 'name': 'Work'},
      {'icon': Icons.nightlight_round, 'color': Colors.yellow, 'name': 'Sleep'},
      {'icon': Icons.fitness_center, 'color': Colors.green, 'name': 'Exercise'},
      {'icon': Icons.book, 'color': Colors.purple, 'name': 'Reading'},
      {'icon': Icons.family_restroom, 'color': Colors.pink, 'name': 'Family'},
      {'icon': Icons.movie, 'color': Colors.red, 'name': 'Movie'},
      {'icon': Icons.restaurant, 'color': Colors.amber, 'name': 'Dining'},
      {'icon': Icons.sports_esports, 'color': Colors.indigo, 'name': 'Gaming'},
      {'icon': Icons.sports_esports, 'color': Colors.indigo, 'name': 'Gaming'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Select Icon',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final iconData = icons[index];
              return InkWell(
                onTap: () {
                  scheduleController.setSelectedIcon(
                    iconData['icon'],
                    iconData['color'],
                  );
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconData['color'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconData['icon'],
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      iconData['name'],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
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
        ],
      ),
    );
  }

  void _showAppSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Select Apps to Block',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              // Search field
              TextField(
                onChanged: scheduleController.searchApps,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: AppColors.borderColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.buttonPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selected count
              Obx(() => Text(
                    '${scheduleController.selectedAppIds.length} apps selected',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  )),
              const SizedBox(height: 8),

              // Apps list
              Expanded(
                child: Obx(() => ListView.builder(
                      itemCount: scheduleController.filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = scheduleController.filteredApps[index];
                        final isSelected =
                            scheduleController.isAppSelected(app.id);

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: app.iconColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              app.icon,
                              color: app.iconColor,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            app.name,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            app.packageName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.buttonPrimary,
                                )
                              : const Icon(
                                  Icons.circle_outlined,
                                  color: AppColors.textSecondary,
                                ),
                          onTap: () {
                            scheduleController.toggleAppSelection(app.id);
                          },
                        );
                      },
                    )),
              ),
            ],
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
            ),
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
