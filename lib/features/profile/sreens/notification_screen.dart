import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';
import '../controllers/profile_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.find<ProfileController>();

    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            _buildAppBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // General Notifications Section
                    _buildSectionCard(
                      title: 'General Notifications',
                      subtitle: 'Basic notification settings',
                      icon: Icons.notifications_outlined,
                      children: [
                        Obx(() => NotificationToggleItem(
                              title: 'Show blocked applications',
                              subtitle:
                                  'Lists all currently blocked applications in a notification.',
                              value: profileController.showBlockedApps.value,
                              onChanged: (value) =>
                                  profileController.toggleShowBlockedApps(),
                            )),
                        Obx(() => NotificationToggleItem(
                              title: 'New Usage report',
                              subtitle:
                                  'Receive a notification when a new usage report is ready',
                              value: profileController.newUsageReport.value,
                              onChanged: (value) =>
                                  profileController.toggleNewUsageReport(),
                            )),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Schedule Notifications Section
                    _buildSectionCard(
                      title: 'Schedule Notifications',
                      subtitle: 'Notifications for scheduled blocking',
                      icon: Icons.schedule_outlined,
                      children: [
                        Obx(() => NotificationToggleItem(
                              title: 'Before start',
                              subtitle:
                                  'Show a notification before a scheduled time becomes active.',
                              value:
                                  profileController.scheduleBeforeStart.value,
                              onChanged: (value) =>
                                  profileController.toggleScheduleBeforeStart(),
                            )),
                        Obx(() => NotificationToggleItem(
                              title: 'After end',
                              subtitle:
                                  'Show notification when a schedule stops being active.',
                              value: profileController.scheduleAfterEnd.value,
                              onChanged: (value) =>
                                  profileController.toggleScheduleAfterEnd(),
                            )),
                        Obx(() => NotificationToggleItem(
                              title: 'Show block notifications',
                              subtitle:
                                  'Display notifications when apps are blocked during scheduled time.',
                              value: profileController
                                  .showBlockNotifications.value,
                              onChanged: (value) => profileController
                                  .toggleShowBlockNotifications(),
                            )),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Quick Mode Section
                    _buildSectionCard(
                      title: 'Quick Mode',
                      subtitle: 'Instant blocking notifications',
                      icon: Icons.flash_on_outlined,
                      children: [
                        Obx(() => NotificationToggleItem(
                              title: 'After end',
                              subtitle:
                                  'Show notification when quick mode session ends.',
                              value: profileController.quickModeAfterEnd.value,
                              onChanged: (value) =>
                                  profileController.toggleQuickModeAfterEnd(),
                            )),
                        Obx(() => NotificationToggleItem(
                              title: 'Show block notifications',
                              subtitle:
                                  'Display notifications when apps are blocked in quick mode.',
                              value: profileController.quickModeShowBlock.value,
                              onChanged: (value) =>
                                  profileController.toggleQuickModeShowBlock(),
                            )),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Activity Section
                    _buildSectionCard(
                      title: 'Activity Notifications',
                      subtitle: 'Daily activity and usage alerts',
                      icon: Icons.trending_up_outlined,
                      children: [
                        Obx(() => NotificationToggleItem(
                              title: 'Show activity notifications',
                              subtitle:
                                  'Show alerts for daily activities and usage milestones.',
                              value: profileController
                                  .showActivityNotifications.value,
                              onChanged: (value) => profileController
                                  .toggleShowActivityNotifications(),
                            )),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Notification Settings Info Card
                    _buildInfoCard(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.containerBackground,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.iconPrimary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notification Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Notification test button
          IconButton(
            onPressed: () => _showTestNotification(),
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.buttonPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: AppColors.buttonPrimary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.buttonPrimary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
              ],
            ),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 1,
            color: AppColors.borderColor.withOpacity(0.3),
          ),

          // Settings Items
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.buttonPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.buttonPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.buttonPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.buttonPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Notifications',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'These settings control when and how you receive notifications. Make sure to allow notifications in your device settings.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTestNotification() {
    Get.snackbar(
      'Test Notification',
      'This is how your notifications will appear',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.containerBackground,
      colorText: AppColors.textPrimary,
      icon: const Icon(
        Icons.notifications_active,
        color: AppColors.buttonPrimary,
      ),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

class NotificationToggleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NotificationToggleItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Custom Switch
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: value
                    ? AppColors.buttonPrimary
                    : AppColors.containerBackground,
                border: Border.all(
                  color:
                      value ? AppColors.buttonPrimary : AppColors.borderColor,
                  width: 2,
                ),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: AppColors.buttonPrimary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: value
                      ? const Icon(
                          Icons.check,
                          color: AppColors.buttonPrimary,
                          size: 14,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
