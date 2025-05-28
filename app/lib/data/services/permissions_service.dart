import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  static final PermissionsService _instance = PermissionsService._internal();

  factory PermissionsService() {
    return _instance;
  }

  PermissionsService._internal();

  /// Request usage access permission (for monitoring app usage)
  Future<bool> requestUsageStatsPermission() async {
    try {
      // For usage stats, we need to use a different approach on Android
      // This permission requires special handling and usually needs to be done through settings
      final status = await Permission.phone.status;
      if (status.isGranted) {
        return true;
      }

      // Request permission
      final result = await Permission.phone.request();
      return result.isGranted;
    } catch (e) {
      print('Error requesting usage stats permission: $e');
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationsPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        return true;
      }

      // Request permission
      final result = await Permission.notification.request();
      return result.isGranted;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Request system alert window permission (for overlay blocking)
  Future<bool> requestOverlayPermission() async {
    try {
      final status = await Permission.systemAlertWindow.status;
      if (status.isGranted) {
        return true;
      }

      // Request permission
      final result = await Permission.systemAlertWindow.request();
      return result.isGranted;
    } catch (e) {
      print('Error requesting overlay permission: $e');
      return false;
    }
  }

  /// Request device admin permission (for app blocking)
  Future<bool> requestDeviceAdminPermission() async {
    try {
      // Device admin permissions need special handling
      // For now, we'll use accessibility permission as a placeholder
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) {
        return true;
      }

      final result = await Permission.manageExternalStorage.request();
      return result.isGranted;
    } catch (e) {
      print('Error requesting device admin permission: $e');
      return false;
    }
  }

  /// Request all required permissions
  Future<bool> requestAllRequiredPermissions() async {
    try {
      print('Requesting all required permissions...');

      final notifications = await requestNotificationsPermission();
      print('Notifications permission: $notifications');

      final overlay = await requestOverlayPermission();
      print('Overlay permission: $overlay');

      // Usage stats permission is optional for basic functionality
      final usageStats = await requestUsageStatsPermission();
      print('Usage stats permission: $usageStats');

      // Return true if essential permissions are granted
      // (notifications and overlay are essential, usage stats is optional)
      return notifications && overlay;
    } catch (e) {
      print('Error requesting all permissions: $e');
      return false;
    }
  }

  /// Check if all permissions are granted
  Future<bool> checkAllPermissions() async {
    try {
      final notifications = await Permission.notification.status.isGranted;
      final overlay = await Permission.systemAlertWindow.status.isGranted;

      // Essential permissions check
      return notifications && overlay;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  /// Check individual permission status
  Future<bool> checkNotificationPermission() async {
    try {
      return await Permission.notification.status.isGranted;
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }

  Future<bool> checkOverlayPermission() async {
    try {
      return await Permission.systemAlertWindow.status.isGranted;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  Future<bool> checkUsageStatsPermission() async {
    try {
      return await Permission.phone.status.isGranted;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }

  /// Open app settings for manual permission grant
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }
}
