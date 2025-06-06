import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/constants/app_images.dart';
import '../../../routes/routes.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the auth controller
    final AuthController authController = Get.find<AuthController>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                            Get.back();
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Login title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Welcome Back',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
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
                          'Login to continue improving your focus and productivity',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // App logo with error handling
                      Center(
                        child: Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            AppImages.login,
                            width: 180,
                            height: 180,
                            // Add error handling
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.buttonPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(75),
                                ),
                                child: const Icon(
                                  Icons.login,
                                  size: 60,
                                  color: AppColors.buttonPrimary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Login options section
                      Column(
                        children: [
                          // Email/Password login button
                          _buildLoginButton(
                            context: context,
                            label: 'Continue with Email',
                            icon: Icons.email_outlined,
                            onPressed: () {
                              Get.toNamed(AppRoutes.emailLogin);
                            },
                            backgroundColor: AppColors.buttonPrimary,
                            textColor: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          // Google login button
                          _buildSocialLoginButton(
                            context: context,
                            label: 'Continue with Google',
                            icon: AppImages.googleIcon,
                            onPressed: () async {
                              await authController.loginWithGoogle();
                            },
                            backgroundColor: Colors.white,
                            textColor: Colors.black87,
                          ),
                          const SizedBox(height: 16),
                          // Facebook login button (placeholder)
                          _buildSocialLoginButton(
                            context: context,
                            label: 'Continue with Facebook',
                            icon: AppImages.facebookIcon,
                            onPressed: () async {
                              Get.snackbar(
                                'Coming Soon',
                                'Facebook login will be available in a future update',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: AppColors.warningBackground,
                                colorText: AppColors.warning,
                              );
                            },
                            backgroundColor: AppColors.facebookBlue,
                            textColor: Colors.white,
                          ),
                        ],
                      ),

                      // Flexible space instead of Spacer for scrollable content
                      const SizedBox(height: 40),

                      // Sign up link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    authController.clearLoginForm();
                                    Get.toNamed(AppRoutes.register);
                                  },
                                  child: Text(
                                    'Sign Up',
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
                      // Loading indicator
                      Obx(() {
                        return authController.isLoading.value
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.buttonPrimary),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }),
                      // Terms and privacy
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                              children: const [
                                TextSpan(
                                  text: 'By continuing, you agree to our ',
                                ),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' and ',
                                ),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: textColor,
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
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
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
              // Add error handling for social icons
              errorBuilder: (context, error, stackTrace) {
                print('Error loading social icon: $error');
                return Icon(
                  Icons.account_circle,
                  size: 24,
                  color: textColor,
                );
              },
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
