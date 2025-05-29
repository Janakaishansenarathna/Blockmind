import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';
import '../controllers/profile_controller.dart';
import 'about_screen.dart';
import 'account_screen.dart';
import 'additional_pages.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.put(ProfileController());

    return GradientScaffold(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => profileController.refreshProfile(),
          color: AppColors.buttonPrimary,
          backgroundColor: AppColors.containerBackground,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      // Profile Avatar with Loading State
                      Obx(() => GestureDetector(
                            onTap: profileController.isLoading.value
                                ? null
                                : () =>
                                    profileController.updateProfilePicture(),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF9C27B0),
                                    Color(0xFFE91E63)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Avatar Content
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: profileController.currentUser.value
                                                    ?.photoUrl !=
                                                null &&
                                            profileController.currentUser.value!
                                                .photoUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            child: Image.network(
                                              profileController
                                                  .currentUser.value!.photoUrl!,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Center(
                                                  child: Text(
                                                    profileController
                                                        .getUserInitials(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 36,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              profileController
                                                  .getUserInitials(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  ),
                                  // Camera Icon
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.buttonPrimary,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),

                      const SizedBox(height: 20),

                      // User Info with Loading State
                      Obx(() => Column(
                            children: [
                              if (profileController.isLoading.value)
                                Container(
                                  width: 120,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.containerBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                )
                              else
                                Text(
                                  profileController.currentUser.value?.name ??
                                      'User',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 8),
                              if (profileController.isLoading.value)
                                Container(
                                  width: 160,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.containerBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                )
                              else
                                Text(
                                  profileController.currentUser.value?.email ??
                                      'user@example.com',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          )),

                      const SizedBox(height: 10)
                    ],
                  ),
                ),
              ),

              // Menu Section
              SliverToBoxAdapter(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Your Account Section
                      _buildSectionHeader('Your account'),
                      const SizedBox(height: 16),

                      _buildMenuCard([
                        ProfileMenuItem(
                          icon: Icons.person_outline,
                          title: 'Account',
                          subtitle: 'Manage your profile information',
                          onTap: () => Get.to(
                            () => const AccountScreen(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // App Settings Section
                      _buildSectionHeader('App blocking Settings'),
                      const SizedBox(height: 16),

                      _buildMenuCard([
                        ProfileMenuItem(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Configure notification preferences',
                          onTap: () => Get.to(
                            () => const NotificationsScreen(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                        ProfileMenuItem(
                          icon: Icons.access_time_outlined,
                          title: 'Time Management',
                          subtitle: 'Set up usage time limits',
                          onTap: () => Get.to(
                            () => const TimeManagementScreen(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                        ProfileMenuItem(
                          icon: Icons.language_outlined,
                          title: 'Language',
                          subtitle: 'Change app language',
                          onTap: () => Get.to(
                            () => const LanguageScreen(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                        ProfileMenuItem(
                          icon: Icons.palette_outlined,
                          title: 'Theme',
                          subtitle: 'Customize app appearance',
                          onTap: () => Get.to(
                            () => const ThemeScreen(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // Support Section
                      _buildSectionHeader('More info and support'),
                      const SizedBox(height: 16),

                      _buildMenuCard([
                        ProfileMenuItem(
                          icon: Icons.help_outline,
                          title: 'Help and FAQ',
                          subtitle: 'Get help and find answers',
                          onTap: () => Get.to(
                            () => const HelpScreen(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                        ProfileMenuItem(
                          icon: Icons.backup_outlined,
                          title: 'Backup',
                          subtitle: 'Backup and restore data',
                          onTap: () => Get.to(
                            () => const BackupScreen(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                        ProfileMenuItem(
                          icon: Icons.info_outline,
                          title: 'About',
                          subtitle: 'App information and version',
                          onTap: () => Get.to(
                            () => const AboutScreen(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                        ProfileMenuItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy',
                          subtitle: 'Privacy policy and settings',
                          onTap: () => Get.to(
                            () => const PrivacyScreen(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.schedule,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.buttonPrimary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// Enhanced Profile Menu Item
class ProfileMenuItem extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;
  final Color? iconColor;

  const ProfileMenuItem({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showChevron = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        (iconColor ?? AppColors.buttonPrimary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.buttonPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
              ],
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
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.iconSecondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
