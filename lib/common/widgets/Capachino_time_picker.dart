import 'package:flutter/cupertino.dart';
import '../../utils/constants/app_colors.dart';

class CupertinoTimerPicker extends StatelessWidget {
  final CupertinoTimerPickerMode mode;
  final Duration initialTimerDuration;
  final ValueChanged<Duration> onTimerDurationChanged;

  const CupertinoTimerPicker({
    super.key,
    required this.mode,
    required this.initialTimerDuration,
    required this.onTimerDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    // This is a simplified mock of iOS-style timer picker
    // In a real app, you'd use the actual CupertinoTimerPicker from Flutter

    final hours = List.generate(24, (index) => index);
    final minutes = List.generate(60, (index) => index);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hours column
        Expanded(
          child: ListWheelScrollView(
            itemExtent: 50,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            children:
                hours.map((hour) {
                  return Center(
                    child: Text(
                      hour.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            hour == initialTimerDuration.inHours
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            hour == initialTimerDuration.inHours
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
            onSelectedItemChanged: (index) {
              final newDuration = Duration(
                hours: index,
                minutes: initialTimerDuration.inMinutes % 60,
              );
              onTimerDurationChanged(newDuration);
            },
          ),
        ),
        const Text(
          ':',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // Minutes column
        Expanded(
          child: ListWheelScrollView(
            itemExtent: 50,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            children:
                minutes.map((minute) {
                  return Center(
                    child: Text(
                      minute.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            minute == initialTimerDuration.inMinutes % 60
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            minute == initialTimerDuration.inMinutes % 60
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
            onSelectedItemChanged: (index) {
              final newDuration = Duration(
                hours: initialTimerDuration.inHours,
                minutes: index,
              );
              onTimerDurationChanged(newDuration);
            },
          ),
        ),
      ],
    );
  }
}
