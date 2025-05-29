import 'package:flutter/material.dart';

import '../../../utils/constants/app_colors.dart';

class CustomProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final bool isCompleted;

  const CustomProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.cancel,
                    color: isCompleted ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(value * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    isCompleted ? ' Completed' : ' Incompleted',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.containerBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.success : AppColors.error,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
