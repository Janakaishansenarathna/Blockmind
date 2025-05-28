// features/schedule/widgets/app_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/schedule_controller.dart';

class AppSelectionDialog extends StatefulWidget {
  final ScheduleController controller;

  const AppSelectionDialog({
    super.key,
    required this.controller,
  });

  @override
  State<AppSelectionDialog> createState() => _AppSelectionDialogState();
}

class _AppSelectionDialogState extends State<AppSelectionDialog> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Search bar
            _buildSearchBar(),

            // Quick selection buttons
            _buildQuickSelectionButtons(),

            // Apps list
            Expanded(
              child: _buildAppsList(),
            ),

            // Bottom actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.apps,
            color: AppColors.buttonPrimary,
            size: 24,
          ),
          const SizedBox(width: 12),
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
                  'Choose which apps to block during this schedule',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.buttonPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.controller.selectedAppIds.length}',
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) => widget.controller.searchApps(value),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Search apps...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.iconSecondary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSelectionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickButton(
              'Popular Apps',
              Icons.star,
              () => _selectPopularApps(),
            ),
            const SizedBox(width: 8),
            _buildQuickButton(
              'Social Media',
              Icons.people,
              () => _selectSocialMediaApps(),
            ),
            const SizedBox(width: 8),
            _buildQuickButton(
              'All Apps',
              Icons.select_all,
              () => _selectAllApps(),
            ),
            const SizedBox(width: 8),
            _buildQuickButton(
              'Clear All',
              Icons.clear,
              () => widget.controller.selectedAppIds.clear(),
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: (color ?? AppColors.buttonPrimary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (color ?? AppColors.buttonPrimary).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? AppColors.buttonPrimary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? AppColors.buttonPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsList() {
    return Obx(() {
      final apps = widget.controller.filteredApps;

      if (apps.isEmpty) {
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

      // Group apps by category
      final Map<String, List<dynamic>> categorizedApps = {};
      for (final app in apps) {
        final category = app.category ?? 'Other';
        if (!categorizedApps.containsKey(category)) {
          categorizedApps[category] = [];
        }
        categorizedApps[category]!.add(app);
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categorizedApps.length,
        itemBuilder: (context, index) {
          final category = categorizedApps.keys.elementAt(index);
          final categoryApps = categorizedApps[category]!;

          return _buildCategorySection(category, categoryApps);
        },
      );
    });
  }

  Widget _buildCategorySection(String category, List apps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  for (final app in apps) {
                    if (!widget.controller.isAppSelected(app.id)) {
                      widget.controller.toggleAppSelection(app.id);
                    }
                  }
                },
                child: const Text(
                  'Select All',
                  style: TextStyle(
                    color: AppColors.buttonPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...apps.map((app) => _buildAppTile(app)).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAppTile(app) {
    return Obx(() {
      final isSelected = widget.controller.isAppSelected(app.id);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonPrimary.withOpacity(0.1)
              : AppColors.background.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.buttonPrimary.withOpacity(0.3)
                : AppColors.borderColor.withOpacity(0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.controller.toggleAppSelection(app.id),
            borderRadius: BorderRadius.circular(12),
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

                  // App name
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

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.borderColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Done button
          Expanded(
            child: Obx(() => ElevatedButton(
                  onPressed: widget.controller.selectedAppIds.isEmpty
                      ? null
                      : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    disabledBackgroundColor: AppColors.borderColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.controller.selectedAppIds.isEmpty
                        ? 'Select Apps'
                        : 'Done (${widget.controller.selectedAppIds.length})',
                    style: TextStyle(
                      color: widget.controller.selectedAppIds.isEmpty
                          ? AppColors.textMuted
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  void _selectPopularApps() {
    final popularPackages = [
      'com.facebook.katana',
      'com.instagram.android',
      'com.google.android.youtube',
      'com.whatsapp',
      'com.twitter.android',
      'com.zhiliaoapp.musically',
      'com.snapchat.android',
    ];

    for (final app in widget.controller.availableApps) {
      if (popularPackages.contains(app.packageName)) {
        if (!widget.controller.isAppSelected(app.id)) {
          widget.controller.toggleAppSelection(app.id);
        }
      }
    }
  }

  void _selectSocialMediaApps() {
    for (final app in widget.controller.availableApps) {
      if (app.category == 'Social Media' &&
          !widget.controller.isAppSelected(app.id)) {
        widget.controller.toggleAppSelection(app.id);
      }
    }
  }

  void _selectAllApps() {
    for (final app in widget.controller.availableApps) {
      if (!widget.controller.isAppSelected(app.id)) {
        widget.controller.toggleAppSelection(app.id);
      }
    }
  }
}
