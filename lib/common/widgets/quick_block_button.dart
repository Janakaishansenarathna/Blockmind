import 'package:flutter/material.dart';
import '../../utils/constants/app_colors.dart';

class QuickBlockButton extends StatelessWidget {
  final bool isActive;
  final IconData? icon;
  final String label;
  final VoidCallback onPressed;

  const QuickBlockButton({
    super.key,
    this.isActive = false,
    this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? AppColors.error : AppColors.buttonPrimary,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
