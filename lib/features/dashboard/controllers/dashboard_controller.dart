// controllers/dashboard_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/local/models/app_model.dart';
import '../../../data/local/models/schedule_model.dart';
import '../../../data/local/models/usage_log_model.dart';
import '../../../data/local/models/user_model.dart';

import '../../../data/services/app_blocker_manager.dart';
import '../../../data/services/app_blocker_service.dart';
import '../../../utils/constants/app_colors.dart';
import 'quick_mood_controller.dart';

/// Production-level Dashboard Controller
///
/// Handles all dashboard-related functionality including:
/// - User authentication and profile management
/// - Schedule management and real-time updates
/// - Progress tracking and statistics
/// - App usage monitoring
/// - Firebase real-time listeners
/// - Offline support and caching
/// - Error handling and recovery
class DashboardController extends GetxController {
  // ===== SERVICES AND DEPENDENCIES =====

  /// Firebase services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAppBlockerService _blockerService = FirebaseAppBlockerService();
  final AppBlockerManager _appBlockerManager = AppBlockerManager();

  /// Quick Mode Controller dependency
  late QuickModeController _quickModeController;

  // ===== USER STATE OBSERVABLES =====

  /// Current authenticated user model
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  /// User display information
  final RxString userName = 'User'.obs;
  final RxString userEmail = ''.obs;
  final RxString currentUserId = ''.obs;
  final RxString userPhotoUrl = ''.obs;
  final RxBool isUserPremium = false.obs;

  /// Authentication state management
  final RxBool isAuthenticated = false.obs;
  final RxBool isCheckingAuth = true.obs;

  // ===== SCHEDULE STATE OBSERVABLES =====

  /// All user schedules
  final RxList<ScheduleModel> allSchedules = <ScheduleModel>[].obs;

  /// Latest 3 schedules for dashboard display
  final RxList<ScheduleModel> latestSchedules = <ScheduleModel>[].obs;

  /// Currently active schedules
  final RxList<ScheduleModel> activeSchedules = <ScheduleModel>[].obs;

  /// Today's applicable schedules
  final RxList<ScheduleModel> todaySchedules = <ScheduleModel>[].obs;

  /// Currently running schedule (if any)
  final Rx<ScheduleModel?> currentActiveSchedule = Rx<ScheduleModel?>(null);

  /// Schedule loading states
  final RxBool isLoadingSchedules = false.obs;
  final RxString schedulesError = ''.obs;

  // ===== PROGRESS AND STATISTICS OBSERVABLES =====

  /// Time saved today and total
  final Rx<Duration> savedTimeToday = Duration.zero.obs;
  final Rx<Duration> totalSavedTime = Duration.zero.obs;

  /// Unblock counts
  final RxInt unblockCount = 0.obs;
  final RxInt totalUnblockCount = 0.obs;

  /// Progress percentages for UI
  final RxDouble progressPercentage = 0.0.obs;
  final RxDouble uncompletedPercentage = 0.0.obs;

  /// Streak tracking
  final RxInt currentStreak = 0.obs;
  final RxInt longestStreak = 0.obs;

  /// Notification count for UI badge
  final RxInt notificationCount = 0.obs;

  // ===== APP DATA OBSERVABLES =====

  /// All installed apps
  final RxList<AppModel> allApps = <AppModel>[].obs;

  /// Currently blocked apps
  final RxList<AppModel> blockedApps = <AppModel>[].obs;

  /// App loading state
  final RxBool isLoadingApps = false.obs;

  // ===== UI STATE MANAGEMENT =====

  /// Overall initialization state
  final RxBool isInitialized = false.obs;
  final RxBool isInitializing = false.obs;

  /// Connection and sync status
  final RxBool isConnected = true.obs;
  final RxString lastSyncTime = ''.obs;

  /// Error handling
  final RxString errorMessage = ''.obs;

  // ===== FIREBASE LISTENERS =====

  /// Real-time data subscriptions
  StreamSubscription? _authSubscription;
  StreamSubscription? _scheduleListener;
  StreamSubscription? _usageLogListener;
  StreamSubscription? _blockedAppsListener;
  StreamSubscription? _userDataListener;

  // ===== TIMERS AND MONITORING =====

  /// Periodic timers for monitoring and sync
  Timer? _progressTimer;
  Timer? _syncTimer;
  Timer? _scheduleMonitorTimer;

  // ===== CACHE MANAGEMENT =====

  /// Cache configuration
  static const String _cachePrefix = 'dashboard_';
  static const Duration _cacheTimeout = Duration(minutes: 5);
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // ===== LIFECYCLE METHODS =====

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

  /// Initialize the dashboard controller
  ///
  /// Sets up services, auth listeners, and loads initial data
  Future<void> _initializeController() async {
    if (isInitializing.value) return;

    try {
      isInitializing.value = true;
      isCheckingAuth.value = true;
      errorMessage.value = '';

      print('DashboardController: Starting initialization...');

      // Initialize services first
      await _initializeServices();

      // Initialize QuickMode controller
      _initializeQuickModeController();

      // Set up authentication listener
      _setupAuthListener();

      // Wait for auth state determination
      await Future.delayed(const Duration(milliseconds: 500));

      // Check current authentication state
      await _checkAuthenticationState();

      print('DashboardController: Initialization completed successfully');
    } catch (e) {
      print('DashboardController: Initialization failed: $e');
      errorMessage.value = 'Failed to initialize dashboard: $e';
      await _handleInitializationError(e);
    } finally {
      isInitializing.value = false;
      isCheckingAuth.value = false;
    }
  }

  /// Initialize required services
  Future<void> _initializeServices() async {
    try {
      await _blockerService.initialize();
      await _appBlockerManager.initialize();
      print('DashboardController: Services initialized successfully');
    } catch (e) {
      print('DashboardController: Service initialization failed: $e');
      throw Exception('Service initialization failed: $e');
    }
  }

  /// Initialize QuickMode controller dependency
  void _initializeQuickModeController() {
    try {
      if (!Get.isRegistered<QuickModeController>()) {
        _quickModeController = Get.put(QuickModeController());
      } else {
        _quickModeController = Get.find<QuickModeController>();
      }
      print('DashboardController: QuickMode controller initialized');
    } catch (e) {
      print('DashboardController: QuickMode initialization failed: $e');
      // Continue without quick mode for now
    }
  }

  // ===== AUTHENTICATION MANAGEMENT =====

  /// Set up Firebase auth state listener
  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen(
      (User? user) async {
        print(
            'DashboardController: Auth state changed - User: ${user?.uid ?? 'null'}');

        if (user != null) {
          await _handleUserSignIn(user);
        } else {
          await _handleUserSignOut();
        }
      },
      onError: (error) {
        print('DashboardController: Auth state error: $error');
        errorMessage.value = 'Authentication error: $error';
        isAuthenticated.value = false;
        isCheckingAuth.value = false;
      },
    );
  }

  /// Check current authentication state
  Future<void> _checkAuthenticationState() async {
    try {
      final user = _auth.currentUser;
      print('DashboardController: Current user check - ${user?.uid ?? 'null'}');

      if (user != null) {
        isAuthenticated.value = true;
        await _handleUserSignIn(user);
      } else {
        isAuthenticated.value = false;
        _redirectToLogin();
      }
    } catch (e) {
      print('DashboardController: Error checking auth state: $e');
      isAuthenticated.value = false;
      _redirectToLogin();
    }
  }

  /// Handle user sign in event
  Future<void> _handleUserSignIn(User user) async {
    try {
      print('DashboardController: User signed in: ${user.uid}');

      // Update authentication state
      isAuthenticated.value = true;
      currentUserId.value = user.uid;
      userEmail.value = user.email ?? '';
      userPhotoUrl.value = user.photoURL ?? '';
      userName.value = user.displayName ?? user.email?.split('@')[0] ?? 'User';

      // Set user in services
      _blockerService.setCurrentUser(user.uid);

      // Set user ID in QuickMode controller
      if (Get.isRegistered<QuickModeController>()) {
        _quickModeController.setUserId(user.uid);
      }

      // Load user profile and setup listeners
      await _loadUserProfile();
      await _setupFirebaseListeners();
      await _loadInitialData();

      // Start monitoring
      _startMonitoring();

      // Update sync time
      _updateLastSyncTime();

      isInitialized.value = true;
      print('DashboardController: User sign in completed successfully');
    } catch (e) {
      print('DashboardController: Error handling user sign in: $e');
      errorMessage.value = 'Failed to load user data: $e';
    }
  }

  /// Handle user sign out event
  Future<void> _handleUserSignOut() async {
    print('DashboardController: User signed out');

    isAuthenticated.value = false;
    isInitialized.value = false;

    // Clear all data and listeners
    _clearAllData();
    _teardownListeners();
    _clearCache();

    // Redirect to login
    _redirectToLogin();
  }

  /// Redirect to login screen
  void _redirectToLogin() {
    print('DashboardController: Redirecting to login');

    // Clear any existing data
    _clearAllData();

    // Navigate to login page
    Get.offAllNamed('/login');
  }

  // ===== USER PROFILE MANAGEMENT =====

  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('DashboardController: No current user for profile loading');
        return;
      }

      print('DashboardController: Loading user profile for ${user.uid}');

      // Check cache first
      final cachedUser = _getFromCache<UserModel>('user_profile');
      if (cachedUser != null) {
        currentUser.value = cachedUser;
        userName.value = cachedUser.name;
        print(
            'DashboardController: Loaded user from cache: ${cachedUser.name}');
        return;
      }

      // Load from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      UserModel userModel;

      if (userDoc.exists) {
        print('DashboardController: User document exists in Firestore');
        final userData = userDoc.data()!;
        userModel = UserModel.fromFirestore(userDoc, userData);

        // Check if user info needs updating
        if (_checkUserInfoUpdate(user, userData)) {
          print('DashboardController: Updating user info in Firestore');
          await _updateUserInfo(user);
        }
      } else {
        print('DashboardController: Creating new user document');
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
          'DashboardController: User profile loaded successfully: ${userModel.name}');
    } catch (e) {
      print('DashboardController: Error loading user profile: $e');
      // Fallback to auth user info
      final user = _auth.currentUser;
      userName.value =
          user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    }
  }

  /// Check if user info needs updating
  bool _checkUserInfoUpdate(User user, Map<String, dynamic> userData) {
    return userData['name'] != user.displayName ||
        userData['email'] != user.email ||
        userData['photoUrl'] != user.photoURL;
  }

  /// Update user info in Firestore
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
      userName.value = updateData['name'] as String;

      print('DashboardController: User info updated successfully');
    } catch (e) {
      print('DashboardController: Error updating user info: $e');
    }
  }

  /// Create new user document
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

    print('DashboardController: New user created: $displayName');
    return newUser;
  }

  /// Check premium status
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

      print(
          'DashboardController: Premium status checked: ${isUserPremium.value}');
    } catch (e) {
      print('DashboardController: Error checking premium status: $e');
      isUserPremium.value = false;
    }
  }

  // ===== FIREBASE LISTENERS SETUP =====

  /// Set up all Firebase real-time listeners
  Future<void> _setupFirebaseListeners() async {
    if (currentUserId.value.isEmpty) {
      print('DashboardController: Cannot setup listeners - no user ID');
      return;
    }

    try {
      print(
          'DashboardController: Setting up Firebase listeners for user: ${currentUserId.value}');

      // User data listener
      _setupUserDataListener();

      // Schedules listener (most important for dashboard)
      _setupSchedulesListener();

      // Blocked apps listener
      _setupBlockedAppsListener();

      // Usage logs listener
      _setupUsageLogListener();

      print('DashboardController: All Firebase listeners setup complete');
    } catch (e) {
      print('DashboardController: Error setting up Firebase listeners: $e');
    }
  }

  /// Set up user data real-time listener
  void _setupUserDataListener() {
    _userDataListener = _firestore
        .collection('users')
        .doc(currentUserId.value)
        .snapshots()
        .listen(
      _handleUserDataSnapshot,
      onError: (error) {
        print('DashboardController: User data listener error: $error');
      },
    );
  }

  /// Set up schedules real-time listener
  void _setupSchedulesListener() {
    _scheduleListener = _firestore
        .collection('users')
        .doc(currentUserId.value)
        .collection('schedules')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      _handleScheduleSnapshot,
      onError: (error) {
        print('DashboardController: Schedule listener error: $error');
        schedulesError.value = 'Failed to load schedules: $error';
      },
    );
  }

  /// Set up blocked apps real-time listener
  void _setupBlockedAppsListener() {
    _blockedAppsListener = _firestore
        .collection('users')
        .doc(currentUserId.value)
        .collection('blocked_apps')
        .snapshots()
        .listen(
      _handleBlockedAppsSnapshot,
      onError: (error) {
        print('DashboardController: Blocked apps listener error: $error');
      },
    );
  }

  /// Set up usage logs real-time listener for today
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
        print('DashboardController: Usage log listener error: $error');
      },
    );
  }

  // ===== FIREBASE SNAPSHOT HANDLERS =====

  /// Handle user data snapshot updates
  void _handleUserDataSnapshot(DocumentSnapshot snapshot) {
    try {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        print('DashboardController: User data snapshot received');

        // Update user statistics
        totalSavedTime.value = Duration(seconds: data['totalSavedTime'] ?? 0);
        totalUnblockCount.value = data['totalUnblocks'] ?? 0;
        currentStreak.value = data['currentStreak'] ?? 0;
        longestStreak.value = data['longestStreak'] ?? 0;
        isUserPremium.value = data['isPremium'] ?? false;

        // Update user name if changed
        final newName = data['name'] ?? userName.value;
        if (newName != userName.value) {
          userName.value = newName;
          print('DashboardController: User name updated to: $newName');
        }
      }
    } catch (e) {
      print('DashboardController: Error handling user data snapshot: $e');
    }
  }

  /// Handle schedule snapshot updates - FIXED VERSION
  void _handleScheduleSnapshot(QuerySnapshot snapshot) {
    try {
      isLoadingSchedules.value = true;
      schedulesError.value = '';

      print(
          'DashboardController: Schedule snapshot received with ${snapshot.docs.length} documents');

      final scheduleList = <ScheduleModel>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Add document ID to data if not present
          if (!data.containsKey('id')) {
            data['id'] = doc.id;
          }

          print('DashboardController: Processing schedule document ${doc.id}');
          print('DashboardController: Document data: $data');

          // Try multiple parsing methods
          ScheduleModel? schedule;

          // First try: Use fromFirestore if available
          try {
            schedule = ScheduleModel.fromFirestore(doc, data);
            print(
                'DashboardController: Successfully loaded schedule with fromFirestore: ${schedule.title}');
          } catch (e) {
            print(
                'DashboardController: fromFirestore failed for ${doc.id}: $e');

            // Second try: Use fromMap if available
            try {
              schedule = ScheduleModel.fromMap(data);
              print(
                  'DashboardController: Successfully loaded schedule with fromMap: ${schedule.title}');
            } catch (e2) {
              print('DashboardController: fromMap failed for ${doc.id}: $e2');

              // Third try: Use alternative parsing method
              schedule = _parseScheduleAlternative(doc.id, data);
              if (schedule != null) {
                print(
                    'DashboardController: Successfully loaded schedule with alternative method: ${schedule.title}');
              }
            }
          }

          if (schedule != null) {
            scheduleList.add(schedule);
          } else {
            print(
                'DashboardController: All parsing methods failed for ${doc.id}');
          }
        } catch (e) {
          print('DashboardController: Error processing schedule ${doc.id}: $e');
        }
      }

      // Update all schedules with explicit notification
      allSchedules.assignAll(scheduleList);
      print(
          'DashboardController: Updated allSchedules with ${allSchedules.length} schedules');

      // Update derived schedule lists
      _updateDerivedScheduleLists();

      // Force UI update
      allSchedules.refresh();
      latestSchedules.refresh();
      activeSchedules.refresh();
      todaySchedules.refresh();

      print(
          'DashboardController: Schedule processing completed - ${scheduleList.length} total, ${activeSchedules.length} active, ${todaySchedules.length} today');
    } catch (e) {
      print('DashboardController: Error handling schedule snapshot: $e');
      schedulesError.value = 'Error loading schedules: $e';
    } finally {
      isLoadingSchedules.value = false;
    }
  }

  /// Alternative schedule parsing method for fallback
  ScheduleModel? _parseScheduleAlternative(
      String docId, Map<String, dynamic> data) {
    try {
      // Parse time fields safely
      TimeOfDay parseTime(dynamic timeData) {
        if (timeData is Map<String, dynamic>) {
          return TimeOfDay(
            hour: timeData['hour'] ?? 0,
            minute: timeData['minute'] ?? 0,
          );
        } else if (timeData is String) {
          final parts = timeData.split(':');
          return TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
          );
        }
        return const TimeOfDay(hour: 8, minute: 0);
      }

      // Parse color safely
      Color parseColor(dynamic colorData) {
        if (colorData is int) {
          return Color(colorData);
        } else if (colorData is String) {
          return Color(int.tryParse(colorData) ?? 0xFF2196F3);
        }
        return Colors.blue;
      }

      // Parse icon safely
      IconData parseIcon(dynamic iconData) {
        if (iconData is int) {
          return IconData(iconData, fontFamily: 'MaterialIcons');
        }
        return Icons.schedule;
      }

      // Parse days list safely
      List<int> parseDays(dynamic daysData) {
        if (daysData is List) {
          return daysData
              .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 1)
              .toList();
        }
        return [1, 2, 3, 4, 5]; // Default to weekdays
      }

      // Parse blocked apps list safely
      List<String> parseBlockedApps(dynamic appsData) {
        if (appsData is List) {
          return appsData.map((e) => e.toString()).toList();
        }
        return [];
      }

      // Parse DateTime safely
      DateTime parseDateTime(dynamic dateData) {
        if (dateData is Timestamp) {
          return dateData.toDate();
        } else if (dateData is String) {
          return DateTime.tryParse(dateData) ?? DateTime.now();
        }
        return DateTime.now();
      }

      return ScheduleModel(
        id: docId,
        title: data['title']?.toString() ?? 'Untitled Schedule',
        icon: parseIcon(data['icon']),
        iconColor: parseColor(data['iconColor']),
        days: parseDays(data['days']),
        startTime: parseTime(data['startTime']),
        endTime: parseTime(data['endTime']),
        blockedApps: parseBlockedApps(data['blockedApps']),
        isActive: data['isActive'] ?? true,
        createdAt: parseDateTime(data['createdAt']),
        lastTriggered: data['lastTriggered'] != null
            ? parseDateTime(data['lastTriggered'])
            : null,
      );
    } catch (e) {
      print('DashboardController: Alternative parsing failed: $e');
      return null;
    }
  }

  /// Update all derived schedule lists - FIXED VERSION
  void _updateDerivedScheduleLists() {
    try {
      final scheduleList = allSchedules.toList();

      // Update latest 3 schedules for dashboard display
      _updateLatestSchedules(scheduleList);

      // Update active schedules with explicit assignment
      final activeList = scheduleList.where((s) => s.isActive).toList();
      activeSchedules.assignAll(activeList);
      print(
          'DashboardController: Updated activeSchedules with ${activeSchedules.length} schedules');

      // Update today's schedules
      _updateTodaySchedules();

      // Update currently active schedule
      _updateCurrentActiveSchedule();

      // Update notification count
      _updateNotificationCount();
    } catch (e) {
      print('DashboardController: Error updating derived schedule lists: $e');
    }
  }

  /// Handle blocked apps snapshot updates
  void _handleBlockedAppsSnapshot(QuerySnapshot snapshot) {
    try {
      final blockedAppsList = <AppModel>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final app = AppModel.fromFirestore(doc);
          blockedAppsList.add(app);
        } catch (e) {
          print(
              'DashboardController: Error processing blocked app ${doc.id}: $e');
        }
      }

      blockedApps.value = blockedAppsList;
      print(
          'DashboardController: Blocked apps updated - ${blockedAppsList.length} apps');
    } catch (e) {
      print('DashboardController: Error handling blocked apps snapshot: $e');
    }
  }

  /// Handle usage log snapshot updates
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
          print(
              'DashboardController: Error processing usage log ${doc.id}: $e');
        }
      }

      savedTimeToday.value = dailySavedTime;
      unblockCount.value = dailyUnblockCount;

      // Recalculate progress percentages
      _calculateProgressPercentages();
      _updateNotificationCount();

      print(
          'DashboardController: Daily progress updated - Saved: ${dailySavedTime.inMinutes}min, Unblocks: $dailyUnblockCount');
    } catch (e) {
      print('DashboardController: Error handling usage log snapshot: $e');
    }
  }

  // ===== SCHEDULE MANAGEMENT METHODS =====

  /// Update latest 3 schedules for dashboard display - FIXED VERSION
  void _updateLatestSchedules(List<ScheduleModel> scheduleList) {
    try {
      // Sort by creation date (newest first) and take first 3
      final sortedSchedules = scheduleList.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final latestList = sortedSchedules.take(3).toList();
      latestSchedules.assignAll(latestList);

      print(
          'DashboardController: Latest schedules updated - ${latestSchedules.length} schedules');

      // Debug print schedule details
      for (final schedule in latestList) {
        print(
            'DashboardController: Latest schedule: ${schedule.title} (${schedule.id})');
      }
    } catch (e) {
      print('DashboardController: Error updating latest schedules: $e');
    }
  }

  /// Update today's applicable schedules - FIXED VERSION
  void _updateTodaySchedules() {
    try {
      final today = DateTime.now().weekday;
      final todayList = activeSchedules
          .where((schedule) => schedule.days.contains(today))
          .toList();

      todaySchedules.assignAll(todayList);

      print(
          'DashboardController: Today\'s schedules updated - ${todaySchedules.length} schedules for day $today');

      // Debug print today's schedules
      for (final schedule in todayList) {
        print(
            'DashboardController: Today\'s schedule: ${schedule.title} (Days: ${schedule.days})');
      }
    } catch (e) {
      print('DashboardController: Error updating today\'s schedules: $e');
    }
  }

  /// Update currently active schedule - FIXED VERSION
  void _updateCurrentActiveSchedule() {
    try {
      final now = DateTime.now();
      final currentDay = now.weekday;
      final currentTime = TimeOfDay.now();

      ScheduleModel? activeSchedule;

      for (final schedule in activeSchedules) {
        if (schedule.days.contains(currentDay)) {
          if (_isTimeInRange(
              currentTime, schedule.startTime, schedule.endTime)) {
            activeSchedule = schedule;
            print(
                'DashboardController: Found currently active schedule: ${schedule.title}');
            break;
          }
        }
      }

      currentActiveSchedule.value = activeSchedule;

      if (activeSchedule != null) {
        print(
            'DashboardController: Currently active schedule: ${activeSchedule.title}');
      } else {
        print('DashboardController: No currently active schedule');
      }
    } catch (e) {
      print('DashboardController: Error updating current active schedule: $e');
    }
  }

  /// Check if current time is within schedule range
  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    // Handle overnight schedules
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }

    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  // ===== SCHEDULE PUBLIC API METHODS =====

  /// Force refresh schedules from Firebase
  Future<void> refreshSchedules() async {
    try {
      if (currentUserId.value.isEmpty) {
        print('DashboardController: Cannot refresh schedules - no user ID');
        return;
      }

      print('DashboardController: Force refreshing schedules...');

      // Manually trigger a refresh by re-querying Firebase
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId.value)
          .collection('schedules')
          .orderBy('createdAt', descending: true)
          .get();

      _handleScheduleSnapshot(snapshot);

      print('DashboardController: Force refresh completed');
    } catch (e) {
      print('DashboardController: Error force refreshing schedules: $e');
      schedulesError.value = 'Failed to refresh schedules: $e';
    }
  }

  /// Get latest 3 schedules for dashboard display - ENHANCED
  List<ScheduleModel> getLatestSchedules() {
    final latest = latestSchedules.toList();
    print('DashboardController: Returning ${latest.length} latest schedules');

    // If no latest schedules but we have schedules, update latest schedules
    if (latest.isEmpty && allSchedules.isNotEmpty) {
      _updateLatestSchedules(allSchedules.toList());
      return latestSchedules.toList();
    }

    return latest;
  }

  /// Get all user schedules - ENHANCED
  List<ScheduleModel> getAllSchedules() {
    final all = allSchedules.toList();
    print('DashboardController: Returning ${all.length} total schedules');
    return all;
  }

  /// Get active schedules only - ENHANCED
  List<ScheduleModel> getActiveSchedules() {
    final active = activeSchedules.toList();
    print('DashboardController: Returning ${active.length} active schedules');
    return active;
  }

  /// Get today's applicable schedules - ENHANCED
  List<ScheduleModel> getTodaySchedules() {
    final today = todaySchedules.toList();
    print('DashboardController: Returning ${today.length} today\'s schedules');
    return today;
  }

  /// Get currently running schedule
  ScheduleModel? getCurrentActiveSchedule() {
    return currentActiveSchedule.value;
  }

  /// Check if any schedule is currently active
  bool isAnyScheduleActiveNow() {
    return currentActiveSchedule.value != null;
  }

  /// Get schedule by ID
  ScheduleModel? getScheduleById(String scheduleId) {
    try {
      return allSchedules
          .firstWhereOrNull((schedule) => schedule.id == scheduleId);
    } catch (e) {
      print('DashboardController: Error getting schedule by ID: $e');
      return null;
    }
  }

  /// Get schedule statistics - ENHANCED
  Map<String, dynamic> getScheduleStatistics() {
    final totalSchedules = allSchedules.length;
    final activeSchedulesCount = activeSchedules.length;
    final inactiveSchedules = totalSchedules - activeSchedulesCount;
    final todaySchedulesCount = todaySchedules.length;
    final currentlyActive = isAnyScheduleActiveNow();

    final stats = {
      'totalSchedules': totalSchedules,
      'activeSchedules': activeSchedulesCount,
      'inactiveSchedules': inactiveSchedules,
      'todaySchedules': todaySchedulesCount,
      'currentlyActive': currentlyActive,
      'hasSchedules': totalSchedules > 0,
    };

    print('DashboardController: Schedule statistics: $stats');
    return stats;
  }

  /// Toggle schedule active state
  Future<bool> toggleScheduleActive(String scheduleId, bool isActive) async {
    try {
      if (currentUserId.value.isEmpty) {
        print('DashboardController: Cannot toggle schedule - no user ID');
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId.value)
          .collection('schedules')
          .doc(scheduleId)
          .update({'isActive': isActive});

      print('DashboardController: Schedule $scheduleId toggled to $isActive');
      return true;
    } catch (e) {
      print('DashboardController: Error toggling schedule: $e');
      return false;
    }
  }

  /// Delete schedule
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      if (currentUserId.value.isEmpty) {
        print('DashboardController: Cannot delete schedule - no user ID');
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId.value)
          .collection('schedules')
          .doc(scheduleId)
          .delete();

      print('DashboardController: Schedule $scheduleId deleted');
      return true;
    } catch (e) {
      print('DashboardController: Error deleting schedule: $e');
      return false;
    }
  }

  // ===== DEBUG METHODS =====

  /// Debug method to print current schedule state
  void debugPrintScheduleState() {
    print('=== DASHBOARD CONTROLLER SCHEDULE DEBUG ===');
    print('User ID: ${currentUserId.value}');
    print('Is Loading Schedules: ${isLoadingSchedules.value}');
    print('Schedules Error: ${schedulesError.value}');
    print('All Schedules Count: ${allSchedules.length}');
    print('Latest Schedules Count: ${latestSchedules.length}');
    print('Active Schedules Count: ${activeSchedules.length}');
    print('Today Schedules Count: ${todaySchedules.length}');
    print(
        'Current Active Schedule: ${currentActiveSchedule.value?.title ?? 'None'}');

    print('\nAll Schedules Details:');
    for (int i = 0; i < allSchedules.length; i++) {
      final schedule = allSchedules[i];
      print(
          '  [$i] ${schedule.title} (ID: ${schedule.id}, Active: ${schedule.isActive})');
    }

    print('\nLatest Schedules Details:');
    for (int i = 0; i < latestSchedules.length; i++) {
      final schedule = latestSchedules[i];
      print('  [$i] ${schedule.title} (ID: ${schedule.id})');
    }

    print('=== END DEBUG ===');
  }

  /// Test method to create a sample schedule (for debugging)
  Future<void> createTestSchedule() async {
    try {
      if (currentUserId.value.isEmpty) {
        print('DashboardController: Cannot create test schedule - no user ID');
        return;
      }

      final testSchedule = {
        'title': 'Test Schedule',
        'icon': Icons.schedule.codePoint,
        'iconColor': Colors.blue.value,
        'days': [1, 2, 3, 4, 5], // Weekdays
        'startTime': {'hour': 9, 'minute': 0},
        'endTime': {'hour': 17, 'minute': 0},
        'blockedApps': ['com.facebook.katana', 'com.instagram.android'],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUserId.value)
          .collection('schedules')
          .add(testSchedule);

      print('DashboardController: Test schedule created successfully');
    } catch (e) {
      print('DashboardController: Error creating test schedule: $e');
    }
  }

  // ===== PROGRESS AND STATISTICS =====

  /// Calculate progress percentages for UI
  void _calculateProgressPercentages() {
    try {
      // Calculate saved time progress (target: 4 hours per day)
      const targetSavedTime = Duration(hours: 4);
      progressPercentage.value =
          (savedTimeToday.value.inMinutes / targetSavedTime.inMinutes)
              .clamp(0.0, 1.0);

      // Calculate unblock progress (target: maximum 5 unblocks per day)
      const targetUnblockLimit = 5;
      uncompletedPercentage.value =
          (unblockCount.value / targetUnblockLimit).clamp(0.0, 1.0);

      print(
          'DashboardController: Progress percentages updated - Saved: ${(progressPercentage.value * 100).round()}%, Unblocks: ${(uncompletedPercentage.value * 100).round()}%');
    } catch (e) {
      print('DashboardController: Error calculating progress percentages: $e');
    }
  }

  /// Update notification count for UI badge
  void _updateNotificationCount() {
    try {
      int count = 0;

      // Active schedules count
      count += activeSchedules.length;

      // Quick mode active
      if (Get.isRegistered<QuickModeController>() &&
          _quickModeController.isQuickModeActive.value) {
        count += 1;
      }

      // Error messages
      if (errorMessage.value.isNotEmpty || schedulesError.value.isNotEmpty) {
        count += 1;
      }

      notificationCount.value = count;
    } catch (e) {
      print('DashboardController: Error updating notification count: $e');
    }
  }

  // ===== DATA LOADING =====

  /// Load initial data after authentication
  Future<void> _loadInitialData() async {
    try {
      print('DashboardController: Loading initial data...');

      // Load apps and statistics in parallel
      await Future.wait([
        _loadInstalledApps(),
        _loadStatistics(),
      ]);

      print('DashboardController: Initial data loaded successfully');
    } catch (e) {
      print('DashboardController: Error loading initial data: $e');
    }
  }

  /// Load installed apps
  Future<void> _loadInstalledApps() async {
    try {
      isLoadingApps.value = true;

      // Check cache first
      final cachedApps = _getFromCache<List<AppModel>>('installed_apps');
      if (cachedApps != null) {
        allApps.value = cachedApps;
        if (Get.isRegistered<QuickModeController>()) {
          _quickModeController.setAvailableApps(cachedApps);
        }
        return;
      }

      print('DashboardController: Loading installed apps...');

      // Load from fallback for now (can be replaced with device apps loading)
      allApps.value = _getFallbackApps();

      // Set apps in QuickMode controller
      if (Get.isRegistered<QuickModeController>()) {
        _quickModeController.setAvailableApps(allApps);
      }

      // Cache the apps
      _addToCache('installed_apps', allApps.toList());

      print('DashboardController: Loaded ${allApps.length} apps');
    } catch (e) {
      print('DashboardController: Error loading apps: $e');
      allApps.value = _getFallbackApps();
    } finally {
      isLoadingApps.value = false;
    }
  }

  /// Load user statistics
  Future<void> _loadStatistics() async {
    try {
      // Statistics are handled by real-time listeners
      // Load cached values if available
      final cachedStats =
          _getFromCache<Map<String, dynamic>>('user_statistics');
      if (cachedStats != null) {
        totalSavedTime.value =
            Duration(seconds: cachedStats['totalSavedTime'] ?? 0);
        totalUnblockCount.value = cachedStats['totalUnblocks'] ?? 0;
        currentStreak.value = cachedStats['currentStreak'] ?? 0;
        longestStreak.value = cachedStats['longestStreak'] ?? 0;
      }
    } catch (e) {
      print('DashboardController: Error loading statistics: $e');
    }
  }

  /// Get fallback apps for testing
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
    ];
  }

  // ===== MONITORING AND SYNC =====

  /// Start periodic monitoring
  void _startMonitoring() {
    // Progress update timer
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _updateProgress();
    });

    // Sync timer for offline support
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _performPeriodicSync();
    });

    // Schedule monitoring timer
    _scheduleMonitorTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      _updateCurrentActiveSchedule();
    });

    print('DashboardController: Monitoring started');
  }

  /// Update progress data
  Future<void> _updateProgress() async {
    try {
      _calculateProgressPercentages();
      _updateNotificationCount();
    } catch (e) {
      print('DashboardController: Error updating progress: $e');
    }
  }

  /// Perform periodic sync
  Future<void> _performPeriodicSync() async {
    try {
      _updateLastSyncTime();
      await _checkConnectionStatus();
    } catch (e) {
      print('DashboardController: Error in periodic sync: $e');
    }
  }

  /// Check connection status
  Future<void> _checkConnectionStatus() async {
    try {
      await _firestore.collection('_test').limit(1).get();
      isConnected.value = true;
    } catch (e) {
      isConnected.value = false;
      print('DashboardController: Connection check failed: $e');
    }
  }

  /// Update last sync time
  void _updateLastSyncTime() {
    final now = DateTime.now();
    lastSyncTime.value =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ===== CACHE MANAGEMENT =====

  /// Get data from cache
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

  /// Add data to cache
  void _addToCache<T>(String key, T value) {
    final cacheKey = '$_cachePrefix$key';
    _cache[cacheKey] = value;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Clear all cache
  void _clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // ===== PUBLIC API METHODS =====

  /// User information getters
  String get currentLoggedUsername => userName.value;
  String get currentUserEmail => userEmail.value;
  String get currentUserPhotoUrl => userPhotoUrl.value;
  bool get isPremiumUser => isUserPremium.value;
  bool get isUserAuthenticated => isAuthenticated.value;
  bool get isCheckingAuthentication => isCheckingAuth.value;

  /// Progress text getters
  String get savedTimeText =>
      "You've saved ${formatDuration(savedTimeToday.value)} today!";

  String get unblockText {
    if (unblockCount.value == 0) {
      return "No app unblocks today - Great job!";
    }
    return "You've unblocked apps ${unblockCount.value} times today";
  }

  String get lastSyncText =>
      lastSyncTime.value.isEmpty ? 'Never' : lastSyncTime.value;

  /// Format duration helper
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  /// Sign out method
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Auth listener will handle the rest
    } catch (e) {
      print('DashboardController: Error signing out: $e');
      rethrow;
    }
  }

  /// Refresh all data
  Future<void> refreshData() async {
    try {
      await Future.wait([
        _loadInstalledApps(),
        _loadStatistics(),
        refreshSchedules(), // Added schedule refresh
      ]);
      _updateLastSyncTime();
    } catch (e) {
      print('DashboardController: Error refreshing data: $e');
      rethrow;
    }
  }

  // ===== ERROR HANDLING =====

  /// Handle initialization errors
  Future<void> _handleInitializationError(dynamic error) async {
    print('DashboardController: Handling initialization error: $error');

    // Show user-friendly error message
    Get.snackbar(
      'Initialization Error',
      'Some features may not work properly. Please restart the app.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );

    // Try to recover with fallback data
    try {
      allApps.value = _getFallbackApps();
      userName.value = 'User';
    } catch (e) {
      print('DashboardController: Error recovery failed: $e');
    }
  }

  // ===== CLEANUP METHODS =====

  /// Clear all user data
  void _clearAllData() {
    // User data
    currentUser.value = null;
    userName.value = 'User';
    userEmail.value = '';
    currentUserId.value = '';
    userPhotoUrl.value = '';
    isUserPremium.value = false;

    // Schedule data
    allSchedules.clear();
    latestSchedules.clear();
    activeSchedules.clear();
    todaySchedules.clear();
    currentActiveSchedule.value = null;

    // App data
    allApps.clear();
    blockedApps.clear();

    // Progress data
    savedTimeToday.value = Duration.zero;
    totalSavedTime.value = Duration.zero;
    unblockCount.value = 0;
    totalUnblockCount.value = 0;
    progressPercentage.value = 0.0;
    uncompletedPercentage.value = 0.0;
    notificationCount.value = 0;
    currentStreak.value = 0;
    longestStreak.value = 0;

    // UI state
    errorMessage.value = '';
    schedulesError.value = '';
    lastSyncTime.value = '';
  }

  /// Teardown all listeners
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

  /// Cleanup method called on controller disposal
  void _cleanup() {
    print('DashboardController: Starting cleanup...');

    // Cancel all timers
    _progressTimer?.cancel();
    _syncTimer?.cancel();
    _scheduleMonitorTimer?.cancel();

    // Teardown listeners
    _teardownListeners();

    // Clear cache
    _clearCache();

    print('DashboardController: Cleanup completed');
  }
}
