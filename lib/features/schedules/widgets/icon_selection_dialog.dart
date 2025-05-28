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
    final List<Map<String, dynamic>> iconOptions = [
      // Education & Work
      {'icon': Icons.school, 'color': Colors.blue, 'name': 'School'},
      {'icon': Icons.work, 'color': Colors.orange, 'name': 'Work'},
      {'icon': Icons.business, 'color': Colors.teal, 'name': 'Business'},
      {'icon': Icons.laptop, 'color': Colors.indigo, 'name': 'Laptop'},

      // Time & Schedule
      {
        'icon': Icons.nightlight_round,
        'color': Colors.deepPurple,
        'name': 'Night'
      },
      {'icon': Icons.wb_sunny, 'color': Colors.amber, 'name': 'Morning'},
      {'icon': Icons.schedule, 'color': Colors.green, 'name': 'Schedule'},
      {'icon': Icons.alarm, 'color': Colors.red, 'name': 'Alarm'},

      // Activities
      {'icon': Icons.fitness_center, 'color': Colors.green, 'name': 'Exercise'},
      {'icon': Icons.book, 'color': Colors.purple, 'name': 'Reading'},
      {'icon': Icons.music_note, 'color': Colors.pink, 'name': 'Music'},
      {'icon': Icons.movie, 'color': Colors.red, 'name': 'Movie'},

      // Social & Family
      {'icon': Icons.family_restroom, 'color': Colors.cyan, 'name': 'Family'},
      {'icon': Icons.people, 'color': Colors.blue, 'name': 'Social'},
      {'icon': Icons.groups, 'color': Colors.teal, 'name': 'Groups'},
      {'icon': Icons.favorite, 'color': Colors.red, 'name': 'Love'},

      // Food & Lifestyle
      {'icon': Icons.restaurant, 'color': Colors.orange, 'name': 'Dining'},
      {'icon': Icons.coffee, 'color': Colors.brown, 'name': 'Coffee'},
      {'icon': Icons.local_dining, 'color': Colors.green, 'name': 'Food'},
      {'icon': Icons.cake, 'color': Colors.pink, 'name': 'Dessert'},

      // Wellness & Mindfulness
      {
        'icon': Icons.self_improvement,
        'color': Colors.deepPurple,
        'name': 'Meditation'
      },
      {'icon': Icons.spa, 'color': Colors.green, 'name': 'Wellness'},
      {'icon': Icons.psychology, 'color': Colors.blue, 'name': 'Mind'},
      {'icon': Icons.mood, 'color': Colors.yellow, 'name': 'Mood'},

      // Productivity
      {'icon': Icons.task_alt, 'color': Colors.green, 'name': 'Tasks'},
      {'icon': Icons.trending_up, 'color': Colors.blue, 'name': 'Growth'},
      {'icon': Icons.timer, 'color': Colors.orange, 'name': 'Timer'},
      {'icon': Icons.lightbulb, 'color': Colors.amber, 'name': 'Ideas'},

      // Hobbies
      {'icon': Icons.sports_esports, 'color': Colors.purple, 'name': 'Gaming'},
      {'icon': Icons.palette, 'color': Colors.red, 'name': 'Art'},
      {'icon': Icons.camera_alt, 'color': Colors.blue, 'name': 'Photo'},
      {'icon': Icons.headphones, 'color': Colors.indigo, 'name': 'Audio'},
    ];

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.containerBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.palette,
                    color: AppColors.buttonPrimary,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Choose Icon & Color',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Icon grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: iconOptions.length,
                itemBuilder: (context, index) {
                  final option = iconOptions[index];
                  return _buildIconOption(
                    context,
                    option['icon'] as IconData,
                    option['color'] as Color,
                    option['name'] as String,
                  );
                },
              ),
            ),

            // Cancel button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconOption(
    BuildContext context,
    IconData icon,
    Color color,
    String name,
  ) {
    return GestureDetector(
      onTap: () {
        onIconSelected(icon, color);
        Navigator.pop(context);
      },
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
