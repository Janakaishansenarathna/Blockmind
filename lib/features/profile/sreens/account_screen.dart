import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';
import '../controllers/profile_controller.dart';
import 'dart:io';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.find<ProfileController>();

    return GradientScaffold(
      child: SafeArea(
        child: Form(
          key: profileController.profileFormKey,
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(context),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),

                          // Profile Avatar Section
                          _buildProfileAvatar(profileController),

                          const SizedBox(height: 40),

                          // Form Fields
                          _buildFormFields(profileController),

                          const SizedBox(height: 32),

                          // Account Information Card
                          _buildAccountInfoCard(profileController),

                          const SizedBox(height: 40),

                          // Save Button
                          _buildSaveButton(profileController),

                          const SizedBox(height: 40),

                          // Account Actions
                          _buildAccountActions(profileController),

                          const SizedBox(height: 32),
                        ],
                      )),
                ),
              ),
            ],
          ),
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
          const Text(
            'Account Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(ProfileController profileController) {
    return Obx(() => GestureDetector(
          onTap: profileController.isLoading.value
              ? null
              : () => profileController.updateProfilePicture(),
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: profileController.currentUser.value?.photoUrl != null &&
                        profileController
                            .currentUser.value!.photoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: profileController.currentUser.value!.photoUrl!
                                .startsWith('http')
                            ? Image.network(
                                profileController.currentUser.value!.photoUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      profileController.getUserInitials(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(profileController
                                    .currentUser.value!.photoUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      profileController.getUserInitials(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      )
                    : Center(
                        child: Text(
                          profileController.getUserInitials(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),

              // Edit Button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.buttonPrimary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Loading Overlay
              if (profileController.isLoading.value)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
            ],
          ),
        ));
  }

  Widget _buildFormFields(ProfileController profileController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name Field with reactive updates
        Obx(() {
          // Update the controller when user data changes
          if (profileController.currentUser.value != null &&
              profileController.nameController.text !=
                  profileController.currentUser.value!.name) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              profileController.nameController.text =
                  profileController.currentUser.value!.name;
            });
          }

          return _buildInputField(
            label: 'Full Name',
            controller: profileController.nameController,
            validator: profileController.validateName,
            icon: Icons.person_outline,
            hint: 'Enter your full name',
            key: ValueKey(
                'name_field_${profileController.currentUser.value?.name}'),
          );
        }),

        const SizedBox(height: 24),

        // Email Field (Read-only) with reactive updates
        Obx(() => _buildReadOnlyField(
              label: 'Email Address',
              value: profileController.currentUser.value?.email ?? 'Loading...',
              icon: Icons.email_outlined,
              isLocked: true,
            )),

        const SizedBox(height: 24),

        // Phone Field (Optional)
        _buildInputField(
          label: 'Phone Number (Optional)',
          controller: TextEditingController(), // Add phone controller if needed
          icon: Icons.phone_outlined,
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    Key? key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.containerBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: AppColors.iconSecondary,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    bool isLocked = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.containerBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.iconSecondary,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isLocked)
                Icon(
                  Icons.lock_outline,
                  color: AppColors.textMuted,
                  size: 18,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfoCard(ProfileController profileController) {
    return Obx(() => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.buttonPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.buttonPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                'User Name',
                profileController.currentUser.value?.name ?? 'Loading...',
                Icons.person_outline,
              ),
              _buildInfoRow(
                'Member Since',
                profileController.currentUser.value?.createdAt != null
                    ? _formatDate(
                        profileController.currentUser.value!.createdAt)
                    : 'Loading...',
                Icons.calendar_today_outlined,
              ),
              _buildInfoRow(
                'Account Type',
                profileController.isPremiumUser ? 'Premium' : 'Free',
                Icons.workspace_premium_outlined,
                valueColor: profileController.isPremiumUser
                    ? AppColors.success
                    : AppColors.textPrimary,
              ),
              // _buildInfoRow(
              //   'Last Login',
              //   // profileController.currentUser.value?.lastLoginAt != null
              //   //     ? _formatDate(
              //   //         profileController.currentUser.value)
              //   //     : 'Loading...',
              //   Icons.login_outlined,
              // ),
              if (profileController.isPremiumUser)
                _buildInfoRow(
                  'Premium Expires',
                  '${profileController.premiumDaysLeft} days left',
                  Icons.timer_outlined,
                  valueColor: profileController.premiumDaysLeft < 7
                      ? AppColors.warning
                      : AppColors.success,
                ),
            ],
          ),
        ));
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.iconSecondary,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ProfileController profileController) {
    return Obx(() {
      // Check if there are changes to save
      final hasChanges = profileController.currentUser.value != null &&
          profileController.nameController.text.trim() !=
              profileController.currentUser.value!.name;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: profileController.isLoading.value
              ? LinearGradient(
                  colors: [
                    AppColors.buttonPrimary.withOpacity(0.5),
                    AppColors.buttonPrimary.withOpacity(0.5),
                  ],
                )
              : hasChanges
                  ? AppColors.primaryGradient
                  : LinearGradient(
                      colors: [
                        AppColors.buttonPrimary.withOpacity(0.3),
                        AppColors.buttonPrimary.withOpacity(0.3),
                      ],
                    ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: profileController.isLoading.value || !hasChanges
              ? null
              : [
                  BoxShadow(
                    color: AppColors.buttonPrimary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: profileController.isLoading.value || !hasChanges
                ? null
                : () async {
                    final success = await profileController.updateProfile();
                    if (success) {
                      // Force UI refresh
                      profileController.currentUser.refresh();
                    }
                  },
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: profileController.isLoading.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasChanges
                              ? Icons.save_outlined
                              : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          hasChanges ? 'Save Changes' : 'No Changes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAccountActions(ProfileController profileController) {
    return Column(
      children: [
        // Sign Out Button
        _buildActionButton(
          title: 'Sign Out',
          subtitle: 'Sign out from your account',
          icon: Icons.logout_outlined,
          onTap: () => profileController.signOut(),
          iconColor: AppColors.warning,
        ),

        const SizedBox(height: 16),

        // Delete Account Button
        _buildActionButton(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          icon: Icons.delete_outline,
          onTap: () => profileController.deleteAccount(),
          iconColor: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
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
                        style: TextStyle(
                          color: iconColor,
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
                Icon(
                  Icons.chevron_right,
                  color: AppColors.iconSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
