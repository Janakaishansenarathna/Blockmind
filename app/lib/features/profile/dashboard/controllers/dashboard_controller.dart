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
import '../../../data/services/schedule_service.dart';
import '../../../utils/constants/app_colors.dart';
import 'quick_mood_controller.dart';

/// Dashboard Controller
/// Handles dashboard-related functionality such as authentication, schedules, and monitoring.
class DashboardController extends GetxController {
  // ===== CONSTANTS =====
  static const String _cachePrefix = 'dashboard_';
  static const Duration _cacheTimeout = Duration(minutes: 5);
  static const Duration _scheduleRefreshInterval = Duration(seconds: 30);
  static const Duration _progressUpdateInterval = Duration(minutes: 1);
  static const Duration _syncInterval = Duration(minutes: 5);

  // ===== SERVICES =====
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAppBlockerService _blockerService = FirebaseAppBlockerService();
  final AppBlockerManager _appBlockerManager = AppBlockerManager();
  final ScheduleService _scheduleService = ScheduleService();

  late QuickModeController _quickModeController;

  // ===== OBSERVABLES =====
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxList<ScheduleModel> allSchedules = <ScheduleModel>[].obs;
  final RxList<AppModel> allApps = <AppModel>[].obs;
  final RxBool isAuthenticated = false.obs;
  final RxBool isInitializing = false.obs;

  // ===== CACHE =====
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // ===== TIMERS =====
  Timer? _progressTimer;
  Timer? _syncTimer;
  Timer? _scheduleMonitorTimer;

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
      await _initializeServices();
      _setupAuthListener();
      await _checkAuthenticationState();
    } catch (e) {
      _handleInitializationError(e);
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> _initializeServices() async {
    await _blockerService.initialize();
    await _appBlockerManager.initialize();
    _quickModeController = Get.put(QuickModeController());
  }

  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _handleUserSignIn(user);
      } else {
        await _handleUserSignOut();
      }
    });
  }

  Future<void> _checkAuthenticationState() async {
    final user = _auth.currentUser;
    if (user != null) {
      isAuthenticated.value = true;
      await _handleUserSignIn(user);
    } else {
      isAuthenticated.value = false;
      _redirectToLogin();
    }
  }

  // ===== AUTHENTICATION =====
  Future<void> _handleUserSignIn(User user) async {
    currentUser.value = await _loadUserProfile(user);
    await _setupFirebaseListeners();
    _startMonitoring();
  }

  Future<void> _handleUserSignOut() async {
    isAuthenticated.value = false;
    _clearAllData();
    _redirectToLogin();
  }

  void _redirectToLogin() {
    Get.offAllNamed('/login');
  }

  Future<UserModel> _loadUserProfile(User user) async {
    final cachedUser = _getFromCache<UserModel>('user_profile');
    if (cachedUser != null) return cachedUser;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      return UserModel.fromFirestore(userDoc, userData);
    } else {
      return _createNewUser(user);
    }
  }

  Future<UserModel> _createNewUser(User user) async {
    final newUser = UserModel(
      id: user.uid,
      name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
      email: user.email ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(newUser.toFirestore());
    return newUser;
  }

  // ===== SCHEDULE MANAGEMENT =====
  Future<void> refreshSchedules() async {
    final refreshedSchedules =
        await _scheduleService.getAllSchedules(currentUser.value!.id);
    allSchedules.assignAll(refreshedSchedules);
  }

  // ===== MONITORING =====
  void _startMonitoring() {
    _progressTimer =
        Timer.periodic(_progressUpdateInterval, (_) => _updateProgress());
    _syncTimer = Timer.periodic(_syncInterval, (_) => _performPeriodicSync());
    _scheduleMonitorTimer =
        Timer.periodic(_scheduleRefreshInterval, (_) => refreshSchedules());
  }

  Future<void> _updateProgress() async {
    // Update progress logic here
  }

  Future<void> _performPeriodicSync() async {
    // Sync logic here
  }

  // ===== CACHE MANAGEMENT =====
  T? _getFromCache<T>(String key) {
    final cacheKey = '$_cachePrefix$key';
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheTimeout) {
      return _cache[cacheKey] as T?;
    }
    return null;
  }

  void _addToCache<T>(String key, T value) {
    final cacheKey = '$_cachePrefix$key';
    _cache[cacheKey] = value;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  void _clearAllData() {
    currentUser.value = null;
    allSchedules.clear();
    allApps.clear();
  }

  void _cleanup() {
    _progressTimer?.cancel();
    _syncTimer?.cancel();
    _scheduleMonitorTimer?.cancel();
  }

  // ===== ERROR HANDLING =====
  void _handleInitializationError(dynamic error) {
    Get.snackbar(
      'Initialization Error',
      'Failed to initialize the dashboard. Please restart the app.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
