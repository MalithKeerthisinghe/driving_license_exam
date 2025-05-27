import 'package:flutter/material.dart';

class SubscriptionPlan {
  final int id;
  final String name;
  final int durationMonths;
  final double price;
  final String currency;
  final String vehicleType;
  final String? description;
  final List<String> features;
  final bool isPopular;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.durationMonths,
    required this.price,
    required this.currency,
    required this.vehicleType,
    this.description,
    required this.features,
    required this.isPopular,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    // Handle features from server response
    List<String> featuresList = [];

    if (json['features'] != null) {
      if (json['features'] is String) {
        // If features come as comma-separated string from server
        final featuresString = json['features'] as String;
        if (featuresString.isNotEmpty) {
          featuresList =
              featuresString.split(',').map((f) => f.trim()).toList();
        }
      } else if (json['features'] is List) {
        // If features come as array
        featuresList = List<String>.from(json['features']);
      }
    }

    return SubscriptionPlan(
      id: _parseToInt(json['id']),
      name: json['name'] ?? '',
      durationMonths: _parseToInt(json['duration_months']),
      // Handle price as string or number
      price: _parseToDouble(json['price']),
      currency: json['currency'] ?? 'INR',
      vehicleType: json['vehicle_type'] ?? '',
      description: json['description'],
      features: featuresList,
      // Handle boolean conversion from integer
      isPopular: _parseToBool(json['is_popular']),
      isActive: _parseToBool(json['is_active']),
    );
  }

  // Helper methods for safe parsing
  static int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool _parseToBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  // Helper method for formatted price display
  String get formattedPrice {
    if (currency == 'INR') {
      return 'Rs. ${price.toInt()}';
    }
    return '$currency ${price.toInt()}';
  }

  // Helper method to get display vehicle type
  String get displayVehicleType {
    switch (vehicleType.toLowerCase()) {
      case 'light_vehicle':
        return 'Light Vehicle';
      case 'heavy_vehicle':
        return 'Heavy Vehicle';
      case 'car':
        return 'Car';
      case 'bike':
        return 'Bike';
      case 'special':
        return 'Special';
      default:
        return vehicleType;
    }
  }

  // Helper method to get user-friendly features
  List<String> get displayFeatures {
    if (features.isEmpty) return [];

    return features
        .map((feature) {
          // Clean up feature names
          final cleanFeature = feature.trim();
          if (cleanFeature.isEmpty) return null;

          switch (cleanFeature.toLowerCase()) {
            case 'practice_tests':
              return 'Full access to practice tests';
            case 'feedback_system':
              return 'Detailed feedback system';
            case 'progress_tracking':
              return 'Progress tracking';
            case 'personalized_study':
              return 'Personalized study plans';
            case 'priority_support':
              return 'Priority customer support';
            case 'unlimited_tests':
              return 'Unlimited practice tests';
            case 'offline_access':
              return 'Offline access to content';
            case 'mock_exams':
              return 'Mock exams simulation';
            default:
              // Convert snake_case to readable format
              return cleanFeature
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((word) => word.isNotEmpty
                      ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                      : '')
                  .join(' ');
          }
        })
        .where((feature) => feature != null)
        .cast<String>()
        .toList();
  }

  // Convert to JSON (for sending to server if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration_months': durationMonths,
      'price': price,
      'currency': currency,
      'vehicle_type': vehicleType,
      'description': description,
      'features': features,
      'is_popular': isPopular,
      'is_active': isActive,
    };
  }

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, name: $name, vehicleType: $vehicleType, price: $formattedPrice)';
  }
}

class UserSubscription {
  final String subscriptionId;
  final SubscriptionPlan plan;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final int daysRemaining;
  final bool isExpired;
  final bool autoRenewal;
  final double amountPaid;
  final DateTime createdAt;

  UserSubscription({
    required this.subscriptionId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
    required this.isExpired,
    required this.autoRenewal,
    required this.amountPaid,
    required this.createdAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    // Handle the plan data - API might return incomplete plan info
    Map<String, dynamic> planData = json['plan'] ?? {};

    // Add default values for missing fields to avoid parsing errors
    Map<String, dynamic> completePlanData = {
      'id': planData['id'] ?? 0,
      'name': planData['name'] ?? 'Unknown Plan',
      'duration_months': planData['duration_months'] ?? 0,
      'price': planData['price'] ?? '0.00',
      'currency': planData['currency'] ?? 'INR',
      'vehicle_type': planData['vehicle_type'] ?? 'unknown',
      'description': planData['description'],
      'features': planData['features'] ?? [],
      'is_popular': planData['is_popular'] ?? false,
      'is_active': planData['is_active'] ?? true,
    };

    return UserSubscription(
      subscriptionId: json['subscription_id'] ?? '',
      plan: SubscriptionPlan.fromJson(completePlanData),
      status: json['status'] ?? '',
      startDate: _parseDateTime(json['start_date']),
      endDate: _parseDateTime(json['end_date']),
      daysRemaining: SubscriptionPlan._parseToInt(json['days_remaining']),
      isExpired: SubscriptionPlan._parseToBool(json['is_expired']),
      autoRenewal: SubscriptionPlan._parseToBool(json['auto_renewal']),
      amountPaid: SubscriptionPlan._parseToDouble(json['amount_paid']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // Helper method to get subscription status display
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  // Helper method to get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Helper method to format remaining time
  String get formattedTimeRemaining {
    if (isExpired) return 'Expired';
    if (daysRemaining <= 0) return 'Expires today';
    if (daysRemaining == 1) return '1 day left';
    return '$daysRemaining days left';
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription_id': subscriptionId,
      'plan': plan.toJson(),
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'days_remaining': daysRemaining,
      'is_expired': isExpired,
      'auto_renewal': autoRenewal,
      'amount_paid': amountPaid,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserSubscription(id: $subscriptionId, status: $status, daysRemaining: $daysRemaining)';
  }
}
