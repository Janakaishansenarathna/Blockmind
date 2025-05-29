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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 48.0 : 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        children: [
                          // Top spacing - responsive
                          SizedBox(height: isSmallScreen ? 20 : 40),

                          // Main content
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Email verification icon - responsive size
                                _buildVerificationIcon(isSmallScreen, isTablet),
                                SizedBox(height: isSmallScreen ? 24 : 32),

                                // Title - responsive text
                                _buildTitle(context, isTablet),
                                SizedBox(height: isSmallScreen ? 12 : 16),

                                // Description - responsive
                                _buildDescription(
                                    context, authController, isTablet),
                                SizedBox(height: isSmallScreen ? 24 : 32),

                                // Check verification status card
                                _buildVerificationStatusCard(context, isTablet),
                                SizedBox(height: isSmallScreen ? 20 : 24),

                                // Action buttons - responsive
                                _buildActionButtons(authController, isTablet),
                              ],
                            ),
                          ),

                          // Bottom content
                          Column(
                            children: [
                              // Help section
                              _buildHelpSection(context, isTablet),
                              SizedBox(height: isSmallScreen ? 16 : 24),

                              // Sign out option
                              _buildSignOutButton(context, authController),
                              SizedBox(height: isSmallScreen ? 16 : 24),

                              // Error messages
                              _buildErrorMessage(context, authController),

                              // Bottom padding
                              SizedBox(height: isSmallScreen ? 16 : 32),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationIcon(bool isSmallScreen, bool isTablet) {
    final iconSize = isSmallScreen ? 80.0 : (isTablet ? 140.0 : 120.0);
    final innerIconSize = isSmallScreen ? 40.0 : (isTablet ? 70.0 : 60.0);

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent.withOpacity(0.1),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Iconsax.sms,
        size: innerIconSize,
        color: AppColors.accent,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, bool isTablet) {
    return Text(
      'Verify Your Email',
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 32 : null,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(
      BuildContext context, AuthController authController, bool isTablet) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 600 : double.infinity,
      ),
      child: Obx(() {
        final userEmail = authController.currentUser.value?.email ??
            authController.emailController.text;
        return Text(
          'We\'ve sent a verification email to\n$userEmail\n\nPlease check your email and click the verification link to continue.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
                fontSize: isTablet ? 18 : null,
              ),
          textAlign: TextAlign.center,
        );
      }),
    );
  }

  Widget _buildVerificationStatusCard(BuildContext context, bool isTablet) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isTablet ? 500 : double.infinity,
      ),
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.clock,
            color: AppColors.accent,
            size: isTablet ? 40 : 32,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            'Checking verification status...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isTablet ? 16 : null,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'We\'ll automatically redirect you once your email is verified.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: isTablet ? 14 : null,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AuthController authController, bool isTablet) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 400 : double.infinity,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Resend email button
          Obx(() => CustomButton(
                text: _resendCooldown > 0
                    ? 'Resend in ${_resendCooldown}s'
                    : 'Resend Verification Email',
                onPressed: _resendCooldown > 0 || authController.isLoading.value
                    ? null
                    : () async {
                        await authController.sendEmailVerification();
                        _startResendCooldown();
                      },
                isLoading: authController.isLoading.value,
                variant: ButtonVariant.outline,
              )),
          SizedBox(height: isTablet ? 20 : 16),

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
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, bool isTablet) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isTablet ? 600 : double.infinity,
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Iconsax.info_circle,
                color: AppColors.warning,
                size: isTablet ? 28 : 24,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  'Didn\'t receive the email?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 18 : null,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Padding(
            padding: EdgeInsets.only(left: isTablet ? 44 : 36),
            child: Text(
              '• Check your spam/junk folder\n• Make sure you entered the correct email address\n• Try resending the verification email\n• Contact support if the problem persists',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontSize: isTablet ? 14 : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(
      BuildContext context, AuthController authController) {
    return TextButton(
      onPressed: () async {
        await authController.signOut();
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        'Use a different email address',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildErrorMessage(
      BuildContext context, AuthController authController) {
    return Obx(() {
      return authController.errorMessage.isEmpty
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ),
                ],
              ),
            );
    });
  }
}
