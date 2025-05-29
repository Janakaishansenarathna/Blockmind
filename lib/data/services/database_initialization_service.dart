// services/database_initialization_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import '../local/database/database_helper.dart';
import '../local/models/app_model.dart';
import '../local/models/user_model.dart';

class DatabaseInitializationService extends GetxService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  final RxBool isInitialized = false.obs;
  final RxBool isInitializing = false.obs;
  final RxString initializationStatus = 'Not started'.obs;
  final RxString errorMessage = ''.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await initializeDatabase();
  }

  Future<bool> initializeDatabase() async {
    if (isInitialized.value) {
      print('DatabaseInitializationService: Database already initialized');
      return true;
    }

    if (isInitializing.value) {
      print(
          'DatabaseInitializationService: Database initialization already in progress');
      return false;
    }

    try {
      isInitializing.value = true;
      errorMessage.value = '';
      initializationStatus.value = 'Starting initialization...';

      print(
          'DatabaseInitializationService: Starting database initialization...');

      // Step 1: Initialize the database
      initializationStatus.value = 'Creating database...';
      await _databaseHelper.initDatabase();

      // Step 2: Verify tables exist
      initializationStatus.value = 'Verifying tables...';
      await _verifyDatabaseStructure();

      // Step 3: Insert sample data for testing
      initializationStatus.value = 'Setting up sample data...';
      await _insertSampleData();

      // Step 4: Print stats
      initializationStatus.value = 'Finalizing...';
      await _databaseHelper.printDatabaseStats();

      isInitialized.value = true;
      initializationStatus.value = 'Initialization completed successfully';

      print(
          'DatabaseInitializationService: Database initialization completed successfully');
      return true;
    } catch (e) {
      print(
          'DatabaseInitializationService: Database initialization failed: $e');
      errorMessage.value = 'Initialization failed: $e';
      initializationStatus.value = 'Initialization failed';

      // Try to recreate database if initialization fails
      try {
        initializationStatus.value = 'Recreating database...';
        await _databaseHelper.recreateDatabase();

        // Retry verification
        await _verifyDatabaseStructure();
        await _insertSampleData();

        isInitialized.value = true;
        initializationStatus.value = 'Database recreated successfully';
        return true;
      } catch (recreateError) {
        print(
            'DatabaseInitializationService: Database recreation also failed: $recreateError');
        errorMessage.value = 'Database recreation failed: $recreateError';
        initializationStatus.value = 'Failed to recreate database';
        return false;
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> _verifyDatabaseStructure() async {
    print('DatabaseInitializationService: Verifying database structure...');

    // Check if critical tables exist
    final criticalTables = [
      'users',
      'apps',
      'blocked_apps',
      'schedules',
      'quick_blocks',
      'mood_logs',
      'settings'
    ];

    for (final tableName in criticalTables) {
      final exists = await _databaseHelper.tableExists(tableName);
      if (!exists) {
        throw Exception('Critical table "$tableName" does not exist');
      }
      print('DatabaseInitializationService: ✓ Table "$tableName" exists');
    }

    print(
        'DatabaseInitializationService: All critical tables verified successfully');
  }

  Future<void> _insertSampleData() async {
    try {
      print('DatabaseInitializationService: Inserting sample data...');

      // Create sample apps for testing
      final sampleApps = [
        AppModel(
          id: 'com.example.testapp',
          name: 'Test App',
          packageName: 'com.example.testapp',
          icon: const IconData(0xe859, fontFamily: 'MaterialIcons'),
          iconColor: Colors.blue,
          isBlocked: false,
          isSystemApp: false,
          category: 'Other',
        ),
        AppModel(
          id: 'com.facebook.katana',
          name: 'Facebook',
          packageName: 'com.facebook.katana',
          icon: IconData(Icons.facebook.codePoint, fontFamily: 'MaterialIcons'),
          iconColor: const Color(0xFF1877F2),
          isBlocked: false,
          isSystemApp: false,
          category: 'Social Media',
        ),
        AppModel(
          id: 'com.instagram.android',
          name: 'Instagram',
          packageName: 'com.instagram.android',
          icon:
              IconData(Icons.camera_alt.codePoint, fontFamily: 'MaterialIcons'),
          iconColor: const Color(0xFFE4405F),
          isBlocked: false,
          isSystemApp: false,
          category: 'Social Media',
        ),
        AppModel(
          id: 'com.google.android.youtube',
          name: 'YouTube',
          packageName: 'com.google.android.youtube',
          icon: IconData(Icons.play_circle_fill.codePoint,
              fontFamily: 'MaterialIcons'),
          iconColor: const Color(0xFFFF0000),
          isBlocked: false,
          isSystemApp: false,
          category: 'Entertainment',
        ),
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
      ];

      // Insert the sample apps
      for (final app in sampleApps) {
        await _databaseHelper.insertApp(app);
      }

      print(
          'DatabaseInitializationService: ✓ ${sampleApps.length} sample apps inserted');

      // Verify the apps were inserted correctly
      final retrievedApps = await _databaseHelper.getAllApps();
      if (retrievedApps.length < sampleApps.length) {
        throw Exception('Failed to retrieve all inserted sample apps');
      }

      print('DatabaseInitializationService: ✓ Sample app verification passed');

      // Create a sample user
      final sampleUser = UserModel(
        id: 'default_user',
        name: 'Default User',
        email: 'user@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.createOrUpdateUser(sampleUser);
      print('DatabaseInitializationService: ✓ Sample user created');
    } catch (e) {
      print('DatabaseInitializationService: Error inserting sample data: $e');
      // Don't throw here, sample data is not critical for basic functionality
    }
  }

  Future<bool> ensureDatabaseReady() async {
    if (isInitialized.value) {
      return true;
    }

    if (isInitializing.value) {
      // Wait for initialization to complete
      print(
          'DatabaseInitializationService: Waiting for initialization to complete...');
      while (isInitializing.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return isInitialized.value;
    }

    return await initializeDatabase();
  }

  Future<void> resetDatabase() async {
    try {
      initializationStatus.value = 'Resetting database...';
      isInitialized.value = false;

      await _databaseHelper.recreateDatabase();

      // Reinitialize
      await initializeDatabase();

      Get.snackbar(
        'Database Reset',
        'Database has been reset successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('DatabaseInitializationService: Error resetting database: $e');
      errorMessage.value = 'Reset failed: $e';

      Get.snackbar(
        'Reset Failed',
        'Failed to reset database: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> clearAllData() async {
    try {
      initializationStatus.value = 'Clearing all data...';

      await _databaseHelper.clearAllData();

      // Re-insert sample data
      await _insertSampleData();

      Get.snackbar(
        'Data Cleared',
        'All data has been cleared and sample data restored',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      initializationStatus.value = 'Data cleared and restored';
    } catch (e) {
      print('DatabaseInitializationService: Error clearing data: $e');
      errorMessage.value = 'Clear failed: $e';

      Get.snackbar(
        'Clear Failed',
        'Failed to clear data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Helper method to get database stats
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      if (!isInitialized.value) {
        return {};
      }

      final db = await _databaseHelper.database;

      final userCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM users')) ??
          0;
      final appCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM apps')) ??
          0;
      final blockedAppCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM blocked_apps')) ??
          0;
      final scheduleCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM schedules')) ??
          0;
      final quickBlockCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM quick_blocks')) ??
          0;
      final moodLogCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM mood_logs')) ??
          0;

      return {
        'users': userCount,
        'apps': appCount,
        'blockedApps': blockedAppCount,
        'schedules': scheduleCount,
        'quickBlocks': quickBlockCount,
        'moodLogs': moodLogCount,
      };
    } catch (e) {
      print('DatabaseInitializationService: Error getting database stats: $e');
      return {};
    }
  }

  // Method to check database health
  Future<bool> checkDatabaseHealth() async {
    try {
      if (!isInitialized.value) {
        return false;
      }

      // Try to perform a simple query on each critical table
      final db = await _databaseHelper.database;

      await db.rawQuery('SELECT COUNT(*) FROM users LIMIT 1');
      await db.rawQuery('SELECT COUNT(*) FROM apps LIMIT 1');
      await db.rawQuery('SELECT COUNT(*) FROM quick_blocks LIMIT 1');
      await db.rawQuery('SELECT COUNT(*) FROM mood_logs LIMIT 1');

      print('DatabaseInitializationService: Database health check passed');
      return true;
    } catch (e) {
      print('DatabaseInitializationService: Database health check failed: $e');
      return false;
    }
  }

  // Method to force database recreation
  Future<void> forceRecreateDatabase() async {
    try {
      isInitialized.value = false;
      initializationStatus.value = 'Force recreating database...';

      await _databaseHelper.recreateDatabase();
      await initializeDatabase();

      print(
          'DatabaseInitializationService: Database force recreation completed');
    } catch (e) {
      print('DatabaseInitializationService: Force recreation failed: $e');
      errorMessage.value = 'Force recreation failed: $e';
      rethrow;
    }
  }
}
