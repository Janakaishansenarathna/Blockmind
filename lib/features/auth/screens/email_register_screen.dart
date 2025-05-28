import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/constants/app_images.dart';
import '../../../common/widgets/buttons/custom_button.dart';
import '../controllers/auth_controller.dart';
import '../../../routes/routes.dart';

class EmailRegisterScreen extends StatelessWidget {
  const EmailRegisterScreen({super.key});

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
              key: authController.registerFormKey,
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
                        authController.clearRegisterForm();
                        Get.back();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Join Focus Block to improve your productivity',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App logo
                  Center(
                    child: Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        AppImages.appLogo,
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Name field
                  _buildTextField(
                    controller: authController.nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Iconsax.user,
                    keyboardType: TextInputType.name,
                    validator: authController.validateName,
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  _buildTextField(
                    controller: authController.emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    icon: Iconsax.sms,
                    keyboardType: TextInputType.emailAddress,
                    validator: authController.validateEmail,
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  Obx(() => _buildTextField(
                        controller: authController.passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Iconsax.lock,
                        obscureText: authController.obscurePassword.value,
                        validator: authController.validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            authController.obscurePassword.value
                                ? Iconsax.eye_slash
                                : Iconsax.eye,
                            color: AppColors.iconSecondary,
                          ),
                          onPressed: authController.togglePasswordVisibility,
                        ),
                      )),
                  const SizedBox(height: 20),

                  // Confirm Password field
                  Obx(() => _buildTextField(
                        controller: authController.confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Confirm your password',
                        icon: Iconsax.lock,
                        obscureText: authController.obscureConfirmPassword.value,
                        validator: authController.validateConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            authController.obscureConfirmPassword.value
                                ? Iconsax.eye_slash
                                : Iconsax.eye,
                            color: AppColors.iconSecondary,
                          ),
                          onPressed: authController.toggleConfirmPasswordVisibility,
                        ),
                      )),
                  const SizedBox(height: 24),

                  // Terms and conditions checkbox
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Obx(() => Checkbox(
                              value: authController.acceptedTerms.value,
                              onChanged: (value) {
                                authController.acceptedTerms.value = value ?? false;
                              },
                              activeColor: AppColors.accent,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(
                                color: AppColors.textSecondary,
                                width: 1.5,
                              ),
                            )),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                              children: const [
                                TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register button
                  Obx(() => CustomButton(
                        text: 'Create Account',
                        onPressed: authController.isLoading.value
                            ? null
                            : () async {
                                await authController.registerWithEmailPassword();
                              },
                        isLoading: authController.isLoading.value,
                      )),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google registration button
                  _buildSocialLoginButton(
                    context: context,
                    label: 'Sign up with Google',
                    icon: 'assets/icons/google.png',
                    onPressed: () async {
                      await authController.registerWithGoogle();
                    },
                    backgroundColor: Colors.white,
                    textColor: Colors.black87,
                  ),
                  const SizedBox(height: 24),

                  // Sign in link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        children: [
                          const TextSpan(text: "Already have an account? "),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                authController.clearRegisterForm();
                                Get.toNamed(AppRoutes.emailLogin);
                              },
                              child: Text(
                                'Sign In',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
    bool obscureText = false,
    Widget? suffixIcon,
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
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.iconSecondary),
            suffixIcon: suffixIcon,
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

  Widget _buildSocialLoginButton({
    required BuildContext context,
    required String label,
    required String icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.divider, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}