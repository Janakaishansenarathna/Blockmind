import 'package:flutter/material.dart';

import '../../../utils/themes/gradient_background.dart';

class ActivityReportScreen extends StatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  State<ActivityReportScreen> createState() => _ActivityReportScreenState();
}

class _ActivityReportScreenState extends State<ActivityReportScreen> {
  final List<AppUsageData> appUsageList = [
    AppUsageData(
      appName: 'Facebook',
      iconPath: 'facebook',
      iconColor: Colors.blue,
      blockedHours: 2,
      timestamp: '10:20 AM',
    ),
    AppUsageData(
      appName: 'Whats app',
      iconPath: 'whatsapp',
      iconColor: Colors.green,
      blockedHours: 2,
      timestamp: '10:20 AM',
    ),
    AppUsageData(
      appName: 'Snapchat',
      iconPath: 'snapchat',
      iconColor: Colors.yellow,
      blockedHours: 2,
      timestamp: '10:20 AM',
    ),
    AppUsageData(
      appName: 'Phone',
      iconPath: 'phone',
      iconColor: Colors.green,
      blockedHours: 2,
      timestamp: '10:20 AM',
    ),
    AppUsageData(
      appName: 'Twitter',
      iconPath: 'twitter',
      iconColor: Colors.blue,
      blockedHours: 2,
      timestamp: '10:20 AM',
    ),
    AppUsageData(
      appName: 'Spotify',
      iconPath: 'spotify',
      iconColor: Colors.green,
      blockedHours: 2,
      timestamp: '10:20 AM',
    ),
    AppUsageData(
      appName: 'Line',
      iconPath: 'line',
      iconColor: Colors.green,
      blockedHours: 2,
      timestamp: '10:20 AM',
    ),
    AppUsageData(
      appName: 'Youtube',
      iconPath: 'youtube',
      iconColor: Colors.red,
      blockedHours: 2,
      timestamp: '10:20 AM',
    ),
    AppUsageData(
      appName: 'Youtube',
      iconPath: 'youtube',
      iconColor: Colors.red,
      blockedHours: 2,
      timestamp: '10:20 AM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildAppList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Activity Report',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.white),
                  const SizedBox(width: 6),
                  Container(
                    width: 25,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(1),
                          width: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {},
              ),
              const Text(
                'Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppList() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: appUsageList.length,
      separatorBuilder: (context, index) => const Divider(
        color: Color(0xFF152642),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final app = appUsageList[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildAppIcon(app),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Blocked ${app.blockedHours} hours',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                app.timestamp,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppIcon(AppUsageData app) {
    // Map to associate app names with corresponding icons
    final Map<String, IconData> appIcons = {
      'facebook': Icons.facebook,
      'whatsapp': Icons.chat,
      'snapchat': Icons.camera_alt,
      'phone': Icons.phone,
      'twitter': Icons.flutter_dash,
      'spotify': Icons.music_note,
      'line': Icons.chat,
      'youtube': Icons.play_circle_filled,
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: app.iconColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        appIcons[app.iconPath.toLowerCase()] ?? Icons.app_blocking,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

// Model class for app usage data
class AppUsageData {
  final String appName;
  final String iconPath;
  final Color iconColor;
  final int blockedHours;
  final String timestamp;

  AppUsageData({
    required this.appName,
    required this.iconPath,
    required this.iconColor,
    required this.blockedHours,
    required this.timestamp,
  });
}
