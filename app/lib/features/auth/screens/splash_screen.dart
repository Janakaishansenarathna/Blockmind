import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../data/local/models/user_model.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _poweredByController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _poweredByFadeAnimation;
  late Animation<Offset> _poweredBySlideAnimation;

  final FirebaseAuthService _authService = FirebaseAuthService();

  // Storage keys
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String userStorageKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startNavigationFlow();
  }

  void _initializeAnimations() {
    // Main animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Powered by animation controller
    _poweredByController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Logo animations
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Powered by animations
    _poweredByFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _poweredByController,
        curve: Curves.easeInOut,
      ),
    );

    _poweredBySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _poweredByController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animations
    _animationController.forward();

    // Delay powered by animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _poweredByController.forward();
      }
    });
  }

  void _startNavigationFlow() {
    // Navigate after animations complete
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _determineNavigationRoute();
      }
    });
  }

  Future<void> _determineNavigationRoute() async {
    try {
      debugPrint('SplashScreen: Starting navigation determination');

      // Step 1: Check if user has seen onboarding
      bool hasSeenOnboarding = await _hasSeenOnboarding();
      debugPrint('SplashScreen: Has seen onboarding: $hasSeenOnboarding');

      if (!hasSeenOnboarding) {
        debugPrint('SplashScreen: Navigating to onboarding');
        _navigateToRoute(AppRoutes.onboarding);
        return;
      }

      // Step 2: Check Firebase Auth state
      User? firebaseUser = _authService.currentUser;
      debugPrint('SplashScreen: Firebase user exists: ${firebaseUser != null}');

      if (firebaseUser != null) {
        // User is authenticated with Firebase
        await _handleAuthenticatedUser(firebaseUser);
      } else {
        // No Firebase user, check local storage
        await _handleUnauthenticatedUser();
      }
    } catch (e) {
      debugPrint('SplashScreen: Error in navigation determination: $e');
      // Default to welcome screen on error
      _navigateToRoute(AppRoutes.welcome);
    }
  }

  Future<void> _handleAuthenticatedUser(User firebaseUser) async {
    try {
      debugPrint(
          'SplashScreen: Handling authenticated user: ${firebaseUser.uid}');

      // Check if email verification is required
      bool requiresEmailVerification =
          await _requiresEmailVerification(firebaseUser);

      if (requiresEmailVerification) {
        debugPrint('SplashScreen: Email verification required');
        _navigateToRoute(AppRoutes.emailVerification);
        return;
      }

      // User is fully authenticated, go to dashboard
      debugPrint(
          'SplashScreen: User fully authenticated, navigating to dashboard');
      _navigateToRoute(AppRoutes.dashboard);
    } catch (e) {
      debugPrint('SplashScreen: Error handling authenticated user: $e');
      _navigateToRoute(AppRoutes.welcome);
    }
  }

  Future<void> _handleUnauthenticatedUser() async {
    try {
      debugPrint('SplashScreen: Handling unauthenticated user');

      // Check for local user data
      UserModel? localUser = await _getLocalUserData();

      if (localUser != null) {
        debugPrint('SplashScreen: Found local user data, but no Firebase auth');
        // Has local data but not authenticated - likely session expired
        _navigateToRoute(AppRoutes.welcome);
      } else {
        debugPrint('SplashScreen: No local user data found');
        // Completely new user or fully logged out
        _navigateToRoute(AppRoutes.welcome);
      }
    } catch (e) {
      debugPrint('SplashScreen: Error handling unauthenticated user: $e');
      _navigateToRoute(AppRoutes.welcome);
    }
  }

  Future<bool> _hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(hasSeenOnboardingKey) ?? false;
    } catch (e) {
      debugPrint('SplashScreen: Error checking onboarding status: $e');
      return false;
    }
  }

  Future<bool> _requiresEmailVerification(User firebaseUser) async {
    try {
      // Check if this is an email/password user
      bool isEmailPasswordUser = firebaseUser.providerData
          .any((provider) => provider.providerId == 'password');

      if (!isEmailPasswordUser) {
        // Social login users don't need email verification
        debugPrint(
            'SplashScreen: Social login user, no email verification needed');
        return false;
      }

      // For email/password users, check verification status
      await firebaseUser.reload(); // Refresh user data
      bool isEmailVerified = _authService.currentUser?.emailVerified ?? false;

      debugPrint('SplashScreen: Email verification status: $isEmailVerified');
      return !isEmailVerified;
    } catch (e) {
      debugPrint('SplashScreen: Error checking email verification: $e');
      // If we can't check, assume verification is not required
      return false;
    }
  }

  Future<UserModel?> _getLocalUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user is marked as logged in
      bool isLoggedIn = prefs.getBool(isLoggedInKey) ?? false;
      if (!isLoggedIn) {
        return null;
      }

      // Get user data
      String? userJsonString = prefs.getString(userStorageKey);

      final userJson = jsonDecode(userJsonString!) as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } catch (e) {
      debugPrint('SplashScreen: Error getting local user data: $e');
      return null;
    }
  }

  void _navigateToRoute(String route) {
    if (mounted) {
      debugPrint('SplashScreen: Navigating to: $route');
      Get.offAllNamed(route);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _poweredByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo animation with glow effect
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(75),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.1),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  AppImages.appLogo,
                                  width: 150,
                                  height: 150,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // App tagline with enhanced animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _animationController,
                            curve:
                                const Interval(0.4, 1.0, curve: Curves.easeOut),
                          ),
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value * 0.5),
                            child: const Text(
                              AppConstants.appTagline,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Loading indicator
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _animationController,
                            curve:
                                const Interval(0.6, 1.0, curve: Curves.easeOut),
                          ),
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Powered by MAD Developers at bottom
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _poweredByController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _poweredBySlideAnimation,
                      child: FadeTransition(
                        opacity: _poweredByFadeAnimation,
                        child: Column(
                          children: [
                            // Decorative line
                            Container(
                              width: 60,
                              height: 1,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),

                            // Powered by text
                            const Text(
                              'Powered by',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // MAD Developers brand with styling
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.05),
                                    Colors.white.withOpacity(0.02),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // MAD icon/logo placeholder
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.withOpacity(0.8),
                                          Colors.purple.withOpacity(0.8),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.code,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Company name with gradient text effect
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.8),
                                      ],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'MAD Developers',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Floating particles effect
              ...List.generate(8, (index) {
                final startValue = (index * 0.1).clamp(0.0, 0.7);
                final endValue =
                    (startValue + 0.3).clamp(startValue + 0.1, 1.0);

                return Positioned(
                  left: (index * 50.0 + 20) %
                      (MediaQuery.of(context).size.width - 50),
                  top: (index * 80.0 + 30) %
                      (MediaQuery.of(context).size.height - 100),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            startValue,
                            endValue,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          width: 2,
                          height: 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
