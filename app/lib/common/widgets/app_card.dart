import 'package:flutter/material.dart';
import '../../utils/constants/app_colors.dart';

class AppCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String appName;
  final bool isSelected;
  final VoidCallback onTap;

  const AppCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.appName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonPrimary.withOpacity(0.2)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.buttonPrimary
                : AppColors.borderColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(
                icon,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                appName,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? AppColors.buttonPrimary
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
