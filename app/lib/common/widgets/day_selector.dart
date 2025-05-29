import 'package:flutter/material.dart';
import '../../utils/constants/app_colors.dart';

class DaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final Function(int) onDaySelected;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> days = [
      {'day': DateTime.monday, 'label': 'M'},
      {'day': DateTime.tuesday, 'label': 'T'},
      {'day': DateTime.wednesday, 'label': 'W'},
      {'day': DateTime.thursday, 'label': 'T'},
      {'day': DateTime.friday, 'label': 'F'},
      {'day': DateTime.saturday, 'label': 'S'},
      {'day': DateTime.sunday, 'label': 'S'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final bool isSelected = selectedDays.contains(day['day']);

        return GestureDetector(
          onTap: () => onDaySelected(day['day']),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: isSelected
                ? AppColors.buttonPrimary
                : AppColors.containerBackground,
            child: Text(
              day['label'],
              style: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
