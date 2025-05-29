import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/models/schedule_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/quick_mood_controller.dart';
import '../widgets/active_blocks_list.dart';
import '../widgets/time_selection_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.put(DashboardController());
    final quickModeController = Get.put(QuickModeController());

    _setupReactiveListeners(dashboardController, quickModeController);

    return GradientScaffold(
      child: SafeArea(
        child: Obx(() {
          if (!dashboardController.isInitialized.value) {
            return InitializationScreen(
                dashboardController: dashboardController);
          }

          return RefreshIndicator(
            onRefresh: () =>
                _handleRefresh(dashboardController, quickModeController),
            color: AppColors.buttonPrimary,
            backgroundColor: AppColors.containerBackground,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderSection(dashboardController: dashboardController),
                  const SizedBox(height: 24),
                  OfflineIndicator(dashboardController: dashboardController),
                  const SizedBox(height: 24),
                  QuickModeSection(
                    dashboardController: dashboardController,
                    quickModeController: quickModeController,
                  ),
                  const SizedBox(height: 24),
                  SchedulesSection(dashboardController: dashboardController),
                  const SizedBox(height: 24),
                  ProgressSection(dashboardController: dashboardController),
                  const SizedBox(height: 24),
                  StatsSection(dashboardController: dashboardController),
                  const SizedBox(height: 24),
                  QuickActionsSection(dashboardController: dashboardController),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _setupReactiveListeners(
    DashboardController dashboardController,
    QuickModeController quickModeController,
  ) {
    ever(dashboardController.allApps, (apps) {
      if (apps.isNotEmpty) {
        quickModeController.setAvailableApps(apps);
      }
    });

    ever(dashboardController.isAuthenticated, (isAuth) {
      if (!isAuth) {
        print('HomeScreen: User signed out, navigation handled by controller');
      }
    });
  }

  Future<void> _handleRefresh(
    DashboardController dashboardController,
    QuickModeController quickModeController,
  ) async {
    try {
      await Future.wait([
        dashboardController.refreshData(),
        quickModeController.refreshQuickModeData(),
      ]);
      Get.snackbar(
        'Refreshed',
        'Data updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.success.withOpacity(0.1),
        colorText: AppColors.success,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Refresh Failed',
        'Failed to update data. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

class InitializationScreen extends StatelessWidget {
  final DashboardController dashboardController;

  const InitializationScreen({required this.dashboardController, super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (dashboardController.isInitializing.value) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.buttonPrimary,
          ),
        );
      }
      return Center(
        child: Text(
          dashboardController.errorMessage.value.isNotEmpty
              ? dashboardController.errorMessage.value
              : 'Initialization Failed',
          style: const TextStyle(color: AppColors.error),
        ),
      );
    });
  }
}

class HeaderSection extends StatelessWidget {
  final DashboardController dashboardController;

  const HeaderSection({required this.dashboardController, super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${dashboardController.currentLoggedUsername}!',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getGreetingMessage(),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Get.to(() => const ChatbotScreen()),
            icon: const Icon(Icons.psychology, color: Colors.blue),
          ),
        ],
      );
    });
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 18) return 'Good afternoon!';
    return 'Good evening!';
  }
}

class OfflineIndicator extends StatelessWidget {
  final DashboardController dashboardController;

  const OfflineIndicator({required this.dashboardController, super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!dashboardController.isConnected.value) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              Icon(Icons.wifi_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('You\'re offline. Some features may not work properly.'),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}

// Additional sections like QuickModeSection, SchedulesSection, ProgressSection, StatsSection, and QuickActionsSection
// can be implemented similarly as separate stateless widgets for better modularity.
