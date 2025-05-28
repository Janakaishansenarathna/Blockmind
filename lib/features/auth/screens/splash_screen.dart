import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/constants/app_images.dart';
import '../../../utils/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final FirebaseAuthService _authService = FirebaseAuthService();
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Navigate to appropriate screen after animation
    Future.delayed(const Duration(seconds: 3), () {
      _checkNavigationPath();
    });
  }

  Future<void> _checkNavigationPath() async {
    try {
      // Check if first time use
      final prefs = await SharedPreferences.getInstance();
      bool hasSeenOnboarding = prefs.getBool(hasSeenOnboardingKey) ?? false;

      if (!hasSeenOnboarding) {
        // First time user, show onboarding
        Get.offAllNamed(AppRoutes.onboarding);
        return;
      }

      // Check if user is currently authenticated with Firebase
      if (_authService.currentUser != null) {
        // User is logged in, check if email is verified (for email/password users)
        bool isEmailVerified = await _authService.isEmailVerified();

        if (!isEmailVerified &&
            _authService.currentUser!.providerData
                .any((provider) => provider.providerId == 'password')) {
          // Email/password user with unverified email, go to verification screen
          Get.offAllNamed(AppRoutes.emailVerification);
        } else {
          // User is fully authenticated, go to dashboard
          Get.offAllNamed(AppRoutes.dashboard);
        }
      } else {
        // User is not logged in, check if they have local user data
        bool hasLocalUserData = await _authService.isLoggedIn();

        if (hasLocalUserData) {
          // Has local data but not authenticated, likely logged out or session expired
          Get.offAllNamed(AppRoutes.welcome);
        } else {
          // No local data, completely new or logged out user
          Get.offAllNamed(AppRoutes.welcome);
        }
      }
    } catch (e) {
      // In case of any error, default to welcome screen for returning users
      print('Error in navigation: $e');
      Get.offAllNamed(AppRoutes.welcome);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Image.asset(
                        AppImages.appLogo,
                        width: 150,
                        height: 150,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              // App name with fade animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Tagline with delayed fade animation
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                ),
                child: const Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
