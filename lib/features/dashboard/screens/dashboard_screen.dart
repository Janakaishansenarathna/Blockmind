// presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';

import '../controllers/dashboard_controller.dart';

import '../controllers/quick_mood_controller.dart';
import '../widgets/active_blocks_list.dart';
import '../widgets/time_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get controllers
    final HomeController homeController = Get.put(HomeController());
    final QuickModeController quickModeController =
        Get.put(QuickModeController());

    // Set available apps in quick mode controller when home controller loads apps
    ever(homeController.allApps, (apps) {
      quickModeController.setAvailableApps(apps);
    });

    return GradientScaffold(
      child: SafeArea(
        child: Obx(() {
          // Show initialization screen if not ready
          if (!homeController.isInitialized.value) {
            return _buildInitializationScreen(homeController);
          }

          // Show main content when ready
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                homeController.refreshData(),
                quickModeController.refreshQuickModeData(),
              ]);
            },
            color: AppColors.buttonPrimary,
            backgroundColor: AppColors.containerBackground,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(homeController),
                  const SizedBox(height: 24),

                  // Quick Mode Section
                  _buildQuickModeSection(homeController, quickModeController),
                  const SizedBox(height: 24),

                  // My Schedules Section
                  _buildSchedulesSection(homeController),
                  const SizedBox(height: 24),

                  // Your Progress Section
                  _buildProgressSection(homeController),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInitializationScreen(HomeController homeController) {
    return Obx(() => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.containerBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (homeController.isInitializing.value)
                  const CircularProgressIndicator(
                    color: AppColors.buttonPrimary,
                  )
                else
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                const SizedBox(height: 16),
                Text(
                  homeController.isInitializing.value
                      ? 'Initializing...'
                      : 'Initialization Failed',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  homeController.isInitializing.value
                      ? 'Setting up your focus environment...'
                      : homeController.errorMessage.value.isNotEmpty
                          ? homeController.errorMessage.value
                          : 'Please try again',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!homeController.isInitializing.value) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => homeController.refreshData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ));
  }

  Widget _buildHeader(HomeController homeController) {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hello, ${homeController.currentLoggedUsername}!',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Get.snackbar(
                      'Notifications',
                      'You have ${homeController.notificationCount.value} new notifications',
                      snackPosition: SnackPosition.TOP,
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.iconPrimary,
                    size: 28,
                  ),
                ),
                if (homeController.notificationCount.value > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${homeController.notificationCount.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ));
  }

  Widget _buildQuickModeSection(
      HomeController homeController, QuickModeController quickModeController) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Mode',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.iconSecondary,
                ),
                onSelected: (value) =>
                    _handleQuickModeAction(value, quickModeController),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('Reset Quick Mode',
                            style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'presets',
                    child: Row(
                      children: [
                        Icon(Icons.bookmark, size: 18),
                        SizedBox(width: 12),
                        Text('Quick Presets'),
                      ],
                    ),
                  ),
                  if (quickModeController.isQuickModeActive.value) ...[
                    const PopupMenuItem(
                      value: 'extend',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, size: 18),
                          SizedBox(width: 12),
                          Text('Extend Time'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: quickModeController.isPaused.value
                          ? 'resume'
                          : 'pause',
                      child: Row(
                        children: [
                          Icon(
                            quickModeController.isPaused.value
                                ? Icons.play_arrow
                                : Icons.pause,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(quickModeController.isPaused.value
                              ? 'Resume'
                              : 'Pause'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content based on Quick Mode state
          Obx(() {
            if (quickModeController.selectedApps.isEmpty) {
              return _buildAddAppsState(quickModeController);
            } else if (!quickModeController.isQuickModeActive.value) {
              return _buildReadyToStartState(quickModeController);
            } else {
              return _buildActiveBlockingState(quickModeController);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildAddAppsState(QuickModeController quickModeController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Something to block. Tap the Add button to select distracting apps',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActionButton(
          quickModeController,
          icon: Icons.add,
          label: '+ Add',
          onPressed: () => _showBlocklistScreen(),
          color: AppColors.buttonPrimary,
        ),
      ],
    );
  }

  Widget _buildReadyToStartState(QuickModeController quickModeController) {
    return Column(
      children: [
        // Selected apps preview
        Obx(() {
          if (quickModeController.selectedApps.isNotEmpty) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Apps:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: quickModeController.selectedApps
                            .take(5)
                            .map(
                              (app) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: app.iconColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: app.iconColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(app.icon,
                                        size: 16, color: app.iconColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      app.name,
                                      style: TextStyle(
                                        color: app.iconColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      if (quickModeController.selectedApps.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+${quickModeController.selectedApps.length - 5} more apps',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }
          return const SizedBox.shrink();
        }),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: Obx(() => _buildQuickActionButton(
                    quickModeController,
                    icon: Icons.play_arrow,
                    label: quickModeController.quickModeButtonText,
                    onPressed: quickModeController.canStartQuickMode
                        ? () => quickModeController.startQuickMode()
                        : null,
                    color: AppColors.buttonPrimary,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                quickModeController,
                icon: Icons.access_time,
                label: 'Set Timer',
                onPressed: () => _showTimerScreen(quickModeController),
                color: AppColors.containerBackground,
                textColor: AppColors.textPrimary,
                borderColor: AppColors.borderColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveBlockingState(QuickModeController quickModeController) {
    return Column(
      children: [
        // Stop button
        _buildQuickActionButton(
          quickModeController,
          icon: Icons.stop,
          label:
              quickModeController.isPaused.value ? 'Resume' : 'Stop Blocking',
          onPressed: () {
            if (quickModeController.isPaused.value) {
              quickModeController.resumeQuickMode();
            } else {
              _showStopConfirmation(quickModeController);
            }
          },
          color: quickModeController.isPaused.value
              ? AppColors.buttonPrimary
              : AppColors.error,
        ),
        const SizedBox(height: 16),

        // Blocking info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: quickModeController.isPaused.value
                ? Colors.orange.withOpacity(0.1)
                : AppColors.buttonPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: quickModeController.isPaused.value
                  ? Colors.orange.withOpacity(0.2)
                  : AppColors.buttonPrimary.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                quickModeController.isPaused.value ? Icons.pause : Icons.shield,
                color: quickModeController.isPaused.value
                    ? Colors.orange
                    : AppColors.buttonPrimary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Obx(() => Text(
                    quickModeController.selectedAppsCountText,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  )),
              const SizedBox(height: 8),
              Obx(() => Text(
                    quickModeController.remainingTimeText.isNotEmpty
                        ? quickModeController.remainingTimeText
                        : 'Active blocking session',
                    style: TextStyle(
                      color: quickModeController.isPaused.value
                          ? Colors.orange
                          : AppColors.buttonPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    QuickModeController quickModeController, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    Color? textColor,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: onPressed != null ? color : color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: textColor ?? Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchedulesSection(HomeController homeController) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Schedules',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                _showAddScheduleDialog();
              },
              icon: const Icon(
                Icons.add,
                color: AppColors.buttonPrimary,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Schedule items - Use userSchedules instead of schedules
        Obx(() => SizedBox(
              height: 100,
              child: homeController.userSchedules.isEmpty
                  ? Center(
                      child: Text(
                        'No schedules yet\nTap + to add one',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: homeController.userSchedules.length,
                      itemBuilder: (context, index) {
                        final schedule = homeController.userSchedules[index];
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: schedule.iconColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: schedule.iconColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    schedule.icon,
                                    color: schedule.iconColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                schedule.title,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            )),
      ],
    );
  }

  Widget _buildProgressSection(HomeController homeController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Progress',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Saved time progress
        Obx(() => _buildProgressCard(
              label: homeController.savedTimeText,
              value: homeController.progressPercentage.value,
              color: AppColors.success,
              icon: Icons.check_circle,
              isCompleted: true,
            )),

        const SizedBox(height: 16),

        // Unblock count progress
        Obx(() => _buildProgressCard(
              label: homeController.unblockText,
              value: homeController.uncompletedPercentage.value,
              color: AppColors.error,
              icon: Icons.cancel,
              isCompleted: false,
            )),
      ],
    );
  }

  Widget _buildProgressCard({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    required bool isCompleted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.borderColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            isCompleted ? 'Completed' : 'Uncompleted',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Action handlers
  void _handleQuickModeAction(
      String action, QuickModeController quickModeController) {
    switch (action) {
      case 'reset':
        _showResetQuickModeConfirmation(quickModeController);
        break;
      case 'presets':
        _showQuickPresets(quickModeController);
        break;
      case 'extend':
        _showExtendDialog(quickModeController);
        break;
      case 'pause':
        quickModeController.pauseQuickMode();
        break;
      case 'resume':
        quickModeController.resumeQuickMode();
        break;
    }
  }

  void _showResetQuickModeConfirmation(
      QuickModeController quickModeController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Quick Mode'),
        content: const Text(
          'Are you sure you want to reset Quick Mode? This will:\n\n'
          '• Stop current session if active\n'
          '• Clear selected apps\n'
          '• Reset quick mood\n'
          '• Clear session data\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _resetQuickMode(quickModeController);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetQuickMode(QuickModeController quickModeController) async {
    try {
      // Stop current session if active
      if (quickModeController.isQuickModeActive.value) {
        await quickModeController.stopQuickMode();
      }

      // Clear selected apps
      quickModeController.clearSelectedApps();

      // Reset quick mood
      await quickModeController.resetQuickMood();

      Get.snackbar(
        'Quick Mode Reset',
        'All Quick Mode data has been reset',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Reset Failed',
        'Failed to reset Quick Mode: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _showExtendDialog(QuickModeController quickModeController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Extend Session'),
        content: const Text('How many minutes would you like to add?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              quickModeController.extendQuickMode(15);
            },
            child: const Text('+15 min'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              quickModeController.extendQuickMode(30);
            },
            child: const Text('+30 min'),
          ),
        ],
      ),
    );
  }

  void _showStopConfirmation(QuickModeController quickModeController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Stop Quick Mode'),
        content: const Text(
            'Are you sure you want to stop the current blocking session?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              quickModeController.stopQuickMode();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  void _showQuickPresets(QuickModeController quickModeController) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.containerBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Presets',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...quickModeController.getQuickModePresets().map(
                  (preset) => _buildPresetOption(preset, quickModeController),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetOption(preset, QuickModeController quickModeController) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.back();
          quickModeController.applyQuickModePreset(preset);
          Get.snackbar(
            'Preset Applied',
            '${preset.name} apps selected',
            backgroundColor: AppColors.success,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: preset.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(preset.icon, color: preset.color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      preset.description,
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
        ),
      ),
    );
  }

  void _showBlocklistScreen() {
    Get.to(
      () => const BlocklistScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _showTimerScreen(QuickModeController quickModeController) {
    Get.to(
      () => TimerSelectionScreen(quickModeController: quickModeController),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _showAddScheduleDialog() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.containerBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add schedule restriction',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.iconSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildScheduleOption(
              icon: Icons.access_time,
              title: 'Add your weekly schedule',
              subtitle: 'Set time intervals when apps should be blocked',
              onTap: () {
                Get.back();
                Get.snackbar(
                    'Coming Soon', 'Weekly schedule feature coming soon!');
              },
            ),
            const SizedBox(height: 16),
            _buildScheduleOption(
              icon: Icons.hourglass_bottom,
              title: 'Set usage limit',
              subtitle: 'Limit total usage of selected apps',
              onTap: () {
                Get.back();
                Get.snackbar('Coming Soon', 'Usage limit feature coming soon!');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.buttonPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.buttonPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.iconSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
