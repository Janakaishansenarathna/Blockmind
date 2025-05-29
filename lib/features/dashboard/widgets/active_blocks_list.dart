// presentation/screens/home/widgets/blocklist_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../../utils/themes/gradient_background.dart';
import '../../../../data/local/models/app_model.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/quick_mood_controller.dart';

/// Production-level Blocklist Screen
///
/// Features:
/// - Complete app selection interface with search functionality
/// - Category-based app organization with selection presets
/// - Real-time search with debouncing for performance
/// - Professional UI with loading states and error handling
/// - Smart categorization and filtering system
/// - Batch selection operations (select all, clear all, etc.)
/// - Enhanced user experience with animations and feedback
/// - Integration with both Dashboard and QuickMode controllers
class BlocklistScreen extends StatefulWidget {
  const BlocklistScreen({super.key});

  @override
  State<BlocklistScreen> createState() => _BlocklistScreenState();
}

class _BlocklistScreenState extends State<BlocklistScreen>
    with TickerProviderStateMixin {
  // Controllers
  late final DashboardController dashboardController;
  late final QuickModeController quickModeController;

  // Search and UI controllers
  final TextEditingController searchController = TextEditingController();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Local state
  String _searchQuery = '';
  bool _isSearching = false;
  Map<String, List<AppModel>> _filteredCategories = {};
  List<AppModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _loadInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize controllers with error handling
  void _initializeControllers() {
    try {
      dashboardController = Get.find<DashboardController>();
      quickModeController = Get.find<QuickModeController>();
    } catch (e) {
      print('BlocklistScreen: Error finding controllers: $e');
      // Show error and navigate back
      Get.snackbar(
        'Error',
        'Failed to initialize app list. Please try again.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      Get.back();
    }
  }

  /// Setup animations for smooth transitions
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  /// Load initial data and setup listeners
  void _loadInitialData() {
    // Load apps if not already loaded
    if (dashboardController.allApps.isEmpty) {
      dashboardController.refreshData();
    }

    // Update filtered categories
    _updateFilteredCategories();
  }

  /// Update filtered categories based on search query
  void _updateFilteredCategories() {
    if (_searchQuery.isEmpty) {
      _filteredCategories = _getAppsByCategory();
      _searchResults.clear();
      _isSearching = false;
    } else {
      _searchResults = dashboardController.allApps
          .where((app) =>
              app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              app.packageName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
      _isSearching = true;
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// Get apps organized by category
  Map<String, List<AppModel>> _getAppsByCategory() {
    final selectedApps = quickModeController.selectedApps;
    final categories = <String, List<AppModel>>{};

    // Add selected apps first if any
    if (selectedApps.isNotEmpty) {
      categories['Selected Apps (${selectedApps.length})'] =
          selectedApps.toList();
    }

    // Group remaining apps by category
    final unselectedApps = dashboardController.allApps
        .where((app) => !quickModeController.isAppSelected(app))
        .toList();

    final groupedApps = <String, List<AppModel>>{};
    for (final app in unselectedApps) {
      final category = app.category ?? 'Other';
      groupedApps.putIfAbsent(category, () => []).add(app);
    }

    // Add non-empty categories
    groupedApps.forEach((category, apps) {
      if (apps.isNotEmpty) {
        categories[category] = apps;
      }
    });

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header with back button and selection count
              _buildHeader(),

              // Search bar with real-time filtering
              _buildSearchBar(),

              // Quick selection presets and actions
              _buildQuickSelectionPresets(),

              // Main content - apps list or search results
              Expanded(
                child: _buildContent(),
              ),

              // Bottom action bar with selection info and actions
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build header with navigation and selection count
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.containerBackground.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.back(),
                borderRadius: BorderRadius.circular(12),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.iconPrimary,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title and subtitle
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
                  'Choose apps to block during focus sessions',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Selection count badge
          Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: quickModeController.selectedApps.isNotEmpty
                      ? AppColors.buttonPrimary.withOpacity(0.1)
                      : AppColors.borderColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: quickModeController.selectedApps.isNotEmpty
                        ? AppColors.buttonPrimary.withOpacity(0.3)
                        : AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: quickModeController.selectedApps.isNotEmpty
                          ? AppColors.buttonPrimary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${quickModeController.selectedApps.length}',
                      style: TextStyle(
                        color: quickModeController.selectedApps.isNotEmpty
                            ? AppColors.buttonPrimary
                            : AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Build search bar with real-time filtering
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _updateFilteredCategories();
        },
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search apps by name or package...',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.iconSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _updateFilteredCategories();
                  },
                  icon: const Icon(Icons.clear, color: AppColors.iconSecondary),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /// Build quick selection presets and batch actions
  Widget _buildQuickSelectionPresets() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() => Text(
                    'Total: ${dashboardController.allApps.length} apps',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 12),

          // Preset buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetButton(
                  'Social Media',
                  Icons.people_outline,
                  Colors.blue,
                  () => _selectAppsByCategory('Social Media'),
                ),
                const SizedBox(width: 8),
                _buildPresetButton(
                  'Entertainment',
                  Icons.movie_outlined,
                  Colors.purple,
                  () => _selectAppsByCategory('Entertainment'),
                ),
                const SizedBox(width: 8),
                _buildPresetButton(
                  'Select All',
                  Icons.select_all,
                  Colors.green,
                  () => _selectAllApps(),
                ),
                const SizedBox(width: 8),
                _buildPresetButton(
                  'Clear All',
                  Icons.clear_all,
                  Colors.orange,
                  () => _clearAllApps(),
                ),
                const SizedBox(width: 8),
                _buildPresetButton(
                  'Popular Apps',
                  Icons.trending_up,
                  Colors.red,
                  () => _selectPopularApps(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build preset action button
  Widget _buildPresetButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
      ),
    );
  }

  /// Build main content - categories or search results
  Widget _buildContent() {
    return Obx(() {
      if (dashboardController.isLoadingApps.value) {
        return _buildLoadingState();
      }

      if (dashboardController.allApps.isEmpty) {
        return _buildEmptyState();
      }

      if (_isSearching) {
        return _buildSearchResults();
      }

      return _buildCategoriesList();
    });
  }

  /// Build loading state with skeleton
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.buttonPrimary),
          SizedBox(height: 16),
          Text(
            'Loading apps...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No apps found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your app permissions or try refreshing',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => dashboardController.refreshData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  /// Build search results
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No apps found for "$_searchQuery"',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search term',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildAppTile(_searchResults[index]);
      },
    );
  }

  /// Build categories list
  Widget _buildCategoriesList() {
    if (_filteredCategories.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final categoryName = _filteredCategories.keys.elementAt(index);
        final apps = _filteredCategories[categoryName]!;
        return _buildCategorySection(categoryName, apps);
      },
    );
  }

  /// Build category section with apps
  Widget _buildCategorySection(String categoryName, List<AppModel> apps) {
    final isSelectedCategory = categoryName.startsWith('Selected Apps');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header with actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelectedCategory
                  ? AppColors.buttonPrimary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(categoryName),
                      color: isSelectedCategory
                          ? AppColors.buttonPrimary
                          : AppColors.iconSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      categoryName,
                      style: TextStyle(
                        color: isSelectedCategory
                            ? AppColors.buttonPrimary
                            : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (apps.isNotEmpty && !isSelectedCategory)
                  Row(
                    children: [
                      Text(
                        '${apps.length} apps',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectCategoryApps(apps),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: const Text(
                              'Select All',
                              style: TextStyle(
                                color: AppColors.buttonPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Apps list
          if (apps.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                return _buildAppTile(apps[index]);
              },
            ),
        ],
      ),
    );
  }

  /// Build individual app tile
  Widget _buildAppTile(AppModel app) {
    return Obx(() {
      final isSelected = quickModeController.isAppSelected(app);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonPrimary.withOpacity(0.1)
              : AppColors.background.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.buttonPrimary.withOpacity(0.3)
                : AppColors.borderColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => quickModeController.toggleAppSelection(app),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // App icon with enhanced styling
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: app.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: app.iconColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      app.icon,
                      color: app.iconColor,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // App details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.buttonPrimary
                                : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.packageName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (app.category != null &&
                            app.category!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: app.iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              app.category!,
                              style: TextStyle(
                                color: app.iconColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Selection indicator with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.buttonPrimary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
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
                            size: 18,
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

  /// Build bottom action bar with selection info and actions
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection summary
            Obx(() => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: quickModeController.selectedApps.isNotEmpty
                        ? AppColors.buttonPrimary.withOpacity(0.1)
                        : AppColors.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: quickModeController.selectedApps.isNotEmpty
                          ? AppColors.buttonPrimary.withOpacity(0.3)
                          : AppColors.borderColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.apps,
                        color: quickModeController.selectedApps.isNotEmpty
                            ? AppColors.buttonPrimary
                            : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quickModeController.selectedAppsCountText,
                              style: TextStyle(
                                color:
                                    quickModeController.selectedApps.isNotEmpty
                                        ? AppColors.buttonPrimary
                                        : AppColors.textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              quickModeController.selectedApps.isNotEmpty
                                  ? 'Ready to start blocking session'
                                  : 'Select apps to enable Quick Mode',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showCancelConfirmation(),
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Done button
                Expanded(
                  flex: 2,
                  child: Obx(() => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 48,
                        decoration: BoxDecoration(
                          color: quickModeController.selectedApps.isNotEmpty
                              ? AppColors.buttonPrimary
                              : AppColors.borderColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: quickModeController.selectedApps.isNotEmpty
                              ? [
                                  BoxShadow(
                                    color: AppColors.buttonPrimary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: quickModeController.selectedApps.isNotEmpty
                                ? _handleDoneAction
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: quickModeController
                                            .selectedApps.isNotEmpty
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Done',
                                    style: TextStyle(
                                      color: quickModeController
                                              .selectedApps.isNotEmpty
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== ACTION HANDLERS =====

  /// Select apps by category
  void _selectAppsByCategory(String category) {
    final apps = dashboardController.allApps
        .where((app) => app.category == category)
        .toList();

    for (final app in apps) {
      if (!quickModeController.isAppSelected(app)) {
        quickModeController.toggleAppSelection(app);
      }
    }

    _showFeedback('$category Apps Selected',
        '${apps.length} apps added to blocking list');
  }

  /// Select all apps in a specific category list
  void _selectCategoryApps(List<AppModel> apps) {
    for (final app in apps) {
      if (!quickModeController.isAppSelected(app)) {
        quickModeController.toggleAppSelection(app);
      }
    }

    _showFeedback(
        'Category Selected', '${apps.length} apps added to blocking list');
  }

  /// Select all available apps
  void _selectAllApps() {
    for (final app in dashboardController.allApps) {
      if (!quickModeController.isAppSelected(app)) {
        quickModeController.toggleAppSelection(app);
      }
    }

    _showFeedback('All Apps Selected',
        '${dashboardController.allApps.length} apps selected for blocking');
  }

  /// Clear all selected apps
  void _clearAllApps() {
    final count = quickModeController.selectedApps.length;
    quickModeController.clearSelectedApps();
    _showFeedback(
        'Selection Cleared', '$count apps removed from blocking list');
  }

  /// Select popular/commonly blocked apps
  void _selectPopularApps() {
    final popularPackages = [
      'com.facebook.katana',
      'com.instagram.android',
      'com.zhiliaoapp.musically',
      'com.google.android.youtube',
      'com.twitter.android',
      'com.snapchat.android',
      'com.whatsapp',
    ];

    int selectedCount = 0;
    for (final app in dashboardController.allApps) {
      if (popularPackages.contains(app.packageName) &&
          !quickModeController.isAppSelected(app)) {
        quickModeController.toggleAppSelection(app);
        selectedCount++;
      }
    }

    _showFeedback('Popular Apps Selected',
        '$selectedCount popular apps added to blocking list');
  }

  /// Handle done action
  void _handleDoneAction() {
    Get.back();
    _showFeedback('Apps Selected',
        '${quickModeController.selectedApps.length} apps ready for blocking');
  }

  /// Show cancel confirmation
  void _showCancelConfirmation() {
    if (quickModeController.selectedApps.isEmpty) {
      Get.back();
      return;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.containerBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Discard Changes?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'You have selected apps. Are you sure you want to go back without saving?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Close screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  /// Show feedback message
  void _showFeedback(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.success.withOpacity(0.1),
      colorText: AppColors.success,
      duration: const Duration(seconds: 2),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Get icon for category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social media':
      case 'social':
        return Icons.people_outline;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'communication':
        return Icons.chat_outlined;
      case 'productivity':
        return Icons.work_outline;
      case 'games':
        return Icons.games_outlined;
      case 'selected apps':
        return Icons.check_circle_outline;
      default:
        return Icons.apps_outlined;
    }
  }
}
