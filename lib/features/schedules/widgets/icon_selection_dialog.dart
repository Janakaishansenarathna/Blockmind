// features/schedule/widgets/icon_selection_dialog.dart
import 'package:flutter/material.dart';
import '../../../utils/constants/app_colors.dart';

class IconSelectionDialog extends StatelessWidget {
  final Function(IconData, Color) onIconSelected;

  const IconSelectionDialog({
    super.key,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    final List<Map<String, dynamic>> iconOptions = [
      // Education & Work
      {
        'icon': Icons.school,
        'color': Colors.blue,
        'name': 'School',
        'category': 'Education'
      },
      {
        'icon': Icons.work,
        'color': Colors.orange,
        'name': 'Work',
        'category': 'Education'
      },
      {
        'icon': Icons.business,
        'color': Colors.teal,
        'name': 'Business',
        'category': 'Education'
      },
      {
        'icon': Icons.laptop,
        'color': Colors.indigo,
        'name': 'Laptop',
        'category': 'Education'
      },
      {
        'icon': Icons.library_books,
        'color': Colors.deepOrange,
        'name': 'Study',
        'category': 'Education'
      },
      {
        'icon': Icons.edit,
        'color': Colors.blueGrey,
        'name': 'Write',
        'category': 'Education'
      },

      // Time & Schedule
      {
        'icon': Icons.nightlight_round,
        'color': Colors.deepPurple,
        'name': 'Night',
        'category': 'Time'
      },
      {
        'icon': Icons.wb_sunny,
        'color': Colors.amber,
        'name': 'Morning',
        'category': 'Time'
      },
      {
        'icon': Icons.schedule,
        'color': Colors.green,
        'name': 'Schedule',
        'category': 'Time'
      },
      {
        'icon': Icons.alarm,
        'color': Colors.red,
        'name': 'Alarm',
        'category': 'Time'
      },
      {
        'icon': Icons.bedtime,
        'color': Colors.indigo,
        'name': 'Sleep',
        'category': 'Time'
      },
      {
        'icon': Icons.access_time,
        'color': Colors.blue,
        'name': 'Time',
        'category': 'Time'
      },

      // Activities & Fitness
      {
        'icon': Icons.fitness_center,
        'color': Colors.green,
        'name': 'Exercise',
        'category': 'Activities'
      },
      {
        'icon': Icons.directions_run,
        'color': Colors.orange,
        'name': 'Running',
        'category': 'Activities'
      },
      {
        'icon': Icons.sports_soccer,
        'color': Colors.green,
        'name': 'Sports',
        'category': 'Activities'
      },
      {
        'icon': Icons.pool,
        'color': Colors.blue,
        'name': 'Swimming',
        'category': 'Activities'
      },
      {
        'icon': Icons.self_improvement,
        'color': Colors.deepPurple,
        'name': 'Yoga',
        'category': 'Activities'
      },
      {
        'icon': Icons.directions_bike,
        'color': Colors.teal,
        'name': 'Cycling',
        'category': 'Activities'
      },

      // Entertainment & Media
      {
        'icon': Icons.book,
        'color': Colors.purple,
        'name': 'Reading',
        'category': 'Entertainment'
      },
      {
        'icon': Icons.music_note,
        'color': Colors.pink,
        'name': 'Music',
        'category': 'Entertainment'
      },
      {
        'icon': Icons.movie,
        'color': Colors.red,
        'name': 'Movie',
        'category': 'Entertainment'
      },
      {
        'icon': Icons.sports_esports,
        'color': Colors.purple,
        'name': 'Gaming',
        'category': 'Entertainment'
      },
      {
        'icon': Icons.tv,
        'color': Colors.blueGrey,
        'name': 'TV',
        'category': 'Entertainment'
      },
      {
        'icon': Icons.headphones,
        'color': Colors.indigo,
        'name': 'Audio',
        'category': 'Entertainment'
      },

      // Social & Family
      {
        'icon': Icons.family_restroom,
        'color': Colors.cyan,
        'name': 'Family',
        'category': 'Social'
      },
      {
        'icon': Icons.people,
        'color': Colors.blue,
        'name': 'Social',
        'category': 'Social'
      },
      {
        'icon': Icons.groups,
        'color': Colors.teal,
        'name': 'Groups',
        'category': 'Social'
      },
      {
        'icon': Icons.favorite,
        'color': Colors.red,
        'name': 'Love',
        'category': 'Social'
      },
      {
        'icon': Icons.celebration,
        'color': Colors.orange,
        'name': 'Party',
        'category': 'Social'
      },
      {
        'icon': Icons.call,
        'color': Colors.green,
        'name': 'Call',
        'category': 'Social'
      },

      // Food & Lifestyle
      {
        'icon': Icons.restaurant,
        'color': Colors.orange,
        'name': 'Dining',
        'category': 'Lifestyle'
      },
      {
        'icon': Icons.coffee,
        'color': Colors.brown,
        'name': 'Coffee',
        'category': 'Lifestyle'
      },
      {
        'icon': Icons.local_dining,
        'color': Colors.green,
        'name': 'Food',
        'category': 'Lifestyle'
      },
      {
        'icon': Icons.cake,
        'color': Colors.pink,
        'name': 'Dessert',
        'category': 'Lifestyle'
      },
      {
        'icon': Icons.shopping_cart,
        'color': Colors.blue,
        'name': 'Shopping',
        'category': 'Lifestyle'
      },
      {
        'icon': Icons.home,
        'color': Colors.teal,
        'name': 'Home',
        'category': 'Lifestyle'
      },

      // Wellness & Health
      {
        'icon': Icons.spa,
        'color': Colors.green,
        'name': 'Wellness',
        'category': 'Health'
      },
      {
        'icon': Icons.psychology,
        'color': Colors.blue,
        'name': 'Mind',
        'category': 'Health'
      },
      {
        'icon': Icons.mood,
        'color': Colors.yellow,
        'name': 'Mood',
        'category': 'Health'
      },
      {
        'icon': Icons.medical_services,
        'color': Colors.red,
        'name': 'Medical',
        'category': 'Health'
      },
      {
        'icon': Icons.healing,
        'color': Colors.purple,
        'name': 'Healing',
        'category': 'Health'
      },
      {
        'icon': Icons.local_hospital,
        'color': Colors.blue,
        'name': 'Hospital',
        'category': 'Health'
      },

      // Productivity & Work
      {
        'icon': Icons.task_alt,
        'color': Colors.green,
        'name': 'Tasks',
        'category': 'Productivity'
      },
      {
        'icon': Icons.trending_up,
        'color': Colors.blue,
        'name': 'Growth',
        'category': 'Productivity'
      },
      {
        'icon': Icons.timer,
        'color': Colors.orange,
        'name': 'Timer',
        'category': 'Productivity'
      },
      {
        'icon': Icons.lightbulb,
        'color': Colors.amber,
        'name': 'Ideas',
        'category': 'Productivity'
      },
      {
        'icon': Icons.checklist,
        'color': Colors.teal,
        'name': 'Checklist',
        'category': 'Productivity'
      },
      {
        'icon': Icons.analytics,
        'color': Colors.indigo,
        'name': 'Analytics',
        'category': 'Productivity'
      },

      // Creative & Hobbies
      {
        'icon': Icons.palette,
        'color': Colors.red,
        'name': 'Art',
        'category': 'Creative'
      },
      {
        'icon': Icons.camera_alt,
        'color': Colors.blue,
        'name': 'Photo',
        'category': 'Creative'
      },
      {
        'icon': Icons.brush,
        'color': Colors.purple,
        'name': 'Paint',
        'category': 'Creative'
      },
      {
        'icon': Icons.theater_comedy,
        'color': Colors.orange,
        'name': 'Theater',
        'category': 'Creative'
      },
      {
        'icon': Icons.design_services,
        'color': Colors.pink,
        'name': 'Design',
        'category': 'Creative'
      },
      {
        'icon': Icons.auto_fix_high,
        'color': Colors.amber,
        'name': 'Magic',
        'category': 'Creative'
      },

      // Travel & Transport
      {
        'icon': Icons.flight,
        'color': Colors.blue,
        'name': 'Travel',
        'category': 'Travel'
      },
      {
        'icon': Icons.directions_car,
        'color': Colors.red,
        'name': 'Drive',
        'category': 'Travel'
      },
      {
        'icon': Icons.train,
        'color': Colors.green,
        'name': 'Train',
        'category': 'Travel'
      },
      {
        'icon': Icons.location_on,
        'color': Colors.red,
        'name': 'Location',
        'category': 'Travel'
      },
      {
        'icon': Icons.explore,
        'color': Colors.orange,
        'name': 'Explore',
        'category': 'Travel'
      },
      {
        'icon': Icons.map,
        'color': Colors.teal,
        'name': 'Map',
        'category': 'Travel'
      },
    ];

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 16,
        vertical: isTablet ? 40 : 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * (isLandscape ? 0.85 : 0.75),
          maxWidth: isTablet ? 600 : screenSize.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(isTablet),

            // Search bar (for large screens)
            if (isTablet || isLandscape) _buildSearchBar(),

            // Icon grid
            Expanded(
              child: _buildIconGrid(
                context,
                iconOptions,
                isTablet,
                isLandscape,
                screenSize,
              ),
            ),

            // Footer with actions
            _buildFooter(context, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: const BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.buttonPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.palette,
              color: AppColors.buttonPrimary,
              size: isTablet ? 28 : 24,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Icon & Color',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isTablet) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Select an icon and color for your schedule',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search icons...',
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.borderColor.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.borderColor.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.buttonPrimary,
            ),
          ),
          filled: true,
          fillColor: AppColors.containerBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(color: AppColors.textPrimary),
        onChanged: (value) {
          // Implement search functionality
        },
      ),
    );
  }

  Widget _buildIconGrid(
    BuildContext context,
    List<Map<String, dynamic>> iconOptions,
    bool isTablet,
    bool isLandscape,
    Size screenSize,
  ) {
    // Calculate responsive grid parameters
    int crossAxisCount;
    double childAspectRatio;
    double spacing;

    if (isTablet) {
      crossAxisCount = isLandscape ? 8 : 6;
      childAspectRatio = 0.9;
      spacing = 16;
    } else if (isLandscape) {
      crossAxisCount = 6;
      childAspectRatio = 0.85;
      spacing = 12;
    } else {
      crossAxisCount = screenSize.width > 360 ? 4 : 3;
      childAspectRatio = 0.8;
      spacing = 12;
    }

    return GridView.builder(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: iconOptions.length,
      itemBuilder: (context, index) {
        final option = iconOptions[index];
        return _buildIconOption(
          context,
          option['icon'] as IconData,
          option['color'] as Color,
          option['name'] as String,
          isTablet,
        );
      },
    );
  }

  Widget _buildIconOption(
    BuildContext context,
    IconData icon,
    Color color,
    String name,
    bool isTablet,
  ) {
    final iconSize = isTablet ? 32.0 : 24.0;
    final containerSize = isTablet ? 56.0 : 48.0;
    final fontSize = isTablet ? 12.0 : 11.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onIconSelected(icon, color);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Info text
          if (isTablet) ...[
            const Expanded(
              child: Text(
                'Tap an icon to select it for your schedule',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Cancel button
          Expanded(
            flex: isTablet ? 0 : 1,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? 16 : 12,
                  horizontal: isTablet ? 32 : 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isTablet ? 16 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
