// models/quick_block_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class QuickBlockModel {
  final String id;
  final String userId;
  final List<String> appPackageNames;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final DateTime createdAt;

  QuickBlockModel({
    required this.id,
    required this.userId,
    required this.appPackageNames,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    required this.createdAt,
  });

  factory QuickBlockModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return QuickBlockModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      appPackageNames: List<String>.from(data['appPackageNames'] ?? []),
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 1)),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'appPackageNames': appPackageNames,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'appPackageNames': appPackageNames,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory QuickBlockModel.fromJson(Map<String, dynamic> json) {
    return QuickBlockModel(
      id: json['id'],
      userId: json['userId'],
      appPackageNames: List<String>.from(json['appPackageNames'] ?? []),
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  // Create a new quick block
  factory QuickBlockModel.create({
    required String userId,
    required List<String> appPackageNames,
    required DateTime endTime,
  }) {
    return QuickBlockModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      appPackageNames: appPackageNames,
      startTime: DateTime.now(),
      endTime: endTime,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  QuickBlockModel copyWith({
    String? userId,
    List<String>? appPackageNames,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
  }) {
    return QuickBlockModel(
      id: id,
      userId: userId ?? this.userId,
      appPackageNames: appPackageNames ?? this.appPackageNames,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  // Check if the quick block is currently active
  bool isActiveNow() {
    final now = DateTime.now();
    return isActive && now.isAfter(startTime) && now.isBefore(endTime);
  }

  // Check if an app is blocked by this quick block
  bool isAppBlocked(String packageName) {
    return isActiveNow() && appPackageNames.contains(packageName);
  }
}
