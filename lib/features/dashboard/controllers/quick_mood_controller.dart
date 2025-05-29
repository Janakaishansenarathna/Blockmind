// controllers/quick_mode_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/local/models/app_model.dart';
import '../../../utils/quick_mode_utils.dart';
import '../../../models/quick_mode_preset.dart';

class QuickModeController extends GetxController {
  final QuickModeManager quickModeManager = QuickModeManager();
  final MoodManager moodManager = MoodManager();
  final PresetManager presetManager = PresetManager();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    quickModeManager.initialize();
    presetManager.loadPresets();
  }

  @override
  void onClose() {
    quickModeManager.cleanup();
    super.onClose();
  }

  void setUserId(String userId) {
    quickModeManager.setUserId(userId);
    moodManager.setUserId(userId);
  }

  void clearError() {
    errorMessage.value = '';
  }
}

// ===== QUICK MODE MANAGER =====

class QuickModeManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isQuickModeActive = false.obs;
  final RxString activeQuickBlockId = ''.obs;
  final RxInt remainingTimeSeconds = 0.obs;
  final RxList<AppModel> selectedApps = <AppModel>[].obs;

  Timer? _countdownTimer;
  String? _currentUserId;

  void initialize() {
    // Load saved data and set up listeners
    _loadSavedData();
  }

  void setUserId(String userId) {
    _currentUserId = userId;
    _setupFirebaseListeners();
  }

  Future<void> startQuickMode(int durationMinutes) async {
    if (selectedApps.isEmpty || _currentUserId == null) {
      QuickModeUtils.showError(
          'Error', 'No apps selected or user not authenticated');
      return;
    }

    try {
      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: durationMinutes));

      final quickModeData = {
        'userId': _currentUserId!,
        'durationMinutes': durationMinutes,
        'blockedAppIds': selectedApps.map((app) => app.id).toList(),
        'isActive': true,
        'startTime': Timestamp.fromDate(now),
        'endTime': Timestamp.fromDate(endTime),
      };

      final docRef = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .add(quickModeData);

      activeQuickBlockId.value = docRef.id;
      isQuickModeActive.value = true;
      remainingTimeSeconds.value = durationMinutes * 60;

      _startCountdownTimer();
      QuickModeUtils.showSuccess(
          'Quick Mode Started', 'Blocking apps for $durationMinutes minutes');
    } catch (e) {
      QuickModeUtils.handleError('Failed to start Quick Mode', e);
    }
  }

  Future<void> stopQuickMode() async {
    if (!isQuickModeActive.value || _currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('quick_modes')
          .doc(activeQuickBlockId.value)
          .update({'isActive': false});

      _resetQuickModeState();
      QuickModeUtils.showSuccess(
          'Quick Mode Stopped', 'Blocking session ended');
    } catch (e) {
      QuickModeUtils.handleError('Failed to stop Quick Mode', e);
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeSeconds.value > 0) {
        remainingTimeSeconds.value--;
      } else {
        timer.cancel();
        stopQuickMode();
      }
    });
  }

  void _resetQuickModeState() {
    _countdownTimer?.cancel();
    isQuickModeActive.value = false;
    activeQuickBlockId.value = '';
    remainingTimeSeconds.value = 0;
  }

  void cleanup() {
    _countdownTimer?.cancel();
  }

  Future<void> _loadSavedData() async {
    // Load saved data from SharedPreferences
  }

  void _setupFirebaseListeners() {
    // Set up Firebase listeners
  }
}

// ===== MOOD MANAGER =====

class MoodManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxInt currentMood = 0.obs;
  final RxString moodNotes = ''.obs;
  final RxList<Map<String, dynamic>> moodHistory = <Map<String, dynamic>>[].obs;

  String? _currentUserId;

  void setUserId(String userId) {
    _currentUserId = userId;
  }

  Future<void> saveMood(int moodLevel, {String? notes}) async {
    if (_currentUserId == null || moodLevel < 1 || moodLevel > 5) {
      QuickModeUtils.showError(
          'Error', 'Invalid mood or user not authenticated');
      return;
    }

    try {
      final today = DateTime.now();
      final moodData = {
        'userId': _currentUserId!,
        'moodLevel': moodLevel,
        'notes': notes ?? '',
        'date': Timestamp.fromDate(today),
      };

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('moods')
          .add(moodData);

      currentMood.value = moodLevel;
      moodNotes.value = notes ?? '';
      QuickModeUtils.showSuccess('Mood Saved', 'Your mood has been recorded');
    } catch (e) {
      QuickModeUtils.handleError('Failed to save mood', e);
    }
  }
}

// ===== PRESET MANAGER =====

class PresetManager {
  final RxList<QuickModePreset> availablePresets = <QuickModePreset>[].obs;

  void loadPresets() {
    availablePresets.value = QuickModeUtils.getDefaultPresets();
  }

  void applyPreset(QuickModePreset preset, RxList<AppModel> selectedApps) {
    selectedApps.clear();
    selectedApps.addAll(preset.getMatchingApps());
  }
}

// ===== UTILITY CLASS =====

class QuickModeUtils {
  static void showError(String title, String message) {
    Get.snackbar(title, message,
        backgroundColor: Colors.red, colorText: Colors.white);
  }

  static void showSuccess(String title, String message) {
    Get.snackbar(title, message,
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  static void handleError(String message, dynamic error) {
    print('Error: $message - $error');
    showError('Error', message);
  }

  static List<QuickModePreset> getDefaultPresets() {
    return [
      QuickModePreset(
        id: 'social_media',
        name: 'Social Media',
        description: 'Block social media apps',
        icon: Icons.people,
        color: Colors.blue,
        packageNames: ['com.instagram.android', 'com.facebook.katana'],
      ),
      QuickModePreset(
        id: 'entertainment',
        name: 'Entertainment',
        description: 'Block entertainment apps',
        icon: Icons.tv,
        color: Colors.purple,
        packageNames: ['com.netflix.mediaclient', 'com.google.android.youtube'],
      ),
    ];
  }
}
