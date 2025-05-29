// features/analysis/controller/analysis_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/models/app_model.dart';

enum AnalysisFilter { day, week, month }

class AnalysisController extends GetxController {
  // Observable variables
  var selectedFilter = AnalysisFilter.day.obs;
  var selectedDate = DateTime.now().obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Screen time data
  var totalScreenTime = Duration.zero.obs;
  var dailyAverage = Duration.zero.obs;
  var weeklyTotal = Duration.zero.obs;
  var screenTimeChange = 0.obs; // percentage change from previous period

  // Chart data
  var screenTimeChartData = <ChartData>[].obs;
  var appUsageData = <AppUsageData>[].obs;
  var weeklyChartData = <ChartData>[].obs;

  // Top apps data
  var topApps = <AppUsageData>[].obs;
  var topIncreaseApps = <AppUsageData>[].obs;
  var topDecreaseApps = <AppUsageData>[].obs;

  // Date navigation
  var currentWeekStart = DateTime.now().obs;
  var currentWeekEnd = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    loadAnalysisData();
  }

  void _initializeData() {
    final now = DateTime.now();
    selectedDate.value = now;

    // Calculate week start and end
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    currentWeekStart.value =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    currentWeekEnd.value = currentWeekStart.value.add(const Duration(days: 6));
  }

  Future<void> loadAnalysisData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));

      switch (selectedFilter.value) {
        case AnalysisFilter.day:
          await _loadDayAnalysis();
          break;
        case AnalysisFilter.week:
          await _loadWeekAnalysis();
          break;
        case AnalysisFilter.month:
          await _loadMonthAnalysis();
          break;
      }
    } catch (e) {
      errorMessage.value = 'Failed to load analysis data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadDayAnalysis() async {
    // Generate sample daily data
    totalScreenTime.value = const Duration(hours: 7, minutes: 24);
    dailyAverage.value = const Duration(hours: 6, minutes: 45);
    screenTimeChange.value = 12; // 12% increase from yesterday

    // Generate hourly chart data
    screenTimeChartData.value = _generateHourlyData();

    // Generate app usage data
    appUsageData.value = _generateAppUsageData();
    topApps.value = appUsageData.take(4).toList();
  }

  Future<void> _loadWeekAnalysis() async {
    // Generate sample weekly data
    weeklyTotal.value = const Duration(hours: 52, minutes: 30);
    dailyAverage.value = const Duration(hours: 7, minutes: 24);
    screenTimeChange.value = -2; // 2% decrease from last week

    // Generate weekly chart data
    weeklyChartData.value = _generateWeeklyData();

    // Generate app usage data
    appUsageData.value = _generateAppUsageData();
    topApps.value = appUsageData.take(4).toList();

    // Generate increase/decrease data
    topIncreaseApps.value = _generateIncreaseDecreaseData(true);
    topDecreaseApps.value = _generateIncreaseDecreaseData(false);
  }

  Future<void> _loadMonthAnalysis() async {
    // Generate sample monthly data
    totalScreenTime.value = const Duration(hours: 210, minutes: 15);
    dailyAverage.value = const Duration(hours: 6, minutes: 58);
    screenTimeChange.value = 5; // 5% increase from last month

    // Generate monthly chart data
    screenTimeChartData.value = _generateMonthlyData();

    // Generate app usage data
    appUsageData.value = _generateAppUsageData();
    topApps.value = appUsageData.take(4).toList();
  }

  List<ChartData> _generateHourlyData() {
    // Generate realistic hourly usage pattern
    final hours = ['12am', '6am', '12pm', '6pm'];
    final values = [0.5, 2.0, 4.5, 3.0, 2.5, 1.0]; // Hours of usage

    return List.generate(24, (index) {
      double value;
      if (index < 6) {
        value = 0.5 + (index * 0.2); // Early morning
      } else if (index < 12)
        value = 1.0 + (index - 6) * 0.3; // Morning
      else if (index < 18)
        value = 4.0 - (index - 12) * 0.2; // Afternoon
      else
        value = 2.0 + (index - 18) * 0.1; // Evening

      return ChartData(
        label: '$index:00',
        value: value + (index % 3 == 0 ? 0.5 : 0), // Add some variation
        hour: index,
      );
    });
  }

  List<ChartData> _generateWeeklyData() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [6.5, 7.2, 8.1, 7.8, 9.2, 5.4, 4.8]; // Hours per day

    return List.generate(7, (index) {
      return ChartData(
        label: days[index],
        value: values[index],
        day: index,
      );
    });
  }

  List<ChartData> _generateMonthlyData() {
    // Generate 30 days of data
    return List.generate(30, (index) {
      final day = index + 1;
      final baseValue = 6.0 + (day % 7) * 0.5; // Weekly pattern
      final randomVariation = (day % 3 == 0 ? 1.0 : -0.5);

      return ChartData(
        label: day.toString(),
        value: (baseValue + randomVariation).clamp(2.0, 12.0),
        day: day,
      );
    });
  }

  List<AppUsageData> _generateAppUsageData() {
    final sampleApps = [
      AppUsageData(
        app: AppModel(
          name: 'Facebook',
          packageName: 'com.facebook.katana',
          icon: Icons.facebook,
          iconColor: const Color(0xFF1877F2),
          id: '',
        ),
        duration: const Duration(hours: 7, minutes: 30),
        percentage: 35.2,
        sessions: 24,
        change: 15,
      ),
      AppUsageData(
        app: AppModel(
          name: 'WhatsApp',
          packageName: 'com.whatsapp',
          icon: Icons.message,
          iconColor: const Color(0xFF25D366),
          id: '',
        ),
        duration: const Duration(hours: 3),
        percentage: 14.1,
        sessions: 45,
        change: -5,
      ),
      AppUsageData(
        app: AppModel(
          name: 'Pinterest',
          packageName: 'com.pinterest',
          icon: Icons.interests,
          iconColor: const Color(0xFFE60023),
          id: '',
        ),
        duration: const Duration(minutes: 52),
        percentage: 4.1,
        sessions: 8,
        change: 22,
      ),
      AppUsageData(
        app: AppModel(
          name: 'Spotify',
          packageName: 'com.spotify.music',
          icon: Icons.music_note,
          iconColor: const Color(0xFF1DB954),
          id: '',
        ),
        duration: const Duration(minutes: 11),
        percentage: 0.9,
        sessions: 3,
        change: -12,
      ),
      AppUsageData(
        app: AppModel(
          name: 'LinkedIn',
          packageName: 'com.linkedin.android',
          icon: Icons.work,
          iconColor: const Color(0xFF0077B5),
          id: '',
        ),
        duration: const Duration(minutes: 11),
        percentage: 0.9,
        sessions: 5,
        change: 8,
      ),
      AppUsageData(
        app: AppModel(
          name: 'Instagram',
          packageName: 'com.instagram.android',
          icon: Icons.camera_alt,
          iconColor: const Color(0xFFE4405F),
          id: '',
        ),
        duration: const Duration(hours: 2, minutes: 15),
        percentage: 10.5,
        sessions: 18,
        change: 25,
      ),
      AppUsageData(
        app: AppModel(
          name: 'YouTube',
          packageName: 'com.google.android.youtube',
          icon: Icons.play_arrow,
          iconColor: const Color(0xFFFF0000),
          id: '',
        ),
        duration: const Duration(hours: 1, minutes: 45),
        percentage: 8.2,
        sessions: 12,
        change: -8,
      ),
    ];

    // Sort by duration (descending)
    sampleApps
        .sort((a, b) => b.duration.inMinutes.compareTo(a.duration.inMinutes));
    return sampleApps;
  }

  List<AppUsageData> _generateIncreaseDecreaseData(bool isIncrease) {
    final allApps = _generateAppUsageData();

    if (isIncrease) {
      // Filter apps with positive change and sort by change percentage
      return allApps.where((app) => app.change > 0).toList()
        ..sort((a, b) => b.change.compareTo(a.change));
    } else {
      // Filter apps with negative change and sort by absolute change
      return allApps.where((app) => app.change < 0).toList()
        ..sort((a, b) => a.change.compareTo(b.change));
    }
  }

  // Filter change methods
  void setFilter(AnalysisFilter filter) {
    if (selectedFilter.value != filter) {
      selectedFilter.value = filter;
      loadAnalysisData();
    }
  }

  // Date navigation methods
  void navigateToPreviousDate() {
    switch (selectedFilter.value) {
      case AnalysisFilter.day:
        selectedDate.value =
            selectedDate.value.subtract(const Duration(days: 1));
        break;
      case AnalysisFilter.week:
        currentWeekStart.value =
            currentWeekStart.value.subtract(const Duration(days: 7));
        currentWeekEnd.value =
            currentWeekStart.value.add(const Duration(days: 6));
        break;
      case AnalysisFilter.month:
        selectedDate.value = DateTime(
          selectedDate.value.year,
          selectedDate.value.month - 1,
          selectedDate.value.day,
        );
        break;
    }
    loadAnalysisData();
  }

  void navigateToNextDate() {
    final now = DateTime.now();

    switch (selectedFilter.value) {
      case AnalysisFilter.day:
        final nextDay = selectedDate.value.add(const Duration(days: 1));
        if (nextDay.isBefore(now.add(const Duration(days: 1)))) {
          selectedDate.value = nextDay;
          loadAnalysisData();
        }
        break;
      case AnalysisFilter.week:
        final nextWeek = currentWeekStart.value.add(const Duration(days: 7));
        if (nextWeek.isBefore(now)) {
          currentWeekStart.value = nextWeek;
          currentWeekEnd.value =
              currentWeekStart.value.add(const Duration(days: 6));
          loadAnalysisData();
        }
        break;
      case AnalysisFilter.month:
        final nextMonth = DateTime(
          selectedDate.value.year,
          selectedDate.value.month + 1,
          selectedDate.value.day,
        );
        if (nextMonth.isBefore(now)) {
          selectedDate.value = nextMonth;
          loadAnalysisData();
        }
        break;
    }
  }

  // Utility methods
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String getDateRangeText() {
    switch (selectedFilter.value) {
      case AnalysisFilter.day:
        return _formatDate(selectedDate.value);
      case AnalysisFilter.week:
        return '${_formatDate(currentWeekStart.value)} - ${_formatDate(currentWeekEnd.value)}';
      case AnalysisFilter.month:
        return '${_getMonthName(selectedDate.value.month)} ${selectedDate.value.year}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day} ${_getMonthName(date.month).substring(0, 3)} ${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  bool canNavigateNext() {
    final now = DateTime.now();

    switch (selectedFilter.value) {
      case AnalysisFilter.day:
        return selectedDate.value
            .isBefore(DateTime(now.year, now.month, now.day));
      case AnalysisFilter.week:
        return currentWeekStart.value
            .isBefore(now.subtract(Duration(days: now.weekday - 1)));
      case AnalysisFilter.month:
        return selectedDate.value.isBefore(DateTime(now.year, now.month));
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadAnalysisData();
  }
}

// Data models
class ChartData {
  final String label;
  final double value;
  final int? hour;
  final int? day;

  ChartData({
    required this.label,
    required this.value,
    this.hour,
    this.day,
  });
}

class AppUsageData {
  final AppModel app;
  final Duration duration;
  final double percentage;
  final int sessions;
  final int change; // Percentage change from previous period

  AppUsageData({
    required this.app,
    required this.duration,
    required this.percentage,
    required this.sessions,
    required this.change,
  });
}
