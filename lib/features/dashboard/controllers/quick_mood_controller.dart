// controllers/quick_mode_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/local/models/app_model.dart';

class QuickModeController extends GetxController {
  // Firebase services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Quick Mode observables
  final RxBool isQuickModeActive = false.obs;
  final RxString activeQuickBlockId = ''.obs;
  final RxInt remainingTimeSeconds = 0.obs;
  final RxList<String> blockedAppIds = <String>[].obs;
  final RxList<AppModel> availableApps = <AppModel>[].obs;
  final RxList<AppModel> selectedApps = <AppModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt selectedDurationMinutes = 30.obs;

  // Enhanced Quick Mode features
  final RxBool isPaused = false.obs;
  final RxInt totalSessionsToday = 0.obs;
  final Rx<Duration> totalBlockingTimeToday = Duration.zero.obs;
  final RxInt consecutiveSuccessfulSessions = 0.obs;
  final RxDouble completionRate = 0.0.obs;
  final RxString lastSessionEndTime = ''.obs;

  // Mood tracking observables
  final RxInt currentMood = 0.obs;
  final RxString moodNotes = ''.obs;
  final RxList<Map<String, dynamic>> moodHistory = <Map<String, dynamic>>[].obs;
  final RxDouble averageMood = 0.0.obs;
  final RxInt moodStreak = 0.obs;
  final RxBool hasMoodToday = false.obs;

  // Quick Mood feature
  final RxInt quickMoodLevel = 0.obs;
  final RxString quickMoodEmoji = ''.obs;
  final RxBool isQuickMoodActive = false.obs;
  final Rx<DateTime> quickMoodStartTime = DateTime.now().obs;

  // Preset and customization
  final RxList<QuickModePreset> availablePresets = <QuickModePreset>[].obs;
  final RxString selectedPresetId = ''.obs;
  final RxBool hasCustomPresets = false.obs;

  // Performance and statistics
  final RxList<Map<String, dynamic>> sessionHistory =
      <Map<String, dynamic>>[].obs;
  final RxInt longestSession = 0.obs;
  final RxInt shortestSession = 0.obs;
  final RxDouble averageSessionDuration = 0.0.obs;

  // Internal state
  Timer? _countdownTimer;
  Timer? _quickMoodTimer;
  String? _currentUserId;
  StreamSubscription? _quickModeListener;
  StreamSubscription? _statisticsListener;
  StreamSubscription? _moodListener;

  // Cache and storage
  static const String selectedAppsKey = 'quick_mode_selected_apps';
  static const String selectedDurationKey = 'quick_mode_duration';
  static const String presetsKey = 'quick_mode_presets';
  static const String quickMoodKey = 'quick_mood_settings';
  static const Duration _cacheTimeout = Duration(minutes: 10);
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
    try {
      await _loadSavedData();
      await _initializePresets();
      print('QuickModeController: Controller initialized');
    } catch (e) {
      print('QuickModeController: Initialization error: $e');
      _handleError('Failed to initialize Quick Mode', e);
    }
  }

  void setUserId(String userId) {
    if (_currentUserId == userId) return;

    _currentUserId = userId;
    _setupFirebaseListeners();
    _initializeUserData();
  }

  void _setupFirebaseListeners() {
    if (_currentUserId == null) return;

    _teardownListeners();

    // Quick mode status listener
    _quickModeListener = _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('quick_modes')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          _handleQuickModeSnapshot,
          onError: (error) =>
              print('QuickModeController: Quick mode listener error: $error'),
        );

    // Statistics listener
    _statisticsListener = _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('quick_mode_stats')
        .doc('summary')
        .snapshots()
        .listen(
          _handleStatisticsSnapshot,
          onError: (error) =>
              print('QuickModeController: Statistics listener error: $error'),
        );

    // Mood listener
    _moodListener = _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('moods')
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots()
        .listen(
          _handleMoodSnapshot,
          onError: (error) =>
              print('QuickModeController: Mood listener error: $error'),
        );

    print('QuickModeController: Firebase listeners setup complete');
  }

  Future<void> _initializeUserData() async {
    try {
      isLoading.value = true;

      await Future.wait([
        _loadTodayStatistics(),
        _loadTodayMood(),
        _loadSessionHistory(),
        _loadQuickMoodSettings(),
      ]);
    } catch (e) {
      _handleError('Failed to load user data', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initializePresets() async {
    try {
      final presets = getQuickModePresets();
      availablePresets.value = presets;

      // Load custom presets if any
      await _loadCustomPresets();
    } catch (e) {
      print('QuickModeController: Error initializing presets: $e');
    }
  }

  // ===== FIREBASE LISTENERS =====

  void _handleQuickModeSnapshot(QuerySnapshot snapshot) {
    try {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final endTime = (data['endTime'] as Timestamp).toDate();

        if (DateTime.now().isBefore(endTime)) {
          // Quick mode is active
          _updateActiveQuickMode(doc.id, data, endTime);
        } else {
          // Quick mode has expired
          _deactivateExpiredQuickMode(doc.id);
        }
      } else {
        // No active quick mode
        _resetQuickModeState();
      }
    } catch (e) {
      print('QuickModeController: Error handling quick mode snapshot: $e');
    }
  }

  void _updateActiveQuickMode(
      String docId, Map<String, dynamic> data, DateTime endTime) {
    activeQuickBlockId.value = docId;
    blockedAppIds.value = List<String>.from(data['blockedAppIds'] ?? []);
    isQuickModeActive.value = true;
    isPaused.value = data['isPaused'] ?? false;
    remainingTimeSeconds.value = endTime.difference(DateTime.now()).inSeconds;

    if (!isPaused.value && (_countdownTimer?.isActive != true)) {
      _startCountdownTimer();
    }
  }

  void _handleStatisticsSnapshot(DocumentSnapshot snapshot) {
    try {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        totalSessionsToday.value = data['totalSessionsToday'] ?? 0;
        totalBlockingTimeToday.value =
            Duration(seconds: data['totalBlockingTimeToday'] ?? 0);
        consecutiveSuccessfulSessions.value =
            data['consecutiveSuccessfulSessions'] ?? 0;
        completionRate.value = (data['completionRate'] ?? 0.0).toDouble();
        longestSession.value = data['longestSession'] ?? 0;
        shortestSession.value = data['shortestSession'] ?? 0;
        averageSessionDuration.value =
            (data['averageSessionDuration'] ?? 0.0).toDouble();
        lastSessionEndTime.value = data['lastSessionEndTime'] ?? '';

        print('QuickModeController: Statistics updated');
      }
    } catch (e) {
      print('QuickModeController: Error handling statistics snapshot: $e');
    }
  }

  void _handleMoodSnapshot(QuerySnapshot snapshot) {
    try {
      final history = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'moodLevel': data['moodLevel'] ?? 0,
          'notes': data['notes'] ?? '',
          'date': (data['date'] as Timestamp).millisecondsSinceEpoch,
          'createdAt':
              (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
        };
      }).toList();

      moodHistory.value = history;
      _updateMoodStatistics(history);
    } catch (e) {
      print('QuickModeController: Error handling mood snapshot: $e');
    }
  }

  void _updateMoodStatistics(List<Map<String, dynamic>> history) {
    if (history.isNotEmpty) {
      // Check if today's mood exists
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      hasMoodToday.value = history.any((mood) {
        final moodDate = DateTime.fromMillisecondsSinceEpoch(mood['date']);
        return moodDate.isAtSameMomentAs(todayStart);
      });

      // Calculate average mood
      final sum = history.fold<double>(
          0, (sum, mood) => sum + (mood['moodLevel'] as int));
      averageMood.value = sum / history.length;

      // Calculate mood streak
      moodStreak.value = _calculateMoodStreak(history);

      // Update current mood if exists today
      if (hasMoodToday.value) {
        final todayMood = history.firstWhere((mood) {
          final moodDate = DateTime.fromMillisecondsSinceEpoch(mood['date']);
          return moodDate.isAtSameMomentAs(todayStart);
        });
        currentMood.value = todayMood['moodLevel'];
        moodNotes.value = todayMood['notes'] ?? '';
      }
    }
  }

  int _calculateMoodStreak(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < history.length; i++) {
      final moodDate = DateTime.fromMillisecondsSinceEpoch(history[i]['date']);
      final expectedDate = today.subtract(Duration(days: i));

      if (moodDate.year == expectedDate.year &&
          moodDate.month == expectedDate.month &&
          moodDate.day == expectedDate.day) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ===== QUICK MODE OPERATIONS =====

  Future<bool> startQuickMode([int? durationMinutes]) async {
    if (selectedApps.isEmpty) {
      _showError('No Apps Selected', 'Please select at least one app to block');
      return false;
    }

    if (_currentUserId == null) {
      _showError('Authentication Error', 'User not authenticated');
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final duration = durationMinutes ?? selectedDurationMinutes.value;

      // Stop any existing quick mode
      if (isQuickModeActive.value) {
        await stopQuickMode();
      }

      print(
          'QuickModeController: Starting Quick Mode for $duration minutes with ${selectedApps.length} apps');

      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: duration));

      // Create quick mode document
      final quickModeData = {
        'userId': _currentUserId!,
        'durationMinutes': duration,
        'blockedAppIds': selectedApps.map((app) => app.id).toList(),
        'blockedApps': selectedApps.map((app) => app.toFirestore()).toList(),
        'isActive': true,
        'isPaused': false,
        'createdAt': FieldValue.serverTimestamp(),
        'startTime': Timestamp.fromDate(now),
        'endTime': Timestamp.fromDate(endTime),
        'endedAt': null,
        'completedSuccessfully': false,
        'presetUsed':
            selectedPresetId.value.isNotEmpty ? selectedPresetId.value : null,
      };

      final docRef = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .add(quickModeData);

      // Update blocked apps collection
      await _updateBlockedApps(docRef.id);

      // Update local state
      activeQuickBlockId.value = docRef.id;
      blockedAppIds.value = selectedApps.map((app) => app.id).toList();
      isQuickModeActive.value = true;
      isPaused.value = false;
      remainingTimeSeconds.value = duration * 60;

      // Start countdown timer
      _startCountdownTimer();

      // Update statistics
      await _updateSessionStatistics(isStart: true);

      _showSuccess('Quick Mode Started',
          'Blocking ${selectedApps.length} apps for $duration minutes');

      print(
          'QuickModeController: Quick mode started successfully: ${docRef.id}');
      return true;
    } catch (e) {
      _handleError('Failed to start Quick Mode', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> stopQuickMode({bool completedSuccessfully = false}) async {
    if (!isQuickModeActive.value || _currentUserId == null) return;

    try {
      isLoading.value = true;

      print('QuickModeController: Stopping Quick Mode');

      // Update quick mode document
      if (activeQuickBlockId.value.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_currentUserId!)
            .collection('quick_modes')
            .doc(activeQuickBlockId.value)
            .update({
          'isActive': false,
          'endedAt': FieldValue.serverTimestamp(),
          'completedSuccessfully': completedSuccessfully,
          'actualDuration':
              selectedDurationMinutes.value * 60 - remainingTimeSeconds.value,
        });
      }

      // Remove blocked apps
      await _removeBlockedApps();

      // Update statistics
      await _updateSessionStatistics(
          isEnd: true, completedSuccessfully: completedSuccessfully);

      // Reset state
      _resetQuickModeState();

      final message = completedSuccessfully
          ? 'Quick Mode completed successfully!'
          : 'Quick Mode stopped';

      _showSuccess('Quick Mode Stopped', message);

      print('QuickModeController: Quick mode stopped successfully');
    } catch (e) {
      _handleError('Failed to stop Quick Mode', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pauseQuickMode() async {
    if (!isQuickModeActive.value || isPaused.value) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .doc(activeQuickBlockId.value)
          .update({'isPaused': true});

      isPaused.value = true;
      _countdownTimer?.cancel();

      _showInfo('Quick Mode Paused', 'Timer paused. Tap resume to continue.');
    } catch (e) {
      _handleError('Failed to pause Quick Mode', e);
    }
  }

  Future<void> resumeQuickMode() async {
    if (!isQuickModeActive.value || !isPaused.value) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .doc(activeQuickBlockId.value)
          .update({'isPaused': false});

      isPaused.value = false;
      _startCountdownTimer();

      _showInfo('Quick Mode Resumed', 'Timer resumed. Stay focused!');
    } catch (e) {
      _handleError('Failed to resume Quick Mode', e);
    }
  }

  Future<bool> toggleQuickMode([int? durationMinutes]) async {
    if (isQuickModeActive.value) {
      await stopQuickMode();
      return false;
    } else {
      return await startQuickMode(durationMinutes);
    }
  }

  Future<void> extendQuickMode(int additionalMinutes) async {
    if (!isQuickModeActive.value) return;

    try {
      final newEndTime = DateTime.now().add(Duration(
          seconds: remainingTimeSeconds.value + (additionalMinutes * 60)));

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .doc(activeQuickBlockId.value)
          .update({
        'endTime': Timestamp.fromDate(newEndTime),
        'extendedBy': FieldValue.increment(additionalMinutes),
      });

      remainingTimeSeconds.value += (additionalMinutes * 60);

      _showInfo('Session Extended',
          'Added $additionalMinutes minutes to your session');
    } catch (e) {
      _handleError('Failed to extend session', e);
    }
  }

  // ===== QUICK MOOD MANAGEMENT =====

  void startQuickMood(int moodLevel) {
    if (moodLevel < 1 || moodLevel > 5) return;

    quickMoodLevel.value = moodLevel;
    quickMoodEmoji.value = getMoodEmoji(moodLevel);
    isQuickMoodActive.value = true;
    quickMoodStartTime.value = DateTime.now();

    // Start quick mood timer (5 minutes)
    _startQuickMoodTimer();

    _showInfo('Quick Mood Started',
        'Feeling ${getMoodLabel(moodLevel).toLowerCase()} for quick session');
  }

  void stopQuickMood() {
    isQuickMoodActive.value = false;
    quickMoodLevel.value = 0;
    quickMoodEmoji.value = '';
    _quickMoodTimer?.cancel();
  }

  Future<void> resetQuickMood() async {
    try {
      isLoading.value = true;

      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Reset Quick Mood'),
              content: const Text(
                  'Are you sure you want to reset your quick mood session? This will stop the current mood tracking.'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;

      // Stop quick mood
      stopQuickMood();

      // Clear any quick mood cache
      await _clearQuickMoodCache();

      _showSuccess('Quick Mood Reset', 'Quick mood session has been reset');
    } catch (e) {
      _handleError('Failed to reset quick mood', e);
    } finally {
      isLoading.value = false;
    }
  }

  void _startQuickMoodTimer() {
    _quickMoodTimer?.cancel();
    _quickMoodTimer = Timer(const Duration(minutes: 5), () {
      // Auto-stop quick mood after 5 minutes
      stopQuickMood();
      _showInfo('Quick Mood Ended', 'Quick mood session completed');
    });
  }

  Future<void> _clearQuickMoodCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(quickMoodKey);

      // Clear from memory cache
      _cache.removeWhere((key, value) => key.contains('quick_mood'));
      _cacheTimestamps.removeWhere((key, value) => key.contains('quick_mood'));
    } catch (e) {
      print('QuickModeController: Error clearing quick mood cache: $e');
    }
  }

  // ===== MOOD TRACKING =====

  Future<void> saveMood(int moodLevel, {String? notes}) async {
    if (_currentUserId == null) {
      _showError('Authentication Error', 'User not authenticated');
      return;
    }

    if (moodLevel < 1 || moodLevel > 5) {
      _showError('Invalid Mood', 'Mood level must be between 1 and 5');
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final dateId =
          '${todayDate.year}-${todayDate.month.toString().padLeft(2, '0')}-${todayDate.day.toString().padLeft(2, '0')}';

      final moodData = {
        'userId': _currentUserId!,
        'moodLevel': moodLevel,
        'notes': notes ?? '',
        'date': Timestamp.fromDate(todayDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'wasQuickMood': isQuickMoodActive.value,
        'quickMoodDuration': isQuickMoodActive.value
            ? DateTime.now().difference(quickMoodStartTime.value).inMinutes
            : null,
      };

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('moods')
          .doc(dateId)
          .set(moodData, SetOptions(merge: true));

      currentMood.value = moodLevel;
      moodNotes.value = notes ?? '';
      hasMoodToday.value = true;

      // Stop quick mood if it was active
      if (isQuickMoodActive.value) {
        stopQuickMood();
      }

      _showSuccess('Mood Saved', 'Your mood has been recorded for today');
    } catch (e) {
      _handleError('Failed to save mood', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetMoodData() async {
    if (_currentUserId == null) {
      _showError('Authentication Error', 'User not authenticated');
      return;
    }

    try {
      isLoading.value = true;

      final confirmed = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Reset All Mood Data'),
              content: const Text(
                  'Are you sure you want to delete all your mood tracking data? This action cannot be undone and will affect your mood statistics.'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete All'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;

      // Delete all mood documents
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('moods')
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Reset local state
      currentMood.value = 0;
      moodNotes.value = '';
      moodHistory.clear();
      averageMood.value = 0.0;
      moodStreak.value = 0;
      hasMoodToday.value = false;

      // Stop any active quick mood
      stopQuickMood();

      _showSuccess(
          'Mood Data Reset', 'All mood tracking data has been deleted');
    } catch (e) {
      _handleError('Failed to reset mood data', e);
    } finally {
      isLoading.value = false;
    }
  }

  // ===== APP MANAGEMENT =====

  void setAvailableApps(List<AppModel> apps) {
    availableApps.value = apps.where((app) => !app.isSystemApp).toList();
    availableApps.sort((a, b) => a.name.compareTo(b.name));
  }

  void toggleAppSelection(AppModel app) {
    if (isAppSelected(app)) {
      selectedApps.removeWhere((a) => a.id == app.id);
    } else {
      selectedApps.add(app);
    }
    _savePersistentData();
  }

  bool isAppSelected(AppModel app) {
    return selectedApps.any((a) => a.id == app.id);
  }

  void clearSelectedApps() {
    selectedApps.clear();
    selectedPresetId.value = '';
    _savePersistentData();
  }

  void selectAllApps() {
    selectedApps.value = List.from(availableApps);
    selectedPresetId.value = '';
    _savePersistentData();
  }

  void selectPopularApps() {
    final popularPackages = [
      'com.instagram.android',
      'com.facebook.katana',
      'com.twitter.android',
      'com.snapchat.android',
      'com.zhiliaoapp.musically',
      'com.google.android.youtube',
    ];

    selectedApps.clear();
    for (final app in availableApps) {
      if (popularPackages.contains(app.packageName)) {
        selectedApps.add(app);
      }
    }
    selectedPresetId.value = 'popular';
    _savePersistentData();
  }

  void setDuration(int minutes) {
    if (minutes < 1 || minutes > 480) return; // Max 8 hours
    selectedDurationMinutes.value = minutes;
    _savePersistentData();
  }

  void applyQuickModePreset(QuickModePreset preset) {
    selectedApps.clear();

    for (final app in availableApps) {
      if (preset.shouldIncludeApp(app)) {
        selectedApps.add(app);
      }
    }

    selectedPresetId.value = preset.id;
    _savePersistentData();
  }

  // ===== QUICK MODE PRESETS =====

  List<QuickModePreset> getQuickModePresets() {
    return [
      QuickModePreset(
        id: 'social_media',
        name: 'Social Media',
        description: 'Block social media apps',
        icon: Icons.people,
        color: Colors.blue,
        packageNames: [
          'com.instagram.android',
          'com.facebook.katana',
          'com.twitter.android',
          'com.snapchat.android',
          'com.zhiliaoapp.musically',
          'com.linkedin.android',
        ],
      ),
      QuickModePreset(
        id: 'entertainment',
        name: 'Entertainment',
        description: 'Block entertainment apps',
        icon: Icons.tv,
        color: Colors.purple,
        packageNames: [
          'com.netflix.mediaclient',
          'com.google.android.youtube',
          'com.amazon.avod.thirdpartyclient',
          'com.disney.disneyplus',
        ],
      ),
      QuickModePreset(
        id: 'games',
        name: 'Games',
        description: 'Block gaming apps',
        icon: Icons.games,
        color: Colors.red,
        categories: ['Games'],
      ),
      QuickModePreset(
        id: 'all_distracting',
        name: 'All Distracting',
        description: 'Block most distracting apps',
        icon: Icons.block,
        color: Colors.orange,
        packageNames: [
          'com.instagram.android',
          'com.facebook.katana',
          'com.twitter.android',
          'com.snapchat.android',
          'com.zhiliaoapp.musically',
          'com.google.android.youtube',
          'com.netflix.mediaclient',
        ],
      ),
    ];
  }

  // ===== DATA LOADING =====

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load selected apps
      final selectedAppsJson = prefs.getString(selectedAppsKey);
      if (selectedAppsJson != null && selectedAppsJson.isNotEmpty) {
        final List<dynamic> appsList = jsonDecode(selectedAppsJson);
        selectedApps.value =
            appsList.map((json) => AppModel.fromJson(json)).toList();
      }

      // Load selected duration
      selectedDurationMinutes.value = prefs.getInt(selectedDurationKey) ?? 30;

      // Load selected preset
      selectedPresetId.value = prefs.getString('selected_preset_id') ?? '';

      print('QuickModeController: Saved data loaded');
    } catch (e) {
      print('QuickModeController: Error loading saved data: $e');
    }
  }

  Future<void> _savePersistentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save selected apps
      final selectedAppsJson =
          jsonEncode(selectedApps.map((app) => app.toJson()).toList());
      await prefs.setString(selectedAppsKey, selectedAppsJson);

      // Save selected duration
      await prefs.setInt(selectedDurationKey, selectedDurationMinutes.value);

      // Save selected preset
      await prefs.setString('selected_preset_id', selectedPresetId.value);

      print('QuickModeController: Data saved successfully');
    } catch (e) {
      print('QuickModeController: Error saving data: $e');
    }
  }

  Future<void> _loadTodayStatistics() async {
    // This is handled by the statistics listener
    // Load from cache if available
    final cachedStats = _getFromCache('today_statistics');
    if (cachedStats != null) {
      totalSessionsToday.value = cachedStats['totalSessionsToday'] ?? 0;
      totalBlockingTimeToday.value =
          Duration(seconds: cachedStats['totalBlockingTimeToday'] ?? 0);
    }
  }

  Future<void> _loadTodayMood() async {
    if (_currentUserId == null) return;

    try {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final dateId =
          '${todayDate.year}-${todayDate.month.toString().padLeft(2, '0')}-${todayDate.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('moods')
          .doc(dateId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        currentMood.value = data['moodLevel'] ?? 0;
        moodNotes.value = data['notes'] ?? '';
        hasMoodToday.value = true;
      } else {
        currentMood.value = 0;
        moodNotes.value = '';
        hasMoodToday.value = false;
      }
    } catch (e) {
      print('QuickModeController: Error loading today mood: $e');
    }
  }

  Future<void> _loadSessionHistory() async {
    if (_currentUserId == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final history = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'startTime': (data['startTime'] as Timestamp?)?.toDate(),
          'endTime': (data['endTime'] as Timestamp?)?.toDate(),
          'endedAt': (data['endedAt'] as Timestamp?)?.toDate(),
        };
      }).toList();

      sessionHistory.value = history;
      _addToCache('session_history', history);
    } catch (e) {
      print('QuickModeController: Error loading session history: $e');
    }
  }

  Future<void> _loadCustomPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(presetsKey);

      if (presetsJson != null && presetsJson.isNotEmpty) {
        final List<dynamic> presetsList = jsonDecode(presetsJson);
        final customPresets =
            presetsList.map((json) => QuickModePreset.fromJson(json)).toList();

        availablePresets.addAll(customPresets);
        hasCustomPresets.value = customPresets.isNotEmpty;
      }
    } catch (e) {
      print('QuickModeController: Error loading custom presets: $e');
    }
  }

  Future<void> _loadQuickMoodSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quickMoodJson = prefs.getString(quickMoodKey);

      if (quickMoodJson != null && quickMoodJson.isNotEmpty) {
        final settings = jsonDecode(quickMoodJson);
        // Apply any saved quick mood settings
      }
    } catch (e) {
      print('QuickModeController: Error loading quick mood settings: $e');
    }
  }

  // ===== DATA REFRESH =====

  Future<void> refreshQuickModeData() async {
    if (_currentUserId == null) {
      print('QuickModeController: Cannot refresh - user not authenticated');
      return;
    }

    try {
      isLoading.value = true;
      print('QuickModeController: Starting data refresh...');

      // Refresh all data sources in parallel
      await Future.wait([
        _refreshQuickModeStatus(),
        _refreshStatistics(),
        _refreshMoodData(),
        _refreshSessionHistory(),
        _refreshPresets(),
      ]);

      // Update last refresh time
      _addToCache('last_refresh_time', DateTime.now());

      print('QuickModeController: Data refresh completed successfully');
    } catch (e) {
      print('QuickModeController: Error during data refresh: $e');
      _handleError('Failed to refresh data', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshQuickModeStatus() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final endTime = (data['endTime'] as Timestamp).toDate();

        if (DateTime.now().isBefore(endTime)) {
          _updateActiveQuickMode(doc.id, data, endTime);
        } else {
          await _deactivateExpiredQuickMode(doc.id);
        }
      } else {
        _resetQuickModeState();
      }

      print('QuickModeController: Quick mode status refreshed');
    } catch (e) {
      print('QuickModeController: Error refreshing quick mode status: $e');
    }
  }

  Future<void> _refreshStatistics() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final sessionsQuery = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();

      int todaySessions = 0;
      int totalBlockingTime = 0;
      int successfulSessions = 0;

      for (final doc in sessionsQuery.docs) {
        final data = doc.data();
        todaySessions++;

        final actualDuration = data['actualDuration'] ?? 0;
        totalBlockingTime += actualDuration as int;

        if (data['completedSuccessfully'] == true) {
          successfulSessions++;
        }
      }

      totalSessionsToday.value = todaySessions;
      totalBlockingTimeToday.value = Duration(seconds: totalBlockingTime);

      if (todaySessions > 0) {
        completionRate.value = successfulSessions / todaySessions;
        averageSessionDuration.value = totalBlockingTime / todaySessions / 60;
      }

      await _calculateConsecutiveSuccessfulSessions();

      print(
          'QuickModeController: Statistics refreshed - $todaySessions sessions today');
    } catch (e) {
      print('QuickModeController: Error refreshing statistics: $e');
    }
  }

  Future<void> _calculateConsecutiveSuccessfulSessions() async {
    try {
      final recentSessions = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      int streak = 0;
      for (final doc in recentSessions.docs) {
        final data = doc.data();
        if (data['completedSuccessfully'] == true) {
          streak++;
        } else {
          break;
        }
      }

      consecutiveSuccessfulSessions.value = streak;
    } catch (e) {
      print('QuickModeController: Error calculating consecutive sessions: $e');
    }
  }

  Future<void> _refreshMoodData() async {
    try {
      await _loadTodayMood();

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('moods')
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      final history = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'moodLevel': data['moodLevel'] ?? 0,
          'notes': data['notes'] ?? '',
          'date': (data['date'] as Timestamp).millisecondsSinceEpoch,
          'createdAt':
              (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
        };
      }).toList();

      moodHistory.value = history;
      _updateMoodStatistics(history);

      print(
          'QuickModeController: Mood data refreshed - ${history.length} entries');
    } catch (e) {
      print('QuickModeController: Error refreshing mood data: $e');
    }
  }

  Future<void> _refreshSessionHistory() async {
    try {
      await _loadSessionHistory();

      if (sessionHistory.isNotEmpty) {
        final durations = sessionHistory
            .where((session) => session['actualDuration'] != null)
            .map((session) => session['actualDuration'] as int)
            .toList();

        if (durations.isNotEmpty) {
          longestSession.value =
              durations.reduce((a, b) => a > b ? a : b) ~/ 60;
          shortestSession.value =
              durations.reduce((a, b) => a < b ? a : b) ~/ 60;
        }
      }

      print('QuickModeController: Session history refreshed');
    } catch (e) {
      print('QuickModeController: Error refreshing session history: $e');
    }
  }

  Future<void> _refreshPresets() async {
    try {
      await _loadCustomPresets();

      final defaultPresets = getQuickModePresets();
      availablePresets.value = defaultPresets;

      final customPresets = availablePresets.where((p) => p.isCustom).toList();
      if (customPresets.isNotEmpty) {
        availablePresets.addAll(customPresets);
        hasCustomPresets.value = true;
      }

      print(
          'QuickModeController: Presets refreshed - ${availablePresets.length} total');
    } catch (e) {
      print('QuickModeController: Error refreshing presets: $e');
    }
  }

  // ===== HELPER METHODS =====

  Future<void> _updateBlockedApps(String quickModeId) async {
    final batch = _firestore.batch();

    for (final app in selectedApps) {
      final blockedAppRef = _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('blocked_apps')
          .doc(app.id);

      batch.set(
          blockedAppRef,
          {
            ...app.toFirestore(),
            'isQuickBlock': true,
            'quickModeId': quickModeId,
            'blockedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> _removeBlockedApps() async {
    final batch = _firestore.batch();

    for (final appId in blockedAppIds) {
      final blockedAppRef = _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('blocked_apps')
          .doc(appId);
      batch.delete(blockedAppRef);
    }

    await batch.commit();
  }

  Future<void> _updateSessionStatistics(
      {bool isStart = false,
      bool isEnd = false,
      bool completedSuccessfully = false}) async {
    if (_currentUserId == null) return;

    try {
      final statsRef = _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_mode_stats')
          .doc('summary');

      final updates = <String, dynamic>{};

      if (isStart) {
        updates['totalSessionsToday'] = FieldValue.increment(1);
        updates['lastSessionStartTime'] = FieldValue.serverTimestamp();
      }

      if (isEnd) {
        final sessionDuration =
            selectedDurationMinutes.value * 60 - remainingTimeSeconds.value;
        updates['totalBlockingTimeToday'] =
            FieldValue.increment(sessionDuration);
        updates['lastSessionEndTime'] = DateTime.now().toIso8601String();

        if (completedSuccessfully) {
          updates['consecutiveSuccessfulSessions'] = FieldValue.increment(1);
        } else {
          updates['consecutiveSuccessfulSessions'] = 0;
        }
      }

      if (updates.isNotEmpty) {
        await statsRef.set(updates, SetOptions(merge: true));
      }
    } catch (e) {
      print('QuickModeController: Error updating session statistics: $e');
    }
  }

  Future<void> _deactivateExpiredQuickMode(String quickModeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .doc(quickModeId)
          .update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
        'completedSuccessfully': true,
      });

      await _updateSessionStatistics(isEnd: true, completedSuccessfully: true);
      _resetQuickModeState();

      _showSuccess('Quick Mode Completed!',
          'Your blocking session has finished. Great job!');
    } catch (e) {
      print('QuickModeController: Error deactivating expired quick mode: $e');
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeSeconds.value > 0 && !isPaused.value) {
        remainingTimeSeconds.value--;
      } else if (remainingTimeSeconds.value <= 0) {
        timer.cancel();
        stopQuickMode(completedSuccessfully: true);
      }
    });
  }

  void _resetQuickModeState() {
    _countdownTimer?.cancel();
    isQuickModeActive.value = false;
    isPaused.value = false;
    activeQuickBlockId.value = '';
    remainingTimeSeconds.value = 0;
    blockedAppIds.clear();
  }

  // ===== CACHE MANAGEMENT =====

  T? _getFromCache<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheTimeout) {
      return _cache[key] as T?;
    }
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }

  void _addToCache<T>(String key, T value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  // ===== UTILITY METHODS =====

  String formatRemainingTime() {
    final minutes = remainingTimeSeconds.value ~/ 60;
    final seconds = remainingTimeSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😞';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '❓';
    }
  }

  String getMoodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very Happy';
      default:
        return 'Unknown';
    }
  }

  Color getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red.shade700;
      case 2:
        return Colors.orange.shade700;
      case 3:
        return Colors.grey.shade600;
      case 4:
        return Colors.green.shade600;
      case 5:
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  // ===== ERROR HANDLING =====

  void _handleError(String message, dynamic error) {
    errorMessage.value = message;
    print('QuickModeController: $message: $error');
    _showError('Error', message);
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void clearError() {
    errorMessage.value = '';
  }

  // ===== GETTERS FOR UI =====

  String get quickModeButtonText {
    if (selectedApps.isEmpty && !isQuickModeActive.value) {
      return '+ Add Apps';
    } else if (isQuickModeActive.value) {
      return isPaused.value ? 'Resume' : 'Stop Blocking';
    } else {
      return 'Start (${selectedApps.length} apps)';
    }
  }

  String get selectedAppsCountText {
    if (selectedApps.isEmpty) {
      return 'No apps selected';
    } else if (selectedApps.length == 1) {
      return '1 app selected';
    } else {
      return '${selectedApps.length} apps selected';
    }
  }

  String get remainingTimeText {
    if (!isQuickModeActive.value || remainingTimeSeconds.value == 0) {
      return '';
    }
    final status = isPaused.value ? 'Paused: ' : 'Time remaining: ';
    return '$status${formatRemainingTime()}';
  }

  String get quickMoodStatusText {
    if (!isQuickMoodActive.value) return '';
    final duration = DateTime.now().difference(quickMoodStartTime.value);
    return 'Quick mood: ${quickMoodEmoji.value} (${duration.inMinutes}m)';
  }

  bool get hasSelectedApps => selectedApps.isNotEmpty;
  bool get canStartQuickMode =>
      selectedApps.isNotEmpty && !isQuickModeActive.value;
  bool get canPauseQuickMode => isQuickModeActive.value && !isPaused.value;
  bool get canResumeQuickMode => isQuickModeActive.value && isPaused.value;

  // ===== CLEANUP =====

  void _teardownListeners() {
    _quickModeListener?.cancel();
    _statisticsListener?.cancel();
    _moodListener?.cancel();

    _quickModeListener = null;
    _statisticsListener = null;
    _moodListener = null;
  }

  void _cleanup() {
    print('QuickModeController: Starting cleanup...');

    _countdownTimer?.cancel();
    _quickMoodTimer?.cancel();
    _teardownListeners();

    _cache.clear();
    _cacheTimestamps.clear();

    print('QuickModeController: Cleanup completed');
  }
}

// ===== ENHANCED QUICK MODE PRESET MODEL =====

class QuickModePreset {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String>? packageNames;
  final List<String>? categories;
  final bool isCustom;
  final DateTime? createdAt;

  QuickModePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.packageNames,
    this.categories,
    this.isCustom = false,
    this.createdAt,
  });

  bool shouldIncludeApp(AppModel app) {
    if (packageNames != null && packageNames!.contains(app.packageName)) {
      return true;
    }

    if (categories != null && categories!.contains(app.category)) {
      return true;
    }

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'packageNames': packageNames,
      'categories': categories,
      'isCustom': isCustom,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static QuickModePreset fromJson(Map<String, dynamic> json) {
    return QuickModePreset(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
      color: Color(json['colorValue']),
      packageNames: json['packageNames']?.cast<String>(),
      categories: json['categories']?.cast<String>(),
      isCustom: json['isCustom'] ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
