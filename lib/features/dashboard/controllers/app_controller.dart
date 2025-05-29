// features/dashboard/controllers/app_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/local/database/database_helper.dart';
import '../../../data/local/models/app_model.dart';

class AppController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  final RxList<AppModel> allApps = <AppModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadApps();
  }

  Future<void> loadApps() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get apps from database
      final apps = await _databaseHelper.getAllApps();

      if (apps.isEmpty) {
        // If no apps in database, insert sample apps
        await _insertSampleApps();
        final updatedApps = await _databaseHelper.getAllApps();
        allApps.value = updatedApps;
      } else {
        allApps.value = apps;
      }

      print('Loaded ${allApps.length} apps');
    } catch (e) {
      errorMessage.value = 'Failed to load apps: $e';
      print('Error loading apps: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<AppModel>> getAllApps() async {
    if (allApps.isEmpty) {
      await loadApps();
    }
    return allApps;
  }

  Future<AppModel?> getAppById(String appId) async {
    try {
      return allApps.firstWhere((app) => app.id == appId);
    } catch (e) {
      // Try to get from database
      final apps = await _databaseHelper.getAllApps();
      return apps.firstWhereOrNull((app) => app.id == appId);
    }
  }

  Future<AppModel?> getAppByPackageName(String packageName) async {
    try {
      return allApps.firstWhere((app) => app.packageName == packageName);
    } catch (e) {
      // Try to get from database
      return await _databaseHelper.getAppByPackageName(packageName);
    }
  }

  Future<void> _insertSampleApps() async {
    try {
      print('Inserting sample apps...');

      final sampleApps = _getSampleApps();

      for (final app in sampleApps) {
        await _databaseHelper.insertApp(app);
      }

      print('Sample apps inserted successfully');
    } catch (e) {
      print('Error inserting sample apps: $e');
    }
  }

  List<AppModel> _getSampleApps() {
    return [
      // Social Media
      AppModel(
        id: 'com.facebook.katana',
        name: 'Facebook',
        packageName: 'com.facebook.katana',
        icon: const IconData(0xe255, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF1877F2),
        isBlocked: false,
        isSystemApp: false,
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.instagram.android',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        icon: const IconData(0xe332, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFFE4405F),
        isBlocked: false,
        isSystemApp: false,
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.twitter.android',
        name: 'Twitter',
        packageName: 'com.twitter.android',
        icon: const IconData(0xe8f6, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF1DA1F2),
        isBlocked: false,
        isSystemApp: false,
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.zhiliaoapp.musically',
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        icon: const IconData(0xe6bb, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF000000),
        isBlocked: false,
        isSystemApp: false,
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.snapchat.android',
        name: 'Snapchat',
        packageName: 'com.snapchat.android',
        icon: const IconData(0xe05c, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFFFFFC00),
        isBlocked: false,
        isSystemApp: false,
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.linkedin.android',
        name: 'LinkedIn',
        packageName: 'com.linkedin.android',
        icon: const IconData(0xe8cc, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF0077B5),
        isBlocked: false,
        isSystemApp: false,
        category: 'Social Media',
      ),

      // Communication
      AppModel(
        id: 'com.whatsapp',
        name: 'WhatsApp',
        packageName: 'com.whatsapp',
        icon: const IconData(0xe0b7, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF25D366),
        isBlocked: false,
        isSystemApp: false,
        category: 'Communication',
      ),
      AppModel(
        id: 'com.telegram',
        name: 'Telegram',
        packageName: 'com.telegram',
        icon: const IconData(0xe8db, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF0088CC),
        isBlocked: false,
        isSystemApp: false,
        category: 'Communication',
      ),
      AppModel(
        id: 'com.discord',
        name: 'Discord',
        packageName: 'com.discord',
        icon: const IconData(0xe8f5, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF5865F2),
        isBlocked: false,
        isSystemApp: false,
        category: 'Communication',
      ),

      // Entertainment
      AppModel(
        id: 'com.google.android.youtube',
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        icon: const IconData(0xe8ff, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFFFF0000),
        isBlocked: false,
        isSystemApp: false,
        category: 'Entertainment',
      ),
      AppModel(
        id: 'com.netflix.mediaclient',
        name: 'Netflix',
        packageName: 'com.netflix.mediaclient',
        icon: const IconData(0xe63a, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFFE50914),
        isBlocked: false,
        isSystemApp: false,
        category: 'Entertainment',
      ),
      AppModel(
        id: 'com.spotify.music',
        name: 'Spotify',
        packageName: 'com.spotify.music',
        icon: const IconData(0xe6bb, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF1DB954),
        isBlocked: false,
        isSystemApp: false,
        category: 'Entertainment',
      ),

      // Games
      AppModel(
        id: 'com.supercell.clashofclans',
        name: 'Clash of Clans',
        packageName: 'com.supercell.clashofclans',
        icon: const IconData(0xe8b8, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFFF5C842),
        isBlocked: false,
        isSystemApp: false,
        category: 'Games',
      ),
      AppModel(
        id: 'com.king.candycrushsaga',
        name: 'Candy Crush',
        packageName: 'com.king.candycrushsaga',
        icon: const IconData(0xe861, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFFFF6B00),
        isBlocked: false,
        isSystemApp: false,
        category: 'Games',
      ),
      AppModel(
        id: 'com.mojang.minecraftpe',
        name: 'Minecraft',
        packageName: 'com.mojang.minecraftpe',
        icon: const IconData(0xe861, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF7FC421),
        isBlocked: false,
        isSystemApp: false,
        category: 'Games',
      ),

      // Shopping
      AppModel(
        id: 'com.amazon.mShop.android.shopping',
        name: 'Amazon',
        packageName: 'com.amazon.mShop.android.shopping',
        icon: const IconData(0xe8cb, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFFFF9900),
        isBlocked: false,
        isSystemApp: false,
        category: 'Shopping',
      ),
      AppModel(
        id: 'com.ebay.mobile',
        name: 'eBay',
        packageName: 'com.ebay.mobile',
        icon: const IconData(0xe8cb, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFFE53238),
        isBlocked: false,
        isSystemApp: false,
        category: 'Shopping',
      ),

      // Productivity
      AppModel(
        id: 'com.microsoft.office.outlook',
        name: 'Outlook',
        packageName: 'com.microsoft.office.outlook',
        icon: const IconData(0xe158, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF0078D4),
        isBlocked: false,
        isSystemApp: false,
        category: 'Productivity',
      ),
      AppModel(
        id: 'com.google.android.gm',
        name: 'Gmail',
        packageName: 'com.google.android.gm',
        icon: const IconData(0xe158, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFFEA4335),
        isBlocked: false,
        isSystemApp: false,
        category: 'Productivity',
      ),
      AppModel(
        id: 'com.google.android.apps.docs',
        name: 'Google Drive',
        packageName: 'com.google.android.apps.docs',
        icon: const IconData(0xe2bc, fontFamily: 'MaterialIcons'),
        iconColor: const Color(0xFF4285F4),
        isBlocked: false,
        isSystemApp: false,
        category: 'Productivity',
      ),
    ];
  }

  // Get apps by category
  Map<String, List<AppModel>> getAppsByCategory() {
    final Map<String, List<AppModel>> categorizedApps = {};

    for (final app in allApps) {
      final category = app.category ?? 'Other';
      if (!categorizedApps.containsKey(category)) {
        categorizedApps[category] = [];
      }
      categorizedApps[category]!.add(app);
    }

    return categorizedApps;
  }

  // Refresh apps
  Future<void> refreshApps() async {
    await loadApps();
  }
}
