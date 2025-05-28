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
    // Use Get.put to ensure controller is initialized
    final ProfileController profileController = Get.put(ProfileController());

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
                child: Form(
                  key: profileController.profileFormKey,
                  child: Column(
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

                      // Action Buttons Row
                      _buildActionButtons(profileController),

                      const SizedBox(height: 40),

                      // Account Actions
                      _buildAccountActions(profileController),

                      const SizedBox(height: 32),
                    ],
                  ),
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
          onTap: profileController.isUpdatingPhoto.value
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
                child: _buildAvatarContent(profileController),
              ),

              // Edit Button
              Positioned(
                bottom: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: profileController.isUpdatingPhoto.value
                        ? LinearGradient(
                            colors: [
                              AppColors.buttonPrimary.withOpacity(0.5),
                              AppColors.buttonPrimary.withOpacity(0.5),
                            ],
                          )
                        : AppColors.primaryGradient,
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
                  child: profileController.isUpdatingPhoto.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),

              // Loading Overlay
              if (profileController.isUpdatingPhoto.value)
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

  Widget _buildAvatarContent(ProfileController profileController) {
    return Obx(() {
      final user = profileController.currentUser.value;
      final photoUrl = user?.photoUrl;

      if (photoUrl != null && photoUrl.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: _buildImageWidget(photoUrl, profileController),
        );
      }

      return _buildInitialsAvatar(profileController);
    });
  }

  Widget _buildImageWidget(
      String photoUrl, ProfileController profileController) {
    if (photoUrl.startsWith('http')) {
      // Network image
      return Image.network(
        photoUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
              strokeWidth: 3,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Network image error: $error');
          return _buildInitialsAvatar(profileController);
        },
      );
    } else {
      // Local file image
      return FutureBuilder<bool>(
        future: File(photoUrl).exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            );
          }

          if (snapshot.data == true) {
            return Image.file(
              File(photoUrl),
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Local image error: $error');
                return _buildInitialsAvatar(profileController);
              },
            );
          } else {
            print('Local image file does not exist: $photoUrl');
            return _buildInitialsAvatar(profileController);
          }
        },
      );
    }
  }

  Widget _buildInitialsAvatar(ProfileController profileController) {
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
  }

  Widget _buildFormFields(ProfileController profileController) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name Field - FIXED
          _buildInputField(
            label: 'Full Name',
            controller: profileController.nameController,
            validator: profileController.validateName,
            icon: Icons.person_outline,
            hint: 'Enter your full name',
            isLoading: profileController.isLoading.value,
          ),

          const SizedBox(height: 24),

          // Email Field (Read-only)
          _buildReadOnlyField(
            label: 'Email Address',
            value: profileController.currentUser.value?.email ?? 'Loading...',
            icon: Icons.email_outlined,
            isLocked: true,
          ),

          const SizedBox(height: 24),

          // Phone Field - FIXED with validation
          _buildInputField(
            label: 'Phone Number (Optional)',
            controller: profileController.phoneController,
            validator: profileController.validatePhone,
            icon: Icons.phone_outlined,
            hint: 'Enter your phone number',
            keyboardType: TextInputType.phone,
            isLoading: profileController.isLoading.value,
          ),
        ],
      );
    });
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool isLoading = false,
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
          decoration: BoxDecoration(
            color: isLoading
                ? AppColors.containerBackground.withOpacity(0.7)
                : AppColors.containerBackground,
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
            enabled: !isLoading,
            style: TextStyle(
              color: isLoading
                  ? AppColors.textPrimary.withOpacity(0.7)
                  : AppColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isLoading
                    ? AppColors.iconSecondary.withOpacity(0.5)
                    : AppColors.iconSecondary,
                size: 20,
              ),
              suffixIcon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.iconSecondary,
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: isLoading
                    ? AppColors.textMuted.withOpacity(0.5)
                    : AppColors.textMuted,
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
                const Icon(
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
    return Obx(() {
      final user = profileController.currentUser.value;

      return Container(
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
              user?.name ?? 'Loading...',
              Icons.person_outline,
            ),
            _buildInfoRow(
              'Member Since',
              user?.createdAt != null
                  ? _formatDate(user!.createdAt)
                  : 'Loading...',
              Icons.calendar_today_outlined,
            ),
            _buildInfoRow(
              'Account Type',
              profileController.isPremiumUser.value ? 'Premium' : 'Free',
              Icons.workspace_premium_outlined,
              valueColor: profileController.isPremiumUser.value
                  ? AppColors.success
                  : AppColors.textPrimary,
            ),
            if (profileController.isPremiumUser.value)
              _buildInfoRow(
                'Premium Expires',
                '${profileController.premiumDaysLeft.value} days left',
                Icons.timer_outlined,
                valueColor: profileController.premiumDaysLeft.value < 7
                    ? AppColors.warning
                    : AppColors.success,
              ),
            _buildInfoRow(
              'Last Updated',
              user?.updatedAt != null ? _formatDate(user!.updatedAt) : 'Never',
              Icons.update_outlined,
            ),
          ],
        ),
      );
    });
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

  Widget _buildActionButtons(ProfileController profileController) {
    return Obx(() {
      // Enhanced change detection
      final user = profileController.currentUser.value;
      final hasNameChange = user != null &&
          profileController.nameController.text.trim() != user.name;
      final hasPhoneChange = user != null &&
          profileController.phoneController.text.trim() != (user.phone ?? '');
      final hasChanges = hasNameChange || hasPhoneChange;

      return Column(
        children: [
          // Edit Profile Button (Always available)
          _buildEditProfileButton(profileController),

          const SizedBox(height: 16),

          // Save Changes Button (Only when there are changes)
          if (hasChanges) _buildSaveButton(profileController, hasChanges),
        ],
      );
    });
  }

  Widget _buildEditProfileButton(ProfileController profileController) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: profileController.isLoading.value
              ? null
              : () => _showEditProfileDialog(profileController),
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
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
  }

  Widget _buildSaveButton(
      ProfileController profileController, bool hasChanges) {
    return Obx(() {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: profileController.isLoading.value
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
            onTap: profileController.isLoading.value
                ? null
                : () async {
                    // Validate form first
                    if (profileController.profileFormKey.currentState!
                        .validate()) {
                      bool success = await profileController.updateProfile();
                      if (success) {
                        Get.snackbar(
                          'Success',
                          'Profile changes saved successfully!',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                      }
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
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Save Changes',
                          style: TextStyle(
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

  // Add the edit profile dialog method
  void _showEditProfileDialog(ProfileController profileController) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You can edit your profile information below. Changes will be saved when you tap "Save Changes".',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Quick Edit Options
              _buildQuickEditOption(
                'Change Name',
                'Update your display name',
                Icons.person_outline,
                () {
                  Get.back();
                  // Focus on name field
                  FocusScope.of(Get.context!).requestFocus(FocusNode());
                  Future.delayed(const Duration(milliseconds: 100), () {
                    profileController.nameController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset:
                          profileController.nameController.text.length,
                    );
                  });
                },
              ),

              const SizedBox(height: 12),

              _buildQuickEditOption(
                'Change Phone',
                'Update your phone number',
                Icons.phone_outlined,
                () {
                  Get.back();
                  // Focus on phone field
                  FocusScope.of(Get.context!).requestFocus(FocusNode());
                  Future.delayed(const Duration(milliseconds: 100), () {
                    profileController.phoneController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset:
                          profileController.phoneController.text.length,
                    );
                  });
                },
              ),

              const SizedBox(height: 12),

              _buildQuickEditOption(
                'Change Photo',
                'Update your profile picture',
                Icons.camera_alt_outlined,
                () {
                  Get.back();
                  profileController.updateProfilePicture();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Force a form validation to show any issues
              profileController.profileFormKey.currentState?.validate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEditOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4A90E2),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white38,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildAccountActions(ProfileController profileController) {
  return Column(
    children: [
      // Refresh Profile Button
      _buildActionButton(
        title: 'Refresh Profile',
        subtitle: 'Reload profile data from server',
        icon: Icons.refresh_outlined,
        onTap: () => profileController.refreshProfile(),
        iconColor: AppColors.buttonPrimary,
      ),

      const SizedBox(height: 16),

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
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
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
              const Icon(
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
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
