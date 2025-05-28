import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:isolate';

class ForegroundService {
  static final ForegroundService _instance = ForegroundService._internal();

  factory ForegroundService() {
    return _instance;
  }

  ForegroundService._internal();

  Future<void> startService() async {
    // Check if the foreground service is running
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      return;
    }

    // Initialize foreground task settings
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'app_blocker_notification_channel',
        channelName: 'App Blocker Notification',
        channelDescription:
            'This notification appears when the app blocker is running.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(
            id: 'stopButton',
            text: 'Stop',
          ),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 1000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    // Start the foreground service
    await FlutterForegroundTask.startService(
      notificationTitle: 'App Blocker',
      notificationText: 'App Blocker is running in the background',
      callback: _startCallback,
    );
  }

  Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }
}

// This is the entry point for the background task
@pragma('vm:entry-point')
void _startCallback() {
  // Initialize the foreground task
  FlutterForegroundTask.setTaskHandler(AppBlockerTaskHandler());
}

// Task handler that runs in the background
class AppBlockerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Initialize background task
    print('Foreground task started');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Code to check and block apps goes here
    print('Checking for apps to block...');
    // This runs periodically according to the interval
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Clean up resources
    print('Foreground task destroyed');
  }

  @override
  void onButtonPressed(String id) {
    // Handle notification button presses
    if (id == 'stopButton') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    // TODO: implement onRepeatEvent
  }
}
