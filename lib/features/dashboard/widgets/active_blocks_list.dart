// presentation/screens/home/widgets/blocklist_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../../utils/themes/gradient_background.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/quick_mood_controller.dart';

class BlocklistScreen extends StatefulWidget {
  const BlocklistScreen({super.key});

  @override
  State<BlocklistScreen> createState() => _BlocklistScreenState();
}

class _BlocklistScreenState extends State<BlocklistScreen> {
  late final HomeController homeController;
  late final QuickModeController quickModeController;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers in initState to ensure they're ready
    homeController = Get.find<HomeController>();
    quickModeController = Get.find<QuickModeController>();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search bar
            _buildSearchBar(),

            // Quick selection presets
            _buildQuickSelectionPresets(),

            // App categories list
            Expanded(
              child: _buildAppCategoriesList(),
            ),

            // Bottom action bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.iconPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Apps to Block',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Choose which apps to block during Quick Mode',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Obx(() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.buttonPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.buttonPrimary.withOpacity(0.3)),
                ),
                child: Text(
                  '${quickModeController.selectedApps.length}',
                  style: const TextStyle(
                    color: AppColors.buttonPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) => homeController.searchApps(value),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Search apps...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppColors.iconSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuickSelectionPresets() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Select',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetButton(
                  'Social Media',
                  Icons.people,
                  Colors.blue,
                  () => quickModeController.selectPopularApps(),
                ),
                const SizedBox(width: 8),
                _buildPresetButton(
                  'All Apps',
                  Icons.select_all,
                  Colors.green,
                  () => quickModeController.selectAllApps(),
                ),
                const SizedBox(width: 8),
                _buildPresetButton(
                  'Clear All',
                  Icons.clear,
                  Colors.orange,
                  () => quickModeController.clearSelectedApps(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCategoriesList() {
    return Obx(() {
      if (homeController.isLoadingApps.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.buttonPrimary),
        );
      }

      final categories = homeController.getAppsByCategory();

      if (categories.isEmpty) {
        return const Center(
          child: Text(
            'No apps found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final categoryName = categories.keys.elementAt(index);
          final apps = categories[categoryName]!;

          return _buildCategorySection(categoryName, apps);
        },
      );
    });
  }

  Widget _buildCategorySection(String categoryName, List apps) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (apps.isNotEmpty && !categoryName.startsWith('Selected'))
                  GestureDetector(
                    onTap: () {
                      // Toggle all apps in this category
                      for (final app in apps) {
                        if (!quickModeController.isAppSelected(app)) {
                          quickModeController.toggleAppSelection(app);
                        }
                      }
                    },
                    child: Text(
                      'Select All',
                      style: TextStyle(
                        color: AppColors.buttonPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Apps list
          if (apps.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No apps in this category',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return _buildAppTile(app);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppTile(app) {
    return Obx(() {
      final isSelected = quickModeController.isAppSelected(app);

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonPrimary.withOpacity(0.1)
              : AppColors.background.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.buttonPrimary.withOpacity(0.3)
                : AppColors.borderColor.withOpacity(0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => quickModeController.toggleAppSelection(app),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // App icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: app.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      app.icon,
                      color: app.iconColor,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // App details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          app.packageName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.buttonPrimary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.buttonPrimary
                            : AppColors.borderColor,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Selection count
            Expanded(
              child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quickModeController.selectedAppsCountText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (quickModeController.selectedApps.isNotEmpty)
                        Text(
                          'Ready to start Quick Mode',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  )),
            ),

            const SizedBox(width: 16),

            // Action buttons
            Row(
              children: [
                // Cancel button
                Container(
                  width: 80,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Done button
                Obx(() => Container(
                      width: 100,
                      height: 48,
                      decoration: BoxDecoration(
                        color: quickModeController.selectedApps.isNotEmpty
                            ? AppColors.buttonPrimary
                            : AppColors.borderColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: quickModeController.selectedApps.isNotEmpty
                              ? () {
                                  Get.back();
                                  Get.snackbar(
                                    'Apps Selected',
                                    '${quickModeController.selectedApps.length} apps selected for blocking',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.success,
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              'Done',
                              style: TextStyle(
                                color:
                                    quickModeController.selectedApps.isNotEmpty
                                        ? Colors.white
                                        : AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
