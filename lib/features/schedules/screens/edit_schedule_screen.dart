// features/schedule/screens/create_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';
import '../controllers/schedule_controller.dart';
import '../widgets/app_selection_dialog.dart';
import '../widgets/icon_selection_dialog.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final ScheduleController scheduleController = Get.find<ScheduleController>();

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
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
            onPressed: () {
              scheduleController.resetForm();
              Get.back();
            },
          ),
        ),
        body: SingleChildScrollView(
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
        ),
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
            onPressed: scheduleController.isLoading.value
                ? null
                : () async {
                    final success = scheduleController.isEditMode.value
                        ? await scheduleController.updateSchedule()
                        : await scheduleController.createSchedule();

                    if (success) {
                      Get.back();
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
            child: scheduleController.isLoading.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    scheduleController.isEditMode.value ? 'Update' : 'Create',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
    showDialog(
      context: context,
      builder: (context) => IconSelectionDialog(
        onIconSelected: (icon, color) {
          scheduleController.setSelectedIcon(icon, color);
        },
      ),
    );
  }

  void _showAppSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AppSelectionDialog(
        controller: scheduleController,
      ),
    );
  }
}
