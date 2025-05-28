import 'package:flutter/material.dart';
import '../../utils/constants/app_colors.dart';

class TimerPicker extends StatelessWidget {
  final Duration initialDuration;
  final Function(Duration) onDurationChanged;

  const TimerPicker({
    super.key,
    required this.initialDuration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Blocked until',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Select end time',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Time picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour picker
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.containerBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  initialDuration.inHours.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Minute picker
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.containerBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (initialDuration.inMinutes % 60).toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Slider
          Slider(
            value: initialDuration.inMinutes.toDouble(),
            min: 1,
            max: 24 * 60, // 24 hours
            activeColor: AppColors.buttonPrimary,
            inactiveColor: AppColors.containerBackground,
            onChanged: (value) {
              final minutes = value.toInt();
              onDurationChanged(Duration(minutes: minutes));
            },
          ),
          // Quick time adjustments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  onDurationChanged(
                      initialDuration - const Duration(minutes: 10));
                },
                child: const Text('-10'),
              ),
              TextButton(
                onPressed: () {
                  onDurationChanged(
                      initialDuration - const Duration(minutes: 1));
                },
                child: const Text('-1'),
              ),
              TextButton(
                onPressed: () {
                  onDurationChanged(
                      initialDuration + const Duration(minutes: 1));
                },
                child: const Text('+1'),
              ),
              TextButton(
                onPressed: () {
                  onDurationChanged(
                      initialDuration + const Duration(minutes: 10));
                },
                child: const Text('+10'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Duration display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_bottom,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Duration : ${initialDuration.inHours}h ${initialDuration.inMinutes % 60}m',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Done button
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, initialDuration);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
