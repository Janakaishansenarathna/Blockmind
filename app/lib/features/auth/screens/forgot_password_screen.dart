import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../common/widgets/buttons/custom_button.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: authController.forgotPasswordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.iconPrimary,
                      ),
                      onPressed: () {
                        authController.clearForgotPasswordForm();
                        Get.back();
                      },
                    ),
                  ),
                  const SizedBox(height: 40),

                  if (!_emailSent) ...[
                    // Reset password icon
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withOpacity(0.1),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.lock,
                          size: 60,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Forgot Password?',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Don\'t worry! Enter your email address and we\'ll send you a link to reset your password.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Email field
                    _buildTextField(
                      controller: authController.forgotPasswordEmailController,
                      label: 'Email Address',
                      hint: 'Enter your email address',
                      icon: Iconsax.sms,
                      keyboardType: TextInputType.emailAddress,
                      validator: authController.validateEmail,
                    ),
                    const SizedBox(height: 32),

                    // Send reset email button
                    Obx(() => CustomButton(
                          text: 'Send Reset Link',
                          onPressed: authController.isLoading.value
                              ? null
                              : () async {
                                  bool success = await authController.sendPasswordResetEmail();
                                  if (success) {
                                    setState(() {
                                      _emailSent = true;
                                    });
                                  }
                                },
                          isLoading: authController.isLoading.value,
                        )),
                  ] else ...[
                    // Email sent confirmation
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.tick_circle,
                          size: 60,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Success title
                    Text(
                      'Check Your Email!',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Success description
                    Text(
                      'We\'ve sent a password reset link to ${authController.forgotPasswordEmailController.text}\n\nPlease check your email and follow the instructions to reset your password.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Back to login button
                    CustomButton(
                      text: 'Back to Login',
                      onPressed: () {
                        authController.clearForgotPasswordForm();
                        Get.back();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Resend email button
                    CustomButton(
                      text: 'Resend Email',
                      onPressed: () async {
                        await authController.sendPasswordResetEmail();
                      },
                      variant: ButtonVariant.outline,
                    ),
                  ],
                  
                  const SizedBox(height: 40),

                  // Help section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warningBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Iconsax.info_circle,
                              color: AppColors.warning,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Didn\'t receive the email?',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '" Check your spam/junk folder\n" Make sure you entered the correct email address\n" Wait a few minutes and try again\n" Contact support if the problem persists',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error messages
                  Obx(() {
                    return authController.errorMessage.isEmpty
                        ? const SizedBox.shrink()
                        : Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    authController.errorMessage.value,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.error,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.iconSecondary),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}