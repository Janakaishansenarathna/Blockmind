// models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  planStart,
  planEnd,
  blockAttempt,
  usageMilestone,
  streakAchievement,
  tip,
  subscription
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values[data['type'] ?? 0],
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.index,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      type: NotificationType.values[json['type'] ?? 0],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
    );
  }

  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: true,
      metadata: metadata,
    );
  }

  // Create a plan start notification
  static NotificationModel createPlanStartNotification(
      String userId, String planName) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: NotificationType.planStart,
      title: 'Plan Started',
      message: '$planName is now active and blocking distractions.',
      timestamp: DateTime.now(),
      metadata: {'planName': planName},
    );
  }

  // Create a plan end notification
  static NotificationModel createPlanEndNotification(
      String userId, String planName) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: NotificationType.planEnd,
      title: 'Plan Ended',
      message: '$planName has finished.',
      timestamp: DateTime.now(),
      metadata: {'planName': planName},
    );
  }

  // Create a usage milestone notification
  static NotificationModel createUsageMilestoneNotification(
      String userId, String appName, int minutes) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: NotificationType.usageMilestone,
      title: 'App Usage Alert',
      message: 'You\'ve spent $minutes minutes on $appName today.',
      timestamp: DateTime.now(),
      metadata: {'appName': appName, 'minutes': minutes},
    );
  }

  // Create a digital wellbeing tip notification
  static NotificationModel createTipNotification(String userId, String tip) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: NotificationType.tip,
      title: 'Digital Wellbeing Tip',
      message: tip,
      timestamp: DateTime.now(),
    );
  }
}
