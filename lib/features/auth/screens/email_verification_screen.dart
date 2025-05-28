import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import '../../../utils/constants/app_colors.dart';
import '../../../common/widgets/buttons/custom_button.dart';
import '../controllers/auth_controller.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final AuthController authController = Get.find<AuthController>();
      bool isVerified = await authController.checkEmailVerification();
      if (isVerified) {
        timer.cancel();
      }
    });
  }

  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 60;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Email verification icon
                Container(
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
                    Iconsax.sms,
                    size: 60,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Obx(() {
                  final userEmail = authController.currentUser.value?.email ??
                      authController.emailController.text;
                  return Text(
                    'We\'ve sent a verification email to\n$userEmail\n\nPlease check your email and click the verification link to continue.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  );
                }),
                const SizedBox(height: 40),

                // Check verification status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Iconsax.clock,
                        color: AppColors.accent,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Checking verification status...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll automatically redirect you once your email is verified.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Resend email button
                Obx(() => CustomButton(
                      text: _resendCooldown > 0
                          ? 'Resend in ${_resendCooldown}s'
                          : 'Resend Verification Email',
                      onPressed:
                          _resendCooldown > 0 || authController.isLoading.value
                              ? null
                              : () async {
                                  await authController.sendEmailVerification();
                                  _startResendCooldown();
                                },
                      isLoading: authController.isLoading.value,
                      variant: ButtonVariant.outline,
                    )),
                const SizedBox(height: 16),

                // Check verification manually button
                Obx(() => CustomButton(
                      text: 'I\'ve verified my email',
                      onPressed: authController.isLoading.value
                          ? null
                          : () async {
                              await authController.checkEmailVerification();
                            },
                      isLoading: authController.isLoading.value,
                    )),

                const Spacer(),

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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Check your spam/junk folder\n• Make sure you entered the correct email address\n• Try resending the verification email\n• Contact support if the problem persists',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign out option
                TextButton(
                  onPressed: () async {
                    await authController.signOut();
                  },
                  child: Text(
                    'Use a different email address',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
