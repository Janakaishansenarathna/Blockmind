import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'data/local/models/app_model.dart';
import 'data/services/app_blocker_manager.dart';
import 'data/services/foreground_service.dart';
import 'data/services/permissions_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'routes/routes.dart';
import 'firebase_options.dart';
import 'utils/constants/app_constants.dart';
import 'utils/themes/app_theme.dart';

/// Main app class using GetX for state management and routing
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      initialBinding: AppBindings(),
    );
  }
}

/// Inject dependencies for the app
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Register controllers
    Get.put(AuthController(), permanent: true);
    Get.put(BlockerController(), permanent: true);
    // Profile controller will be lazily loaded when needed
    // Other controllers will be added as needed
  }
}

/// BlockerController to manage app blocking functionality
class BlockerController extends GetxController {
  final AppBlockerManager _blockerManager = AppBlockerManager();
  final PermissionsService _permissionsService = PermissionsService();
  final ForegroundService _foregroundService = ForegroundService();

  final RxBool isQuickModeActive = false.obs;
  final RxInt blockedAppsCount = 0.obs;
  final RxInt unblockCount = 0.obs;
  final RxString savedTime = '0h 0m'.obs;

  @override
  void onInit() {
    super.onInit();
    _initBlocker();
    _initForegroundTask();
  }

  Future<void> _initForegroundTask() async {
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
  }

  Future<void> _initBlocker() async {
    await _blockerManager.initialize();

    // Update observable variables
    isQuickModeActive.value = _blockerManager.isQuickBlockActive();
    blockedAppsCount.value = (await _blockerManager.getBlockedApps()).length;
    unblockCount.value = await _blockerManager.getUnblockCountToday();

    // Format saved time
    final savedDuration = await _blockerManager.getSavedTimeToday();
    savedTime.value = _formatDuration(savedDuration);

    // Start background service if quick mode is active
    if (isQuickModeActive.value) {
      await _foregroundService.startService();
    }
  }

  Future<bool> checkPermissions() async {
    return await _permissionsService.checkAllPermissions();
  }

  Future<bool> requestPermissions() async {
    return await _permissionsService.requestAllRequiredPermissions();
  }

  // Fixed the type error by converting List<dynamic> to List<AppModel>
  Future<void> toggleQuickMode(List<dynamic> apps, Duration duration) async {
    if (isQuickModeActive.value) {
      await _blockerManager.stopQuickBlock();
      await _foregroundService.stopService();
      isQuickModeActive.value = false;
    } else {
      // Convert List<dynamic> to List<AppModel>
      final List<AppModel> appModels = apps.map((app) {
        if (app is AppModel) {
          return app;
        } else if (app is Map<String, dynamic>) {
          // Convert map to AppModel if needed
          return AppModel(
            id: app['id'] as String,
            name: app['name'] as String,
            packageName: app['packageName'] as String,
            icon: IconData(
              app['iconCode'] as int,
              fontFamily: 'MaterialIcons',
            ),
            iconColor: Color(app['iconColor'] as int),
          );
        } else {
          throw ArgumentError('Cannot convert to AppModel: $app');
        }
      }).toList();

      await _blockerManager.startQuickBlock(duration, appModels);
      await _foregroundService.startService();
      isQuickModeActive.value = true;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Initialize app services and Firebase
class AppInitializer {
  static Future<void> init() async {
    try {
      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Apply status bar styling
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ));

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize app blocker manager
      await AppBlockerManager().initialize();

      // Initialize other services
      _initServices();

      // Log initialization complete
      debugPrint('App initialization completed successfully');
    } catch (e) {
      debugPrint('Error during app initialization: $e');
    }
  }

  static void _initServices() {
    // Initialize local storage
    // Initialize notifications
    // Initialize analytics
    // Set up method channel for native app blocking functionality
    _setupMethodChannel();
  }

  static void _setupMethodChannel() {
    const methodChannel =
        MethodChannel('com.example.socialmediablocker/app_blocker');

    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAppBlocked':
          final packageName = call.arguments as String;
          debugPrint('App blocked: $packageName');
          // Notify controller if needed
          return true;

        case 'onBlockBypass':
          final packageName = call.arguments as String;
          debugPrint('Block bypassed for: $packageName');
          // Update unblock count
          return true;

        default:
          throw PlatformException(
            code: 'UNSUPPORTED_METHOD',
            message: 'Method ${call.method} not supported',
          );
      }
    });
  }
}

/// Main app launcher
Future<void> initializeApp() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app services
  await AppInitializer.init();
}
