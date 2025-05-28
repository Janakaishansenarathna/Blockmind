// presentation/screens/home/timer_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';
import '../controllers/quick_mood_controller.dart';

class TimerSelectionScreen extends StatefulWidget {
  final QuickModeController quickModeController;

  const TimerSelectionScreen({
    super.key,
    required this.quickModeController,
  });

  @override
  State<TimerSelectionScreen> createState() => _TimerSelectionScreenState();
}

class _TimerSelectionScreenState extends State<TimerSelectionScreen> {
  late int selectedHours;
  late int selectedMinutes;
  late double sliderValue;

  // Quick duration presets in minutes
  final List<int> quickDurations = [15, 30, 60, 120, 240, 480];
  final List<String> quickLabels = ['15m', '30m', '1h', '2h', '4h', '8h'];

  @override
  void initState() {
    super.initState();

    // Initialize from QuickModeController's selected duration
    final currentDurationMinutes =
        widget.quickModeController.selectedDurationMinutes.value;
    selectedHours = currentDurationMinutes ~/ 60;
    selectedMinutes = currentDurationMinutes % 60;
    sliderValue = currentDurationMinutes.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Current time display
            _buildCurrentTimeDisplay(),

            // Time picker wheels
            Expanded(
              child: _buildTimePicker(),
            ),

            // Quick duration buttons
            _buildQuickDurationButtons(),

            // Slider control
            _buildSliderControl(),

            // Bottom action bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.iconPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Block Duration',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Choose how long to block your apps',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _resetToDefault,
            icon: const Icon(
              Icons.refresh,
              color: AppColors.iconSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer,
                color: AppColors.buttonPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _formatDuration(
                    Duration(hours: selectedHours, minutes: selectedMinutes)),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Block Duration',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Show selected apps count
          const SizedBox(height: 12),
          Obx(() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.buttonPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.buttonPrimary.withOpacity(0.2)),
                ),
                child: Text(
                  widget.quickModeController.selectedAppsCountText,
                  style: const TextStyle(
                    color: AppColors.buttonPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Time',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Time picker wheels
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Hours picker
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Hours',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 40,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedHours,
                          ),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedHours = index;
                              _updateSliderValue();
                            });
                          },
                          children: List.generate(25, (index) {
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                // Separator
                Container(
                  height: 40,
                  width: 2,
                  color: AppColors.borderColor.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),

                // Minutes picker
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Minutes',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 40,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedMinutes ~/ 5,
                          ),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedMinutes = index * 5;
                              _updateSliderValue();
                            });
                          },
                          children: List.generate(12, (index) {
                            final minutes = index * 5;
                            return Center(
                              child: Text(
                                minutes.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Manual adjustment buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAdjustmentButton(
                  icon: Icons.remove,
                  label: '-15m',
                  onTap: () => _adjustTime(-15),
                ),
                _buildAdjustmentButton(
                  icon: Icons.add,
                  label: '+15m',
                  onTap: () => _adjustTime(15),
                ),
                _buildAdjustmentButton(
                  icon: Icons.remove,
                  label: '-1h',
                  onTap: () => _adjustTime(-60),
                ),
                _buildAdjustmentButton(
                  icon: Icons.add,
                  label: '+1h',
                  onTap: () => _adjustTime(60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.iconSecondary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDurationButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Select',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: quickDurations.length,
              itemBuilder: (context, index) {
                final duration = quickDurations[index];
                final label = quickLabels[index];
                final isSelected = _getCurrentTotalMinutes() == duration;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _setQuickDuration(duration),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.buttonPrimary
                            : AppColors.containerBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.buttonPrimary
                              : AppColors.borderColor.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fine Adjustment',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${sliderValue.round()} minutes',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.buttonPrimary,
              inactiveTrackColor: AppColors.borderColor.withOpacity(0.3),
              thumbColor: AppColors.buttonPrimary,
              overlayColor: AppColors.buttonPrimary.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: sliderValue,
              min: 5,
              max: 480, // 8 hours
              divisions: 95, // 5-minute increments
              onChanged: (value) {
                setState(() {
                  sliderValue = value;
                  _updateFromSlider();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5m',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                '8h',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Preview info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Duration Preview',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(Duration(
                        hours: selectedHours, minutes: selectedMinutes)),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ends at ${_getEndTime()}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Action buttons
            Row(
              children: [
                // Cancel button
                Container(
                  width: 80,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Save button
                Container(
                  width: 100,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.buttonPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _saveAndGoBack,
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Text(
                          'Set Timer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  void _updateSliderValue() {
    sliderValue = (selectedHours * 60 + selectedMinutes).toDouble();
  }

  void _updateFromSlider() {
    final totalMinutes = sliderValue.round();
    selectedHours = totalMinutes ~/ 60;
    selectedMinutes = totalMinutes % 60;
  }

  void _adjustTime(int minutesToAdd) {
    final totalMinutes =
        (selectedHours * 60 + selectedMinutes + minutesToAdd).clamp(5, 480);
    setState(() {
      selectedHours = totalMinutes ~/ 60;
      selectedMinutes = totalMinutes % 60;
      sliderValue = totalMinutes.toDouble();
    });
  }

  void _setQuickDuration(int minutes) {
    setState(() {
      selectedHours = minutes ~/ 60;
      selectedMinutes = minutes % 60;
      sliderValue = minutes.toDouble();
    });
  }

  void _resetToDefault() {
    setState(() {
      selectedHours = 1;
      selectedMinutes = 0;
      sliderValue = 60;
    });
  }

  int _getCurrentTotalMinutes() {
    return selectedHours * 60 + selectedMinutes;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getEndTime() {
    final now = DateTime.now();
    final endTime =
        now.add(Duration(hours: selectedHours, minutes: selectedMinutes));
    final hour = endTime.hour;
    final minute = endTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  void _saveAndGoBack() {
    final totalMinutes = _getCurrentTotalMinutes();

    // Update the QuickModeController
    widget.quickModeController.setDuration(totalMinutes);

    Get.back();

    Get.snackbar(
      'Timer Set',
      'Block duration set to ${_formatDuration(Duration(minutes: totalMinutes))}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
