import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppModel {
  final String id;
  final String name;
  final String packageName;
  final IconData icon;
  final Color iconColor;
  final bool isBlocked;
  final DateTime? lastUsed;
  final Duration? dailyUsage;
  final bool isSystemApp;
  final String category;
  final String? appIconUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppModel({
    required this.id,
    required this.name,
    required this.packageName,
    required this.icon,
    required this.iconColor,
    this.isBlocked = false,
    this.lastUsed,
    this.dailyUsage,
    this.isSystemApp = false,
    this.category = 'Other',
    this.appIconUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Create a copy of this app with some properties changed
  AppModel copyWith({
    String? id,
    String? name,
    String? packageName,
    IconData? icon,
    Color? iconColor,
    bool? isBlocked,
    DateTime? lastUsed,
    Duration? dailyUsage,
    bool? isSystemApp,
    String? category,
    String? appIconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      isBlocked: isBlocked ?? this.isBlocked,
      lastUsed: lastUsed ?? this.lastUsed,
      dailyUsage: dailyUsage ?? this.dailyUsage,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      category: category ?? this.category,
      appIconUrl: appIconUrl ?? this.appIconUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to map for database storage (your original format)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'package_name': packageName,
      'packageName': packageName, // compatibility
      'appName': name, // compatibility
      'icon_data': icon.codePoint,
      'icon_color': iconColor.value,
      'is_blocked': isBlocked ? 1 : 0,
      'last_used': lastUsed?.millisecondsSinceEpoch,
      'daily_usage_seconds': dailyUsage?.inSeconds,
      'is_system_app': isSystemApp ? 1 : 0,
      'category': category,
      'appIconUrl': appIconUrl ?? '',
      'created_at': createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Convert to JSON string for storage and transmission
  String toJson() => json.encode(toJsonMap());

  // Convert to JSON map (for list serialization and Firebase)
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'name': name,
      'packageName': packageName,
      'appName': name, // compatibility
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily ?? 'MaterialIcons',
      'iconColor': iconColor.value,
      'isBlocked': isBlocked,
      'lastUsed': lastUsed?.toIso8601String(),
      'dailyUsageSeconds': dailyUsage?.inSeconds,
      'isSystemApp': isSystemApp,
      'category': category,
      'appIconUrl': appIconUrl ?? '',
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Firebase compatibility
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'packageName': packageName,
      'appName': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily ?? 'MaterialIcons',
      'iconColor': iconColor.value,
      'isBlocked': isBlocked,
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
      'dailyUsageSeconds': dailyUsage?.inSeconds,
      'isSystemApp': isSystemApp,
      'category': category,
      'appIconUrl': appIconUrl ?? '',
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : Timestamp.now(),
      'updatedAt':
          updatedAt != null ? Timestamp.fromDate(updatedAt!) : Timestamp.now(),
    };
  }

  // Create an app from map (your original format)
  factory AppModel.fromMap(Map<String, dynamic> map) {
    return AppModel(
      id: map['id'] ?? '',
      name: map['name'] ?? map['appName'] ?? '',
      packageName: map['package_name'] ?? map['packageName'] ?? '',
      icon: IconData(
        map['icon_data'] ?? map['iconCodePoint'] ?? Icons.android.codePoint,
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
      ),
      iconColor:
          Color(map['icon_color'] ?? map['iconColor'] ?? Colors.blue.value),
      isBlocked: (map['is_blocked'] ?? map['isBlocked']) == 1 ||
          (map['is_blocked'] ?? map['isBlocked']) == true,
      lastUsed: map['last_used'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used'])
          : (map['lastUsed'] != null ? DateTime.parse(map['lastUsed']) : null),
      dailyUsage: map['daily_usage_seconds'] != null
          ? Duration(seconds: map['daily_usage_seconds'])
          : (map['dailyUsageSeconds'] != null
              ? Duration(seconds: map['dailyUsageSeconds'])
              : null),
      isSystemApp: (map['is_system_app'] ?? map['isSystemApp']) == 1 ||
          (map['is_system_app'] ?? map['isSystemApp']) == true,
      category: map['category'] ?? 'Other',
      appIconUrl: map['appIconUrl'] ?? map['app_icon_url'],
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : (map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : null),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : (map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'])
              : null),
    );
  }

  // Create an app from JSON string
  factory AppModel.fromJson(String jsonString) {
    final Map<String, dynamic> map = json.decode(jsonString);
    return AppModel.fromJsonMap(map);
  }

  // Create an app from JSON map (for list deserialization)
  factory AppModel.fromJsonMap(Map<String, dynamic> map) {
    return AppModel(
      id: map['id'] ?? '',
      name: map['name'] ?? map['appName'] ?? '',
      packageName: map['packageName'] ?? '',
      icon: IconData(
        map['iconCodePoint'] ?? Icons.android.codePoint,
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
      ),
      iconColor: Color(map['iconColor'] ?? Colors.blue.value),
      isBlocked: map['isBlocked'] ?? false,
      lastUsed:
          map['lastUsed'] != null ? DateTime.parse(map['lastUsed']) : null,
      dailyUsage: map['dailyUsageSeconds'] != null
          ? Duration(seconds: map['dailyUsageSeconds'])
          : null,
      isSystemApp: map['isSystemApp'] ?? false,
      category: map['category'] ?? 'Other',
      appIconUrl: map['appIconUrl'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  // Firebase compatibility
  factory AppModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppModel(
      id: doc.id,
      name: data['name'] ?? data['appName'] ?? '',
      packageName: data['packageName'] ?? '',
      icon: IconData(
        data['iconCodePoint'] ?? Icons.android.codePoint,
        fontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
      ),
      iconColor: Color(data['iconColor'] ?? Colors.blue.value),
      isBlocked: data['isBlocked'] ?? false,
      lastUsed: data['lastUsed'] != null
          ? (data['lastUsed'] as Timestamp).toDate()
          : null,
      dailyUsage: data['dailyUsageSeconds'] != null
          ? Duration(seconds: data['dailyUsageSeconds'])
          : null,
      isSystemApp: data['isSystemApp'] ?? false,
      category: data['category'] ?? 'Other',
      appIconUrl: data['appIconUrl'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Static method to create list from JSON string
  static List<AppModel> listFromJson(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => AppModel.fromJsonMap(json)).toList();
  }

  // Static method to convert list to JSON string
  static String listToJson(List<AppModel> apps) {
    final List<Map<String, dynamic>> jsonList =
        apps.map((app) => app.toJsonMap()).toList();
    return json.encode(jsonList);
  }

  // Helper method to get initials for display
  String get initials {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  // Helper method to check if app was used today
  bool get wasUsedToday {
    if (lastUsed == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final usedDate = DateTime(lastUsed!.year, lastUsed!.month, lastUsed!.day);
    return usedDate.isAtSameMomentAs(today);
  }

  // Helper method to get formatted daily usage
  String get formattedDailyUsage {
    if (dailyUsage == null) return '0m';
    final hours = dailyUsage!.inHours;
    final minutes = dailyUsage!.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Helper method to get usage color based on time
  Color get usageColor {
    if (dailyUsage == null) return Colors.grey;
    final minutes = dailyUsage!.inMinutes;

    if (minutes < 30) return Colors.green;
    if (minutes < 120) return Colors.orange;
    return Colors.red;
  }

  // Helper method to check if app is a social media app
  bool get isSocialMedia {
    final socialPackages = [
      'com.facebook.katana',
      'com.instagram.android',
      'com.twitter.android',
      'com.snapchat.android',
      'com.zhiliaoapp.musically', // TikTok
      'com.pinterest',
      'com.linkedin.android',
      'com.reddit.frontpage',
      'com.discord',
    ];
    return socialPackages.contains(packageName) ||
        category.toLowerCase().contains('social');
  }

  // Helper method to check if app is entertainment
  bool get isEntertainment {
    final entertainmentPackages = [
      'com.google.android.youtube',
      'com.spotify.music',
      'com.netflix.mediaclient',
      'com.amazon.avod.thirdpartyclient', // Prime Video
      'com.disney.disneyplus',
      'com.hulu.plus',
      'com.twitch.android.app',
    ];
    return entertainmentPackages.contains(packageName) ||
        category.toLowerCase().contains('entertainment');
  }

  // Equality operators
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppModel &&
        other.id == id &&
        other.packageName == packageName;
  }

  @override
  int get hashCode => id.hashCode ^ packageName.hashCode;

  // For debugging
  @override
  String toString() {
    return 'AppModel(id: $id, name: $name, packageName: $packageName, isBlocked: $isBlocked, category: $category)';
  }
}
