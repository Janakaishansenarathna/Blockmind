import 'package:flutter/material.dart';
import '../../utils/constants/app_colors.dart';

class AppSelectionList extends StatelessWidget {
  final List<Map<String, dynamic>> availableApps;
  final List<String> selectedApps;
  final Function(String) onAppToggle;

  const AppSelectionList({
    super.key,
    required this.availableApps,
    required this.selectedApps,
    required this.onAppToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: availableApps.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 56,
        ),
        itemBuilder: (context, index) {
          final app = availableApps[index];
          final isSelected = selectedApps.contains(app['name']);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: app['iconColor'].withOpacity(0.2),
              child: Icon(
                app['icon'],
                color: app['iconColor'],
              ),
            ),
            title: Text(
              app['name'],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? AppColors.buttonPrimary
                  : AppColors.textSecondary,
            ),
            onTap: () => onAppToggle(app['name']),
          );
        },
      ),
    );
  }
}
