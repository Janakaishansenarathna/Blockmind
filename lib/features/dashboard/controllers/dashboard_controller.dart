// controllers/home_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_apps/device_apps.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/local/models/app_model.dart';
import '../../../data/local/models/schedule_model.dart';
import '../../../data/local/models/usage_log_model.dart';
import '../../../data/local/models/user_model.dart';

import '../../../data/services/app_blocker_manager.dart';
import '../../../data/services/app_blocker_service.dart';
import 'quick_mood_controller.dart';

class HomeController extends GetxController {
  // Firebase services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAppBlockerService _blockerService = FirebaseAppBlockerService();
  final AppBlockerManager _appBlockerManager = AppBlockerManager();

  // Controllers
  late QuickModeController _quickModeController;

  // User data observables
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxString userName = 'User'.obs;
  RxString userEmail = ''.obs;
  RxString currentUserId = ''.obs;
  RxString userPhotoUrl = ''.obs;
  RxBool isUserPremium = false.obs;

  // Authentication state
  RxBool isAuthenticated = false.obs;
  RxBool isCheckingAuth = true.obs;

  // App data observables
  RxList<AppModel> allApps = <AppModel>[].obs;
  RxList<AppModel> filteredApps = <AppModel>[].obs;
  RxList<AppModel> blockedApps = <AppModel>[].obs;
  RxBool isLoadingApps = false.obs;
  RxString searchQuery = ''.obs;

  // Progress tracking observables
  Rx<Duration> savedTimeToday = Duration.zero.obs;
  Rx<Duration> totalSavedTime = Duration.zero.obs;
  RxInt unblockCount = 0.obs;
  RxInt totalUnblockCount = 0.obs;
  RxDouble progressPercentage = 0.0.obs;
  RxDouble uncompletedPercentage = 0.0.obs;
  RxInt notificationCount = 0.obs;
  RxInt currentStreak = 0.obs;
  RxInt longestStreak = 0.obs;

  // Schedule data observables
  RxList<ScheduleModel> schedules = <ScheduleModel>[].obs;
  RxList<ScheduleModel> activeSchedules = <ScheduleModel>[].obs;
  RxList<ScheduleModel> todaySchedules = <ScheduleModel>[].obs;
  RxBool isLoadingSchedules = false.obs;

  // UI State observables
  RxBool isInitialized = false.obs;
  RxBool isInitializing = false.obs;
  RxBool isConnected = true.obs;
  RxString errorMessage = ''.obs;
  RxString lastSyncTime = ''.obs;

  // Timers and subscriptions
  Timer? _progressTimer;
  Timer? _appMonitorTimer;
  Timer? _syncTimer;
  StreamSubscription? _authSubscription;
  StreamSubscription? _scheduleListener;
  StreamSubscription? _usageLogListener;
  StreamSubscription? _blockedAppsListener;
  StreamSubscription? _userDataListener;

  // Cache management
  static const String _cachePrefix = 'home_controller_';
  static const Duration _cacheTimeout = Duration(minutes: 5);
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  // ===== INITIALIZATION =====

  Future<void> _initializeController() async {
    if (isInitializing.value) return;

    try {
      isInitializing.value = true;
      isCheckingAuth.value = true;
      errorMessage.value = '';

      print('HomeController: Starting initialization...');

      // Initialize services first
      await _initializeServices();

      // Set up authentication listener first
      _setupAuthListener();

      // Wait a bit for auth state to be determined
      await Future.delayed(const Duration(milliseconds: 500));

      // Check current user authentication
      await _checkAuthenticationState();

      print('HomeController: Initialization completed');
    } catch (e) {
      print('HomeController: Initialization failed: $e');
      errorMessage.value = 'Failed to initialize: $e';
      await _handleInitializationError(e);
    } finally {
      isInitializing.value = false;
      isCheckingAuth.value = false;
    }
  }

  Future<void> _initializeServices() async {
    try {
      await _blockerService.initialize();
      await _appBlockerManager.initialize();
      print('HomeController: Services initialized');
    } catch (e) {
      print('HomeController: Service initialization failed: $e');
      throw Exception('Service initialization failed: $e');
    }
  }

  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen(
      (User? user) async {
        print(
            'HomeController: Auth state changed - User: ${user?.uid ?? 'null'}');

        if (user != null) {
          await _handleUserSignIn(user);
        } else {
          await _handleUserSignOut();
        }
      },
      onError: (error) {
        print('HomeController: Auth state error: $error');
        errorMessage.value = 'Authentication error: $error';
        isAuthenticated.value = false;
        isCheckingAuth.value = false;
      },
    );
  }

  Future<void> _checkAuthenticationState() async {
    try {
      final user = _auth.currentUser;
      print('HomeController: Current user check - ${user?.uid ?? 'null'}');

      if (user != null) {
        // User is authenticated
        isAuthenticated.value = true;
        await _handleUserSignIn(user);
      } else {
        // User is not authenticated - redirect to login
        isAuthenticated.value = false;
        _redirectToLogin();
      }
    } catch (e) {
      print('HomeController: Error checking auth state: $e');
      isAuthenticated.value = false;
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    print('HomeController: Redirecting to login');

    // Clear any existing data
    _clearUserData();

    // Navigate to login page
    Get.offAllNamed('/login'); // Adjust route name as needed

    // Or if using a different navigation method:
    // Get.offAll(() => LoginPage());
  }

  // ===== USER MANAGEMENT =====

  Future<void> _handleUserSignIn(User user) async {
    try {
      print('HomeController: User signed in: ${user.uid}');
      print('HomeController: User display name: ${user.displayName}');
      print('HomeController: User email: ${user.email}');

      isAuthenticated.value = true;
      currentUserId.value = user.uid;
      userEmail.value = user.email ?? '';
      userPhotoUrl.value = user.photoURL ?? '';

      // Set initial user name from Firebase Auth
      userName.value = user.displayName ?? user.email?.split('@')[0] ?? 'User';

      // Set user in services
      _blockerService.setCurrentUser(user.uid);

      // Initialize quick mode controller
      _initializeQuickMode();

      // Load user data and setup listeners
      await _loadUserProfile();
      await _setupFirebaseListeners();
      await _loadInitialData();

      // Start monitoring and sync
      _startMonitoring();

      // Update last sync time
      _updateLastSyncTime();

      isInitialized.value = true;
      print('HomeController: User sign in completed successfully');
    } catch (e) {
      print('HomeController: Error handling user sign in: $e');
      errorMessage.value = 'Failed to load user data: $e';
    }
  }

  Future<void> _handleUserSignOut() async {
    print('HomeController: User signed out');

    isAuthenticated.value = false;
    isInitialized.value = false;

    // Clear all data
    _clearUserData();
    _teardownListeners();
    _clearCache();

    // Redirect to login
    _redirectToLogin();
  }

  void _initializeQuickMode() {
    try {
      if (!Get.isRegistered<QuickModeController>()) {
        _quickModeController = Get.put(QuickModeController());
      } else {
        _quickModeController = Get.find<QuickModeController>();
      }

      if (currentUserId.value.isNotEmpty) {
        _quickModeController.setUserId(currentUserId.value);
      }
    } catch (e) {
      print('HomeController: QuickMode initialization failed: $e');
      // Continue without quick mode for now
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('HomeController: No current user for profile loading');
        return;
      }

      print('HomeController: Loading user profile for ${user.uid}');

      // Check cache first
      final cachedUser = _getFromCache('user_profile');
      if (cachedUser != null) {
        currentUser.value = cachedUser;
        userName.value = cachedUser.name;
        print('HomeController: Loaded user from cache: ${cachedUser.name}');
        return;
      }

      // Load from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      UserModel userModel;

      if (userDoc.exists) {
        print('HomeController: User document exists in Firestore');
        final userData = userDoc.data()!;
        userModel = UserModel.fromFirestore(userDoc, userData);

        // Check if we need to update user info
        final needsUpdate = _checkUserInfoUpdate(user, userData);
        if (needsUpdate) {
          print('HomeController: Updating user info in Firestore');
          await _updateUserInfo(user);
        }
      } else {
        print('HomeController: Creating new user document');
        // Create new user document
        userModel = await _createNewUser(user);
      }

      // Update observables
      currentUser.value = userModel;
      userName.value = userModel.name;

      // Check premium status
      await _checkPremiumStatus();

      // Cache the user data
      _addToCache('user_profile', userModel);

      print(
          'HomeController: User profile loaded successfully: ${userModel.name}');
    } catch (e) {
      print('HomeController: Error loading user profile: $e');
      // Fallback to auth user info
      final user = _auth.currentUser;
      userName.value =
          user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    }
  }

  bool _checkUserInfoUpdate(User user, Map<String, dynamic> userData) {
    return userData['name'] != user.displayName ||
        userData['email'] != user.email ||
        userData['photoUrl'] != user.photoURL;
  }

  Future<void> _updateUserInfo(User user) async {
    try {
      final updateData = {
        'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).update(updateData);

      // Update local state
      userName.value = updateData['name'] as String;

      print('HomeController: User info updated successfully');
    } catch (e) {
      print('HomeController: Error updating user info: $e');
    }
  }

  Future<UserModel> _createNewUser(User user) async {
    final displayName = user.displayName ?? user.email?.split('@')[0] ?? 'User';

    final newUser = UserModel(
      id: user.uid,
      name: displayName,
      email: user.email ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final userData = newUser.toFirestore();
    userData.addAll({
      'photoUrl': user.photoURL ?? '',
      'isPremium': false,
      'totalSavedTime': 0,
      'totalUnblocks': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(user.uid).set(userData);

    print('HomeController: New user created: $displayName');
    return newUser;
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final premiumDoc = await _firestore
          .collection('users')
          .doc(currentUserId.value)
          .collection('premium')
          .doc('status')
          .get();

      if (premiumDoc.exists) {
        final premiumData = premiumDoc.data()!;
        final expiryDate = (premiumData['expiryDate'] as Timestamp?)?.toDate();
        isUserPremium.value =
            expiryDate != null && expiryDate.isAfter(DateTime.now());
      } else {
        isUserPremium.value = false;
      }

      print('HomeController: Premium status checked: ${isUserPremium.value}');
    } catch (e) {
      print('HomeController: Error checking premium status: $e');
      isUserPremium.value = false;
    }
  }

  // ===== FIREBASE LISTENERS =====

  Future<void> _setupFirebaseListeners() async {
    if (currentUserId.value.isEmpty) {
      print('HomeController: Cannot setup listeners - no user ID');
      return;
    }

    try {
      print(
          'HomeController: Setting up Firebase listeners for user: ${currentUserId.value}');

      // User data listener
      _userDataListener = _firestore
          .collection('users')
          .doc(currentUserId.value)
          .snapshots()
          .listen(
        _handleUserDataSnapshot,
        onError: (error) {
          print('HomeController: User data listener error: $error');
        },
      );

      // Schedules listener
      _scheduleListener = _firestore
          .collection('users')
          .doc(currentUserId.value)
          .collection('schedules')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        _handleScheduleSnapshot,
        onError: (error) {
          print('HomeController: Schedule listener error: $error');
        },
      );

      // Blocked apps listener
      _blockedAppsListener = _firestore
          .collection('users')
          .doc(currentUserId.value)
          .collection('blocked_apps')
          .snapshots()
          .listen(
        _handleBlockedAppsSnapshot,
        onError: (error) {
          print('HomeController: Blocked apps listener error: $error');
        },
      );

      // Usage logs listener for today
      _setupUsageLogListener();

      print('HomeController: Firebase listeners setup complete');
    } catch (e) {
      print('HomeController: Error setting up Firebase listeners: $e');
    }
  }

  void _setupUsageLogListener() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    _usageLogListener = _firestore
        .collection('users')
        .doc(currentUserId.value)
        .collection('usage_logs')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('date', isLessThan: Timestamp.fromDate(todayEnd))
        .snapshots()
        .listen(
      _handleUsageLogSnapshot,
      onError: (error) {
        print('HomeController: Usage log listener error: $error');
      },
    );
  }

  void _handleUserDataSnapshot(DocumentSnapshot snapshot) {
    try {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        print('HomeController: User data snapshot received');

        // Update user stats
        totalSavedTime.value = Duration(seconds: data['totalSavedTime'] ?? 0);
        totalUnblockCount.value = data['totalUnblocks'] ?? 0;
        currentStreak.value = data['currentStreak'] ?? 0;
        longestStreak.value = data['longestStreak'] ?? 0;
        isUserPremium.value = data['isPremium'] ?? false;

        // Update user name if changed
        final newName = data['name'] ?? userName.value;
        if (newName != userName.value) {
          userName.value = newName;
          print('HomeController: User name updated to: $newName');
        }
      }
    } catch (e) {
      print('HomeController: Error handling user data snapshot: $e');
    }
  }

  void _handleScheduleSnapshot(QuerySnapshot snapshot) {
    try {
      isLoadingSchedules.value = true;
      print(
          'HomeController: Schedule snapshot received with ${snapshot.docs.length} documents');

      final scheduleList = <ScheduleModel>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final schedule = ScheduleModel.fromFirestore(doc, data);
          scheduleList.add(schedule);
          print('HomeController: Loaded schedule: ${schedule.title}');
        } catch (e) {
          print('HomeController: Error processing schedule ${doc.id}: $e');
        }
      }

      schedules.value = scheduleList;
      activeSchedules.value = scheduleList.where((s) => s.isActive).toList();

      // Filter today's schedules
      final today = DateTime.now().weekday;
      todaySchedules.value =
          activeSchedules.where((s) => s.days.contains(today)).toList();

      _updateNotificationCount();

      print(
          'HomeController: Schedules updated - ${scheduleList.length} total, ${activeSchedules.length} active, ${todaySchedules.length} today');
    } catch (e) {
      print('HomeController: Error handling schedule snapshot: $e');
    } finally {
      isLoadingSchedules.value = false;
    }
  }

  void _handleBlockedAppsSnapshot(QuerySnapshot snapshot) {
    try {
      final blockedAppsList = <AppModel>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final app = AppModel.fromFirestore(doc);
          blockedAppsList.add(app);
        } catch (e) {
          print('HomeController: Error processing blocked app ${doc.id}: $e');
        }
      }

      blockedApps.value = blockedAppsList;

      print(
          'HomeController: Blocked apps updated - ${blockedAppsList.length} apps');
    } catch (e) {
      print('HomeController: Error handling blocked apps snapshot: $e');
    }
  }

  void _handleUsageLogSnapshot(QuerySnapshot snapshot) {
    try {
      Duration dailySavedTime = Duration.zero;
      int dailyUnblockCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final log = UsageLogModel.fromFirestore(doc, data);

          if (log.wasBlocked) {
            dailySavedTime += log.duration;
            dailyUnblockCount += log.openCount;
          }
        } catch (e) {
          print('HomeController: Error processing usage log ${doc.id}: $e');
        }
      }

      savedTimeToday.value = dailySavedTime;
      unblockCount.value = dailyUnblockCount;

      _calculateProgressPercentages();
      _updateNotificationCount();

      print(
          'HomeController: Daily progress updated - Saved: ${dailySavedTime.inMinutes}min, Unblocks: $dailyUnblockCount');
    } catch (e) {
      print('HomeController: Error handling usage log snapshot: $e');
    }
  }

  void _calculateProgressPercentages() {
    // Calculate saved time progress
    const targetSavedTime = Duration(hours: 4);
    progressPercentage.value =
        (savedTimeToday.value.inMinutes / targetSavedTime.inMinutes)
            .clamp(0.0, 1.0);

    // Calculate unblock progress
    const targetUnblockLimit = 5;
    uncompletedPercentage.value =
        (unblockCount.value / targetUnblockLimit).clamp(0.0, 1.0);
  }

  void _updateNotificationCount() {
    int count = 0;

    // Active schedules
    count += activeSchedules.length;

    // Quick mode
    if (_quickModeController.isQuickModeActive.value) {
      count += 1;
    }

    // Pending updates (example)
    if (errorMessage.value.isNotEmpty) {
      count += 1;
    }

    notificationCount.value = count;
  }

  // ===== DATA LOADING =====

  Future<void> _loadInitialData() async {
    try {
      print('HomeController: Loading initial data...');

      // Load apps and other data in parallel
      await Future.wait([
        _loadInstalledApps(),
        _loadStatistics(),
      ]);

      print('HomeController: Initial data loaded successfully');
    } catch (e) {
      print('HomeController: Error loading initial data: $e');
    }
  }

  Future<void> _loadInstalledApps() async {
    try {
      isLoadingApps.value = true;

      // Check cache first
      final cachedApps = _getFromCache('installed_apps');
      if (cachedApps != null) {
        allApps.value = cachedApps;
        filteredApps.value = cachedApps;
        _quickModeController.setAvailableApps(cachedApps);
        return;
      }

      print('HomeController: Loading installed apps...');

      // Try to load real device apps first
      await _loadRealDeviceApps();

      // If no real apps loaded, use fallback apps
      if (allApps.isEmpty) {
        print('HomeController: Using fallback apps');
        allApps.value = _getFallbackApps();
      }

      filteredApps.value = allApps.toList();
      _quickModeController.setAvailableApps(allApps);

      // Cache the apps
      _addToCache('installed_apps', allApps.toList());

      // Save to Firebase in background
      _saveAppsToFirebase();

      print('HomeController: Loaded ${allApps.length} apps');
    } catch (e) {
      print('HomeController: Error loading apps: $e');
      allApps.value = _getFallbackApps();
      filteredApps.value = allApps.toList();
    } finally {
      isLoadingApps.value = false;
    }
  }

  Future<void> _loadRealDeviceApps() async {
    try {
      final deviceApps = await DeviceApps.getInstalledApplications(
        includeAppIcons: false,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );

      final appModels = <AppModel>[];

      for (final app in deviceApps) {
        try {
          final appModel = AppModel(
            id: app.packageName,
            name: app.appName,
            packageName: app.packageName,
            icon: _getIconForPackage(app.packageName),
            iconColor: _generateColorFromString(app.appName),
            isSystemApp: app.systemApp,
            category: _getCategoryForPackage(app.packageName),
          );

          appModels.add(appModel);
        } catch (e) {
          print('HomeController: Error processing app ${app.appName}: $e');
        }
      }

      appModels
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      allApps.value = appModels;

      print('HomeController: Loaded ${appModels.length} real device apps');
    } catch (e) {
      print('HomeController: Error loading real device apps: $e');
      rethrow;
    }
  }

  Future<void> _loadStatistics() async {
    try {
      // This is handled by real-time listeners now
      // But we can load initial cached values here
      final cachedStats = _getFromCache('user_statistics');
      if (cachedStats != null) {
        totalSavedTime.value =
            Duration(seconds: cachedStats['totalSavedTime'] ?? 0);
        totalUnblockCount.value = cachedStats['totalUnblocks'] ?? 0;
        currentStreak.value = cachedStats['currentStreak'] ?? 0;
        longestStreak.value = cachedStats['longestStreak'] ?? 0;
      }
    } catch (e) {
      print('HomeController: Error loading statistics: $e');
    }
  }

  // ===== UTILITY METHODS =====

  Future<void> _saveAppsToFirebase() async {
    if (currentUserId.value.isEmpty || allApps.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final appsRef = _firestore
          .collection('users')
          .doc(currentUserId.value)
          .collection('installed_apps');

      for (final app in allApps) {
        final appDoc = appsRef.doc(app.id);
        batch.set(appDoc, app.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();
      print('HomeController: Apps saved to Firebase');
    } catch (e) {
      print('HomeController: Error saving apps to Firebase: $e');
    }
  }

  IconData _getIconForPackage(String packageName) {
    final knownIcons = {
      'com.facebook.katana': Icons.facebook,
      'com.instagram.android': Icons.camera_alt,
      'com.whatsapp': Icons.chat,
      'com.google.android.youtube': Icons.play_circle_fill,
      'com.twitter.android': Icons.alternate_email,
      'com.zhiliaoapp.musically': Icons.music_note,
      'com.snapchat.android': Icons.camera,
      'com.pinterest': Icons.push_pin,
      'com.linkedin.android': Icons.work,
      'com.reddit.frontpage': Icons.forum,
      'com.discord': Icons.headset_mic,
      'com.spotify.music': Icons.music_note,
      'com.netflix.mediaclient': Icons.tv,
      'com.chrome.beta': Icons.web,
      'com.android.chrome': Icons.web,
    };

    return knownIcons[packageName] ?? Icons.android;
  }

  String _getCategoryForPackage(String packageName) {
    final knownCategories = {
      'com.facebook.katana': 'Social Media',
      'com.instagram.android': 'Social Media',
      'com.twitter.android': 'Social Media',
      'com.snapchat.android': 'Social Media',
      'com.linkedin.android': 'Social Media',
      'com.reddit.frontpage': 'Social Media',
      'com.google.android.youtube': 'Entertainment',
      'com.netflix.mediaclient': 'Entertainment',
      'com.spotify.music': 'Entertainment',
      'com.zhiliaoapp.musically': 'Entertainment',
      'com.whatsapp': 'Communication',
      'com.discord': 'Communication',
    };

    return knownCategories[packageName] ?? 'Other';
  }

  Color _generateColorFromString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
      Colors.deepOrange,
    ];

    return colors[hash.abs() % colors.length];
  }

  List<AppModel> _getFallbackApps() {
    return [
      AppModel(
        id: 'com.facebook.katana',
        name: 'Facebook',
        packageName: 'com.facebook.katana',
        icon: Icons.facebook,
        iconColor: const Color(0xFF1877F2),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.instagram.android',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        icon: Icons.camera_alt,
        iconColor: const Color(0xFFE4405F),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.whatsapp',
        name: 'WhatsApp',
        packageName: 'com.whatsapp',
        icon: Icons.chat,
        iconColor: const Color(0xFF25D366),
        category: 'Communication',
      ),
      AppModel(
        id: 'com.google.android.youtube',
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        icon: Icons.play_circle_fill,
        iconColor: const Color(0xFFFF0000),
        category: 'Entertainment',
      ),
      AppModel(
        id: 'com.zhiliaoapp.musically',
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        icon: Icons.music_note,
        iconColor: const Color(0xFF000000),
        category: 'Entertainment',
      ),
      AppModel(
        id: 'com.twitter.android',
        name: 'Twitter',
        packageName: 'com.twitter.android',
        icon: Icons.alternate_email,
        iconColor: const Color(0xFF1DA1F2),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.snapchat.android',
        name: 'Snapchat',
        packageName: 'com.snapchat.android',
        icon: Icons.camera,
        iconColor: const Color(0xFFFFFC00),
        category: 'Social Media',
      ),
      AppModel(
        id: 'com.netflix.mediaclient',
        name: 'Netflix',
        packageName: 'com.netflix.mediaclient',
        icon: Icons.tv,
        iconColor: const Color(0xFFE50914),
        category: 'Entertainment',
      ),
    ];
  }

  // ===== MONITORING AND SYNC =====

  void _startMonitoring() {
    // Progress update timer
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_quickModeController.isQuickModeActive.value) {
        await _monitorAppUsage();
      }
    });

    // Sync timer for offline support
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _performPeriodicSync();
    });

    print('HomeController: Monitoring started');
  }

  Future<void> _monitorAppUsage() async {
    try {
      for (final appId in _quickModeController.blockedAppIds) {
        final app = allApps.firstWhereOrNull((a) => a.id == appId);
        if (app != null) {
          await _logAppUsage(app, wasBlocked: true);
        }
      }
    } catch (e) {
      print('HomeController: Error monitoring app usage: $e');
    }
  }

  Future<void> _performPeriodicSync() async {
    try {
      _updateLastSyncTime();

      // Update connection status
      await _checkConnectionStatus();

      // Sync any cached data if online
      if (isConnected.value) {
        await _syncCachedData();
      }
    } catch (e) {
      print('HomeController: Error in periodic sync: $e');
    }
  }

  Future<void> _checkConnectionStatus() async {
    try {
      // Simple connectivity check by pinging Firestore
      await _firestore.collection('_test').limit(1).get();
      isConnected.value = true;
    } catch (e) {
      isConnected.value = false;
      print('HomeController: Connection check failed: $e');
    }
  }

  Future<void> _syncCachedData() async {
    // Implement syncing of any cached offline data
    // This is a placeholder for future offline support
  }

  Future<void> _logAppUsage(AppModel app,
      {required bool wasBlocked, String? scheduleId}) async {
    if (currentUserId.value.isEmpty) return;

    try {
      final log = UsageLogModel(
        id: '${app.id}_${DateTime.now().millisecondsSinceEpoch}',
        appId: app.id,
        date: DateTime.now(),
        duration: const Duration(minutes: 1),
        wasBlocked: wasBlocked,
        scheduleId: scheduleId,
        openCount: wasBlocked ? 1 : 0,
      );

      await _firestore
          .collection('users')
          .doc(currentUserId.value)
          .collection('usage_logs')
          .doc(log.id)
          .set(log.toFirestore());
    } catch (e) {
      print('HomeController: Error logging app usage: $e');
    }
  }

  // ===== CACHE MANAGEMENT =====

  T? _getFromCache<T>(String key) {
    final cacheKey = '$_cachePrefix$key';
    final timestamp = _cacheTimestamps[cacheKey];

    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheTimeout) {
      return _cache[cacheKey] as T?;
    }

    // Remove expired cache
    _cache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
    return null;
  }

  void _addToCache<T>(String key, T value) {
    final cacheKey = '$_cachePrefix$key';
    _cache[cacheKey] = value;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  void _clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // ===== PUBLIC API METHODS =====

  // User methods
  String get currentLoggedUsername => userName.value;
  String get currentUserEmail => userEmail.value;
  String get currentUserPhotoUrl => userPhotoUrl.value;
  bool get isPremiumUser => isUserPremium.value;
  bool get isUserAuthenticated => isAuthenticated.value;
  bool get isCheckingAuthentication => isCheckingAuth.value;

  // Schedule methods
  List<ScheduleModel> get userSchedules => schedules.toList();
  List<ScheduleModel> get activeUserSchedules => activeSchedules.toList();
  List<ScheduleModel> get todayUserSchedules => todaySchedules.toList();

  Future<void> createSchedule(ScheduleModel schedule) async {
    try {
      await _appBlockerManager.addSchedule(schedule);
    } catch (e) {
      print('HomeController: Error creating schedule: $e');
      rethrow;
    }
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    try {
      await _appBlockerManager.updateSchedule(schedule);
    } catch (e) {
      print('HomeController: Error updating schedule: $e');
      rethrow;
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _appBlockerManager.deleteSchedule(scheduleId);
    } catch (e) {
      print('HomeController: Error deleting schedule: $e');
      rethrow;
    }
  }

  Future<void> toggleSchedule(String scheduleId, bool isActive) async {
    try {
      await _appBlockerManager.toggleScheduleActive(scheduleId, isActive);
    } catch (e) {
      print('HomeController: Error toggling schedule: $e');
      rethrow;
    }
  }

  // Authentication methods
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // The auth listener will handle the rest
    } catch (e) {
      print('HomeController: Error signing out: $e');
      rethrow;
    }
  }

  Future<void> checkAuthAndRedirect() async {
    await _checkAuthenticationState();
  }

  // App methods
  void searchApps(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredApps.value = allApps.toList();
    } else {
      filteredApps.value = allApps
          .where((app) =>
              app.name.toLowerCase().contains(query.toLowerCase()) ||
              app.packageName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  Map<String, List<AppModel>> getAppsByCategory() {
    final selectedApps = _quickModeController.selectedApps;
    final categories = <String, List<AppModel>>{};

    if (selectedApps.isNotEmpty) {
      categories['Selected Apps (${selectedApps.length})'] =
          selectedApps.toList();
    }

    categories['Social Media'] = allApps
        .where((app) =>
            app.category == 'Social Media' &&
            !_quickModeController.isAppSelected(app))
        .toList();

    categories['Entertainment'] = allApps
        .where((app) =>
            app.category == 'Entertainment' &&
            !_quickModeController.isAppSelected(app))
        .toList();

    categories['Communication'] = allApps
        .where((app) =>
            app.category == 'Communication' &&
            !_quickModeController.isAppSelected(app))
        .toList();

    categories['Other'] = allApps
        .where((app) =>
            app.category == 'Other' && !_quickModeController.isAppSelected(app))
        .toList();

    categories.removeWhere((key, value) => value.isEmpty);
    return categories;
  }

  bool isAppBlocked(AppModel app) {
    // Check if app is blocked by quick mode
    if (_quickModeController.isQuickModeActive.value &&
        _quickModeController.blockedAppIds.contains(app.id)) {
      return true;
    }

    // Check if app is blocked by any active schedule
    for (final schedule in activeSchedules) {
      if (schedule.isCurrentlyActive &&
          schedule.blockedApps.contains(app.packageName)) {
        return true;
      }
    }

    // Check if app is in blocked apps list
    return blockedApps.any((blockedApp) => blockedApp.id == app.id);
  }

  Future<void> refreshData() async {
    try {
      await Future.wait([
        _loadInstalledApps(),
        _loadStatistics(),
      ]);

      _updateLastSyncTime();
    } catch (e) {
      print('HomeController: Error refreshing data: $e');
      rethrow;
    }
  }

  // Format methods
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  // Text getters
  String get savedTimeText =>
      "You've saved ${formatDuration(savedTimeToday.value)} today!";

  String get unblockText {
    if (unblockCount.value == 0) {
      return "No app unblocks today - Great job!";
    }
    return "You've unblocked apps ${unblockCount.value} times today";
  }

  String get selectedAppsText {
    final selectedApps = _quickModeController.selectedApps;

    if (selectedApps.isEmpty) {
      return 'Add apps to block. Tap the Add button to select distracting apps';
    } else if (selectedApps.length == 1) {
      return 'Currently blocking: ${selectedApps.first.name}';
    } else {
      return 'Currently blocking: ${selectedApps.map((app) => app.name).take(2).join(", ")}${selectedApps.length > 2 ? " and ${selectedApps.length - 2} more" : ""}';
    }
  }

  String get lastSyncText =>
      lastSyncTime.value.isEmpty ? 'Never' : lastSyncTime.value;

  // ===== CLEANUP AND ERROR HANDLING =====

  void _updateLastSyncTime() {
    final now = DateTime.now();
    lastSyncTime.value =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleInitializationError(dynamic error) async {
    print('HomeController: Handling initialization error: $error');

    // Show user-friendly error message
    Get.snackbar(
      'Initialization Error',
      'Some features may not work properly. Please restart the app.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );

    // Try to recover with offline mode or basic functionality
    try {
      allApps.value = _getFallbackApps();
      filteredApps.value = allApps.toList();
      userName.value = 'User';
    } catch (e) {
      print('HomeController: Error recovery failed: $e');
    }
  }

  void _clearUserData() {
    currentUser.value = null;
    userName.value = 'User';
    userEmail.value = '';
    currentUserId.value = '';
    userPhotoUrl.value = '';
    isUserPremium.value = false;

    allApps.clear();
    filteredApps.clear();
    blockedApps.clear();
    schedules.clear();
    activeSchedules.clear();
    todaySchedules.clear();

    savedTimeToday.value = Duration.zero;
    totalSavedTime.value = Duration.zero;
    unblockCount.value = 0;
    totalUnblockCount.value = 0;
    progressPercentage.value = 0.0;
    uncompletedPercentage.value = 0.0;
    notificationCount.value = 0;
    currentStreak.value = 0;
    longestStreak.value = 0;

    errorMessage.value = '';
    lastSyncTime.value = '';
  }

  void _teardownListeners() {
    _authSubscription?.cancel();
    _scheduleListener?.cancel();
    _usageLogListener?.cancel();
    _blockedAppsListener?.cancel();
    _userDataListener?.cancel();

    _authSubscription = null;
    _scheduleListener = null;
    _usageLogListener = null;
    _blockedAppsListener = null;
    _userDataListener = null;
  }

  void _cleanup() {
    print('HomeController: Starting cleanup...');

    _progressTimer?.cancel();
    _appMonitorTimer?.cancel();
    _syncTimer?.cancel();

    _teardownListeners();
    _clearCache();

    print('HomeController: Cleanup completed');
  }
}
