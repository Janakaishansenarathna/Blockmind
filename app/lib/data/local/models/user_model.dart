// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone; // ADDED: Phone number field
  final String? photoUrl;
  final bool isPremium;
  final DateTime? premiumExpiryDate;
  final int maxPlansAllowed;
  final int maxAppsPerPlan;
  final int remainingPredefinedDownloads;
  final DateTime createdAt;
  final DateTime? lastLoginAt; // Made nullable for database compatibility
  final DateTime updatedAt;
  final bool darkModeEnabled;
  final bool allowNotifications;

  // Usage statistics (enhanced for database compatibility)
  final Duration? totalBlockedTime; // Changed to Duration for consistency
  final int successfulBlocks;
  final int attemptedBlocks;
  final int currentStreak;
  final int streakDays; // For database compatibility
  final int totalDownloads; // For database compatibility

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone, // ADDED: Phone parameter
    this.photoUrl,
    this.isPremium = false,
    this.premiumExpiryDate,
    this.maxPlansAllowed = 5, // Default for free tier
    this.maxAppsPerPlan = 3, // Default for free tier
    this.remainingPredefinedDownloads = 2, // Default for free tier
    required this.createdAt,
    this.lastLoginAt, // Made nullable
    required this.updatedAt,
    this.darkModeEnabled = false,
    this.allowNotifications = true,
    this.totalBlockedTime,
    this.successfulBlocks = 0,
    this.attemptedBlocks = 0,
    this.currentStreak = 0,
    this.streakDays = 0,
    this.totalDownloads = 100,
  });

  // Factory constructor to create a user from a Firestore document
  factory UserModel.fromFirestore(
      DocumentSnapshot doc, Map<String, dynamic> userData) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data is null for user: ${doc.id}');
    }

    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'], // ADDED: Phone field
      photoUrl: data['photoUrl'],
      isPremium: data['isPremium'] ?? false,
      premiumExpiryDate: data['premiumExpiryDate'] != null
          ? (data['premiumExpiryDate'] as Timestamp).toDate()
          : null,
      maxPlansAllowed: data['maxPlansAllowed'] ?? 5,
      maxAppsPerPlan: data['maxAppsPerPlan'] ?? 3,
      remainingPredefinedDownloads: data['remainingPredefinedDownloads'] ?? 2,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      darkModeEnabled: data['darkModeEnabled'] ?? false,
      allowNotifications: data['allowNotifications'] ?? true,
      totalBlockedTime: data['totalBlockedTime'] != null
          ? Duration(seconds: data['totalBlockedTime'])
          : (data['totalBlockedTimeSeconds'] != null
              ? Duration(seconds: data['totalBlockedTimeSeconds'])
              : null),
      successfulBlocks: data['successfulBlocks'] ?? 0,
      attemptedBlocks: data['attemptedBlocks'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      streakDays: data['streakDays'] ?? 0,
      totalDownloads: data['totalDownloads'] ?? 100,
    );
  }

  // Factory constructor for database map (SQLite compatibility)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'], // ADDED: Phone field
      photoUrl: map['photoUrl'] ?? map['photo_url'],
      isPremium: (map['isPremium'] ?? map['is_premium']) == 1 ||
          (map['isPremium'] ?? map['is_premium']) == true,
      premiumExpiryDate: map['premiumExpiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['premiumExpiryDate'])
          : (map['premium_expiry_date'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['premium_expiry_date'])
              : null),
      maxPlansAllowed: map['maxPlansAllowed'] ?? map['max_plans_allowed'] ?? 5,
      maxAppsPerPlan: map['maxAppsPerPlan'] ?? map['max_apps_per_plan'] ?? 3,
      remainingPredefinedDownloads: map['remainingPredefinedDownloads'] ??
          map['remaining_predefined_downloads'] ??
          2,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : (map['created_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
              : DateTime.now()),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'])
          : (map['last_login_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['last_login_at'])
              : null),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : (map['updated_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
              : DateTime.now()),
      darkModeEnabled:
          (map['darkModeEnabled'] ?? map['dark_mode_enabled']) == 1 ||
              (map['darkModeEnabled'] ?? map['dark_mode_enabled']) == true,
      allowNotifications:
          (map['allowNotifications'] ?? map['allow_notifications']) == 1 ||
              (map['allowNotifications'] ?? map['allow_notifications']) == true,
      totalBlockedTime: map['totalBlockedTime'] != null
          ? Duration(seconds: map['totalBlockedTime'])
          : (map['total_blocked_time'] != null
              ? Duration(seconds: map['total_blocked_time'])
              : null),
      successfulBlocks:
          map['successfulBlocks'] ?? map['successful_blocks'] ?? 0,
      attemptedBlocks: map['attemptedBlocks'] ?? map['attempted_blocks'] ?? 0,
      currentStreak: map['currentStreak'] ?? map['current_streak'] ?? 0,
      streakDays: map['streakDays'] ?? map['streak_days'] ?? 0,
      totalDownloads: map['totalDownloads'] ?? map['total_downloads'] ?? 100,
    );
  }

  // Factory constructor for new users
  factory UserModel.newUser({
    required String id,
    required String name,
    required String email,
    String? phone, // ADDED: Phone parameter
    String? photoUrl,
    bool isPremium = false,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      name: name,
      email: email,
      phone: phone, // ADDED: Phone field
      photoUrl: photoUrl,
      isPremium: isPremium,
      maxPlansAllowed: isPremium ? 20 : 5,
      maxAppsPerPlan: isPremium ? 10 : 3,
      remainingPredefinedDownloads: isPremium ? 10 : 2,
      createdAt: now,
      lastLoginAt: now,
      updatedAt: now,
      totalDownloads: isPremium ? 1000 : 100,
    );
  }

  // Create a user from JSON (local storage)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'], // ADDED: Phone field
      photoUrl: json['photoUrl'],
      isPremium: json['isPremium'] ?? false,
      premiumExpiryDate: json['premiumExpiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['premiumExpiryDate'])
          : null,
      maxPlansAllowed: json['maxPlansAllowed'] ?? 5,
      maxAppsPerPlan: json['maxAppsPerPlan'] ?? 3,
      remainingPredefinedDownloads: json['remainingPredefinedDownloads'] ?? 2,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.now(),
      darkModeEnabled: json['darkModeEnabled'] ?? false,
      allowNotifications: json['allowNotifications'] ?? true,
      totalBlockedTime: json['totalBlockedTime'] != null
          ? Duration(seconds: json['totalBlockedTime'])
          : (json['totalBlockedTimeSeconds'] != null
              ? Duration(seconds: json['totalBlockedTimeSeconds'])
              : null),
      successfulBlocks: json['successfulBlocks'] ?? 0,
      attemptedBlocks: json['attemptedBlocks'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      totalDownloads: json['totalDownloads'] ?? 100,
    );
  }

  // Convert to a Map for storing in Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone, // ADDED: Phone field
      'photoUrl': photoUrl,
      'isPremium': isPremium,
      'premiumExpiryDate': premiumExpiryDate != null
          ? Timestamp.fromDate(premiumExpiryDate!)
          : null,
      'maxPlansAllowed': maxPlansAllowed,
      'maxAppsPerPlan': maxAppsPerPlan,
      'remainingPredefinedDownloads': remainingPredefinedDownloads,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'darkModeEnabled': darkModeEnabled,
      'allowNotifications': allowNotifications,
      'totalBlockedTime': totalBlockedTime?.inSeconds ?? 0,
      'totalBlockedTimeSeconds':
          totalBlockedTime?.inSeconds ?? 0, // compatibility
      'successfulBlocks': successfulBlocks,
      'attemptedBlocks': attemptedBlocks,
      'currentStreak': currentStreak,
      'streakDays': streakDays,
      'totalDownloads': totalDownloads,
    };
  }

  // Convert to a Map for storing in local database (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone, // ADDED: Phone field
      'photoUrl': photoUrl,
      'photo_url': photoUrl, // compatibility
      'isPremium': isPremium ? 1 : 0,
      'is_premium': isPremium ? 1 : 0, // compatibility
      'premiumExpiryDate': premiumExpiryDate?.millisecondsSinceEpoch,
      'premium_expiry_date':
          premiumExpiryDate?.millisecondsSinceEpoch, // compatibility
      'maxPlansAllowed': maxPlansAllowed,
      'max_plans_allowed': maxPlansAllowed, // compatibility
      'maxAppsPerPlan': maxAppsPerPlan,
      'max_apps_per_plan': maxAppsPerPlan, // compatibility
      'remainingPredefinedDownloads': remainingPredefinedDownloads,
      'remaining_predefined_downloads':
          remainingPredefinedDownloads, // compatibility
      'createdAt': createdAt.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch, // compatibility
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'last_login_at': lastLoginAt?.millisecondsSinceEpoch, // compatibility
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch, // compatibility
      'darkModeEnabled': darkModeEnabled ? 1 : 0,
      'dark_mode_enabled': darkModeEnabled ? 1 : 0, // compatibility
      'allowNotifications': allowNotifications ? 1 : 0,
      'allow_notifications': allowNotifications ? 1 : 0, // compatibility
      'totalBlockedTime': totalBlockedTime?.inSeconds ?? 0,
      'total_blocked_time': totalBlockedTime?.inSeconds ?? 0, // compatibility
      'successfulBlocks': successfulBlocks,
      'successful_blocks': successfulBlocks, // compatibility
      'attemptedBlocks': attemptedBlocks,
      'attempted_blocks': attemptedBlocks, // compatibility
      'currentStreak': currentStreak,
      'current_streak': currentStreak, // compatibility
      'streakDays': streakDays,
      'streak_days': streakDays, // compatibility
      'totalDownloads': totalDownloads,
      'total_downloads': totalDownloads, // compatibility
    };
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone, // ADDED: Phone field
      'photoUrl': photoUrl,
      'isPremium': isPremium,
      'premiumExpiryDate': premiumExpiryDate?.millisecondsSinceEpoch,
      'maxPlansAllowed': maxPlansAllowed,
      'maxAppsPerPlan': maxAppsPerPlan,
      'remainingPredefinedDownloads': remainingPredefinedDownloads,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'darkModeEnabled': darkModeEnabled,
      'allowNotifications': allowNotifications,
      'totalBlockedTime': totalBlockedTime?.inSeconds ?? 0,
      'totalBlockedTimeSeconds': totalBlockedTime?.inSeconds ?? 0,
      'successfulBlocks': successfulBlocks,
      'attemptedBlocks': attemptedBlocks,
      'currentStreak': currentStreak,
      'streakDays': streakDays,
      'totalDownloads': totalDownloads,
    };
  }

  // Convert to JSON string
  String toJsonString() => json.encode(toJson());

  // Create from JSON string
  factory UserModel.fromJsonString(String jsonString) {
    final Map<String, dynamic> map = json.decode(jsonString);
    return UserModel.fromJson(map);
  }

  // Copy with method for updating user properties - UPDATED with phone
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone, // ADDED: Phone parameter
    String? photoUrl,
    bool? isPremium,
    DateTime? premiumExpiryDate,
    int? maxPlansAllowed,
    int? maxAppsPerPlan,
    int? remainingPredefinedDownloads,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
    bool? darkModeEnabled,
    bool? allowNotifications,
    Duration? totalBlockedTime,
    int? successfulBlocks,
    int? attemptedBlocks,
    int? currentStreak,
    int? streakDays,
    int? totalDownloads,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone, // ADDED: Phone field
      photoUrl: photoUrl ?? this.photoUrl,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      maxPlansAllowed: maxPlansAllowed ?? this.maxPlansAllowed,
      maxAppsPerPlan: maxAppsPerPlan ?? this.maxAppsPerPlan,
      remainingPredefinedDownloads:
          remainingPredefinedDownloads ?? this.remainingPredefinedDownloads,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      updatedAt: updatedAt ?? DateTime.now(),
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      allowNotifications: allowNotifications ?? this.allowNotifications,
      totalBlockedTime: totalBlockedTime ?? this.totalBlockedTime,
      successfulBlocks: successfulBlocks ?? this.successfulBlocks,
      attemptedBlocks: attemptedBlocks ?? this.attemptedBlocks,
      currentStreak: currentStreak ?? this.currentStreak,
      streakDays: streakDays ?? this.streakDays,
      totalDownloads: totalDownloads ?? this.totalDownloads,
    );
  }

  // Utility methods for business logic

  /// Check if the user's premium subscription is active
  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiryDate == null) return true; // Lifetime premium
    return DateTime.now().isBefore(premiumExpiryDate!);
  }

  /// Get remaining days for premium subscription
  int get premiumDaysRemaining {
    if (!isPremium || premiumExpiryDate == null) return 0;
    final difference = premiumExpiryDate!.difference(DateTime.now());
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  /// Check if user can create more plans
  bool get canCreateMorePlans => remainingPredefinedDownloads > 0;

  /// Get block success rate as percentage
  double get blockSuccessRate {
    if (attemptedBlocks == 0) return 0.0;
    return (successfulBlocks / attemptedBlocks) * 100;
  }

  /// Get total blocked time in hours and minutes format
  String get formattedTotalBlockedTime {
    if (totalBlockedTime == null) return '0h 0m';
    final hours = totalBlockedTime!.inHours;
    final minutes = totalBlockedTime!.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  /// Get total blocked time in minutes (for backward compatibility)
  int get totalBlockedTimeMinutes {
    return totalBlockedTime?.inMinutes ?? 0;
  }

  /// Get user initials for avatar
  String get initials {
    if (name.isEmpty) return 'U';
    final words = name.split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  /// Check if user is a new user (created within last 7 days)
  bool get isNewUser {
    final difference = DateTime.now().difference(createdAt);
    return difference.inDays <= 7;
  }

  /// Get account age in days
  int get accountAge {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Get formatted account age
  String get formattedAccountAge {
    final days = accountAge;
    if (days == 0) return 'Today';
    if (days == 1) return '1 day ago';
    if (days < 30) return '$days days ago';

    final months = days ~/ 30;
    if (months == 1) return '1 month ago';
    if (months < 12) return '$months months ago';

    final years = months ~/ 12;
    if (years == 1) return '1 year ago';
    return '$years years ago';
  }

  /// Get formatted phone number for display
  String get formattedPhone {
    if (phone == null || phone!.isEmpty) return '';

    // Basic phone formatting (you can enhance this based on your needs)
    final cleanPhone = phone!.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length == 10) {
      // US format: (123) 456-7890
      return '(${cleanPhone.substring(0, 3)}) ${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    } else if (cleanPhone.length == 11 && cleanPhone.startsWith('1')) {
      // US format with country code: +1 (123) 456-7890
      return '+1 (${cleanPhone.substring(1, 4)}) ${cleanPhone.substring(4, 7)}-${cleanPhone.substring(7)}';
    }

    // Return original if no specific format matches
    return phone!;
  }

  /// Check if phone number is provided
  bool get hasPhoneNumber => phone != null && phone!.trim().isNotEmpty;

  /// Update last login time
  UserModel updateLastLogin() {
    return copyWith(lastLoginAt: DateTime.now());
  }

  /// Increment usage statistics
  UserModel incrementStats({
    Duration? blockedTime,
    bool? wasSuccessful,
    bool? incrementStreak,
  }) {
    Duration newTotalBlockedTime = totalBlockedTime ?? Duration.zero;
    if (blockedTime != null) {
      newTotalBlockedTime = newTotalBlockedTime + blockedTime;
    }

    return copyWith(
      totalBlockedTime: newTotalBlockedTime,
      successfulBlocks:
          wasSuccessful == true ? successfulBlocks + 1 : successfulBlocks,
      attemptedBlocks:
          wasSuccessful != null ? attemptedBlocks + 1 : attemptedBlocks,
      currentStreak: incrementStreak == true
          ? currentStreak + 1
          : (wasSuccessful == false ? 0 : currentStreak),
      streakDays: incrementStreak == true
          ? streakDays + 1
          : (wasSuccessful == false ? 0 : streakDays),
    );
  }

  /// Decrease remaining downloads
  UserModel decrementDownloads() {
    return copyWith(
      remainingPredefinedDownloads: remainingPredefinedDownloads > 0
          ? remainingPredefinedDownloads - 1
          : 0,
      totalDownloads: totalDownloads > 0 ? totalDownloads - 1 : 0,
    );
  }

  /// Increase downloads (for premium users)
  UserModel incrementDownloads(int amount) {
    return copyWith(
      remainingPredefinedDownloads: remainingPredefinedDownloads + amount,
      totalDownloads: totalDownloads + amount,
    );
  }

  /// Upgrade to premium
  UserModel upgradeToPremium({DateTime? expiryDate}) {
    return copyWith(
      isPremium: true,
      premiumExpiryDate: expiryDate,
      maxPlansAllowed: 20,
      maxAppsPerPlan: 10,
      remainingPredefinedDownloads:
          remainingPredefinedDownloads + 8, // Add 8 more
      totalDownloads: totalDownloads + 900, // Add 900 more downloads
    );
  }

  /// Downgrade from premium
  UserModel downgradeToPremium() {
    return copyWith(
      isPremium: false,
      premiumExpiryDate: null,
      maxPlansAllowed: 5,
      maxAppsPerPlan: 3,
      remainingPredefinedDownloads: 2,
    );
  }

  /// Reset daily/weekly stats (for scheduled resets)
  UserModel resetPeriodStats({
    bool resetDaily = false,
    bool resetWeekly = false,
  }) {
    if (resetDaily) {
      return copyWith(
        // Reset daily stats here if needed
        updatedAt: DateTime.now(),
      );
    }

    if (resetWeekly) {
      return copyWith(
        currentStreak: 0, // Reset weekly streak
        updatedAt: DateTime.now(),
      );
    }

    return this;
  }

  /// Get user tier (Free/Premium)
  String get userTier {
    return isPremiumActive ? 'Premium' : 'Free';
  }

  /// Get remaining downloads percentage
  double get downloadsUsagePercentage {
    if (totalDownloads == 0) return 0.0;
    final used = totalDownloads - remainingPredefinedDownloads;
    return (used / totalDownloads).clamp(0.0, 1.0);
  }

  /// Check if user needs to upgrade (based on usage)
  bool get needsUpgrade {
    return !isPremiumActive &&
        (remainingPredefinedDownloads <= 1 || downloadsUsagePercentage >= 0.8);
  }

  /// Get progress towards next milestone
  Map<String, dynamic> get progressToNextMilestone {
    final milestones = [
      {'blocks': 10, 'title': 'First Steps'},
      {'blocks': 50, 'title': 'Getting Started'},
      {'blocks': 100, 'title': 'Focus Master'},
      {'blocks': 500, 'title': 'Discipline Expert'},
      {'blocks': 1000, 'title': 'Zen Master'},
    ];

    for (final milestone in milestones) {
      final target = milestone['blocks'] as int;
      if (successfulBlocks < target) {
        return {
          'current': successfulBlocks,
          'target': target,
          'title': milestone['title'],
          'progress': successfulBlocks / target,
          'remaining': target - successfulBlocks,
        };
      }
    }

    // If all milestones achieved
    return {
      'current': successfulBlocks,
      'target': successfulBlocks,
      'title': 'Ultimate Master',
      'progress': 1.0,
      'remaining': 0,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone && // ADDED: Phone comparison
        other.photoUrl == photoUrl &&
        other.isPremium == isPremium &&
        other.premiumExpiryDate == premiumExpiryDate &&
        other.maxPlansAllowed == maxPlansAllowed &&
        other.maxAppsPerPlan == maxAppsPerPlan &&
        other.remainingPredefinedDownloads == remainingPredefinedDownloads &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        other.updatedAt == updatedAt &&
        other.darkModeEnabled == darkModeEnabled &&
        other.allowNotifications == allowNotifications &&
        other.totalBlockedTime == totalBlockedTime &&
        other.successfulBlocks == successfulBlocks &&
        other.attemptedBlocks == attemptedBlocks &&
        other.currentStreak == currentStreak &&
        other.streakDays == streakDays &&
        other.totalDownloads == totalDownloads;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      name,
      email,
      phone, // ADDED: Phone to hash
      photoUrl,
      isPremium,
      premiumExpiryDate,
      maxPlansAllowed,
      maxAppsPerPlan,
      remainingPredefinedDownloads,
      createdAt,
      lastLoginAt,
      updatedAt,
      darkModeEnabled,
      allowNotifications,
      totalBlockedTime,
      successfulBlocks,
      attemptedBlocks,
      currentStreak,
      streakDays,
      totalDownloads,
    ]);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, phone: $phone, isPremium: $isPremium, tier: $userTier)';
  }
}
