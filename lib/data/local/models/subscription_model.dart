// models/subscription_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionType { free, monthly, yearly, family, lifetime }

class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionType type;
  final double price;
  final String currencyCode;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final String? paymentMethod;
  final String? transactionId;
  final String? receiptData;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.price,
    required this.currencyCode,
    required this.startDate,
    required this.endDate,
    this.autoRenew = true,
    this.paymentMethod,
    this.transactionId,
    this.receiptData,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: SubscriptionType.values[data['type'] ?? 0],
      price: (data['price'] ?? 0.0).toDouble(),
      currencyCode: data['currencyCode'] ?? 'USD',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      autoRenew: data['autoRenew'] ?? true,
      paymentMethod: data['paymentMethod'],
      transactionId: data['transactionId'],
      receiptData: data['receiptData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.index,
      'price': price,
      'currencyCode': currencyCode,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'autoRenew': autoRenew,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'receiptData': receiptData,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'price': price,
      'currencyCode': currencyCode,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'autoRenew': autoRenew,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'receiptData': receiptData,
    };
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'],
      userId: json['userId'],
      type: SubscriptionType.values[json['type'] ?? 0],
      price: (json['price'] ?? 0.0).toDouble(),
      currencyCode: json['currencyCode'] ?? 'USD',
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate']),
      autoRenew: json['autoRenew'] ?? true,
      paymentMethod: json['paymentMethod'],
      transactionId: json['transactionId'],
      receiptData: json['receiptData'],
    );
  }

  // Create subscription for different plans
  factory SubscriptionModel.createMonthly(String userId) {
    return SubscriptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: SubscriptionType.monthly,
      price: 2.99,
      currencyCode: 'USD',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      autoRenew: true,
    );
  }

  factory SubscriptionModel.createYearly(String userId) {
    return SubscriptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: SubscriptionType.yearly,
      price: 24.99,
      currencyCode: 'USD',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 365)),
      autoRenew: true,
    );
  }

  factory SubscriptionModel.createLifetime(String userId) {
    return SubscriptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: SubscriptionType.lifetime,
      price: 49.99,
      currencyCode: 'USD',
      startDate: DateTime.now(),
      // Far future date for lifetime subscription
      endDate: DateTime(2099, 12, 31),
      autoRenew: false,
    );
  }

  bool get isActive {
    return DateTime.now().isBefore(endDate);
  }

  bool get isLifetime {
    return type == SubscriptionType.lifetime;
  }

  // Check if subscription will expire soon (within 3 days)
  bool get isExpiringSoon {
    if (isLifetime) return false;

    final threeDaysFromNow = DateTime.now().add(const Duration(days: 3));
    return endDate.isBefore(threeDaysFromNow) &&
        endDate.isAfter(DateTime.now());
  }
}
