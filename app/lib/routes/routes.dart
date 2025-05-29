import 'package:get/get.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/on_boarding_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/email_login_screen.dart';
import '../features/auth/screens/email_register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/email_verification_screen.dart';
import '../navigation_menu.dart';

/// App route definitions and navigation
class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailLogin = '/email-login';
  static const String emailRegister = '/email-register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String dashboard = '/dashboard';
  static const String appsList = '/apps_list';
  static const String scheduleList = '/schedule_list';
  static const String createSchedule = '/create_schedule';
  static const String editSchedule = '/edit_schedule';
  static const String quickBlock = '/quick_block';
  static const String analytics = '/analytics';
  static const String profile = '/profile';
  static const String editProfile = '/edit_profile';
  static const String subscriptionPlans = '/subscription_plans';
  static const String manageSubscription = '/manage_subscription';

  // Route list
  static final routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
    ),
    GetPage(
      name: welcome,
      page: () => const WelcomeScreen(),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: register,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: emailLogin,
      page: () => const EmailLoginScreen(),
    ),
    GetPage(
      name: emailRegister,
      page: () => const EmailRegisterScreen(),
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: emailVerification,
      page: () => const EmailVerificationScreen(),
    ),
    GetPage(
      name: dashboard,
      page: () => const AppNavBar(),
    ),

    // Uncomment these routes as you implement the screens
    /*
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: appsList,
      page: () => const AppsListScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: scheduleList,
      page: () => const ScheduleListScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: createSchedule,
      page: () => const CreateScheduleScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: editSchedule,
      page: () => const EditScheduleScreen(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: quickBlock,
      page: () => const QuickBlockScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: analytics,
      page: () => const AnalyticsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: editProfile,
      page: () => const EditProfileScreen(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: subscriptionPlans,
      page: () => const SubscriptionPlansScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: manageSubscription,
      page: () => const ManageSubscriptionScreen(),
      middlewares: [AuthMiddleware()],
    ),
    */
  ];

  // Helper functions
  static void goToOnboarding() {
    Get.offAllNamed(onboarding);
  }

  static void goToWelcome() {
    Get.offAllNamed(welcome);
  }

  static void goToDashboard() {
    Get.offAllNamed(dashboard);
  }

  static void goToLogin() {
    Get.toNamed(login);
  }

  static void goToRegister() {
    Get.toNamed(register);
  }

  static void goToScheduleList() {
    Get.toNamed(scheduleList);
  }

  static void goToCreateSchedule() {
    Get.toNamed(createSchedule);
  }

  static void goToEditSchedule(String scheduleId) {
    Get.toNamed('$editSchedule/$scheduleId');
  }

  static void goToAppsList() {
    Get.toNamed(appsList);
  }

  static void goToQuickBlock() {
    Get.toNamed(quickBlock);
  }

  static void goToAnalytics() {
    Get.toNamed(analytics);
  }

  static void goToProfile() {
    Get.toNamed(profile);
  }

  static void goToEditProfile() {
    Get.toNamed(editProfile);
  }

  static void goToSubscriptionPlans() {
    Get.toNamed(subscriptionPlans);
  }

  static void goToManageSubscription() {
    Get.toNamed(manageSubscription);
  }

  static void goBack() {
    Get.back();
  }
}
