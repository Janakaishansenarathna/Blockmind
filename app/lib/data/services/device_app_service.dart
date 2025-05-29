import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

import '../local/models/app_model.dart';

class DeviceAppService {
  static final DeviceAppService _instance = DeviceAppService._internal();

  factory DeviceAppService() {
    return _instance;
  }

  DeviceAppService._internal();

  // Get all installed apps from the device
  Future<List<AppModel>> getInstalledApps() async {
    // Get all installed apps with icons
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );

    // Convert to our AppModel
    return apps.map((app) {
      // Access app icon through the ApplicationWithIcon class
      final appWithIcon = app as ApplicationWithIcon;

      // Convert app icon to widget
      final iconWidget = Image.memory(appWithIcon.icon);

      // Generate a color based on the app name for consistent colors
      final color = _generateColorFromString(app.appName);

      // Create an AppModel
      return AppModel(
        id: app.packageName,
        name: app.appName,
        packageName: app.packageName,
        // We'll use placeholder icons since we can't directly convert to IconData
        icon: _getIconForPackage(app.packageName),
        iconColor: color,
      );
    }).toList();
  }

  // Get specific app information
  Future<AppModel?> getAppInfo(String packageName) async {
    bool isInstalled = await DeviceApps.isAppInstalled(packageName);

    if (!isInstalled) return null;

    Application? app = await DeviceApps.getApp(packageName, true);
    if (app == null) return null;

    final appWithIcon = app as ApplicationWithIcon;
    final color = _generateColorFromString(app.appName);

    return AppModel(
      id: app.packageName,
      name: app.appName,
      packageName: app.packageName,
      icon: _getIconForPackage(app.packageName),
      iconColor: color,
    );
  }

  // Launch an app
  Future<bool> launchApp(String packageName) async {
    return await DeviceApps.openApp(packageName);
  }

  // Get icon for common package names or fallback to default
  IconData _getIconForPackage(String packageName) {
    Map<String, IconData> knownApps = {
      'com.facebook.katana': Icons.facebook,
      'com.instagram.android': Icons.camera_alt,
      'com.whatsapp': Icons.chat,
      'com.google.android.youtube': Icons.play_circle_fill,
      'com.twitter.android': Icons.public,
      'com.zhiliaoapp.musically': Icons.music_note,
      'com.snapchat.android': Icons.camera,
      'com.pinterest': Icons.push_pin,
      'com.linkedin.android': Icons.work,
      'com.reddit.frontpage': Icons.forum,
      'com.discord': Icons.headset_mic,
      'com.spotify.music': Icons.music_note,
    };

    return knownApps[packageName] ?? Icons.android;
  }

  // Generate a color based on the string
  Color _generateColorFromString(String input) {
    // Simple hash function for the string
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Convert to a color
    return Color.fromARGB(
      255,
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
    );
  }
}
