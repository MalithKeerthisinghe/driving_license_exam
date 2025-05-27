import 'package:driving_license_exam/services/http_service.dart';
import '../models/subscription_models.dart';
import 'api_config.dart';

class SubscriptionService {
  static Future<ApiResponse<List<SubscriptionPlan>>> getSubscriptionPlans({
    String? vehicleType,
  }) async {
    try {
      String url = '${ApiConfig.subscriptionBaseUrl}/subscription-plans';
      if (vehicleType != null && vehicleType.isNotEmpty) {
        url += '?vehicle_type=$vehicleType';
      }

      print('Fetching subscription plans from: $url');

      final response = await HttpService.get(url);
      print('Raw API Response: $response');

      // Handle the response structure from your server
      if (response['success'] == true && response['data'] != null) {
        try {
          final plansList = response['data'] as List;
          final plans = plansList
              .map((planJson) => SubscriptionPlan.fromJson(planJson))
              .toList();

          print('Successfully parsed ${plans.length} subscription plans');

          return ApiResponse<List<SubscriptionPlan>>(
            success: true,
            data: plans,
            message: response['message'] ?? 'Plans loaded successfully',
          );
        } catch (parseError) {
          print('Error parsing subscription plans: $parseError');
          return ApiResponse<List<SubscriptionPlan>>(
            success: false,
            data: null,
            message: 'Failed to parse subscription data',
            error: parseError.toString(),
          );
        }
      } else {
        return ApiResponse<List<SubscriptionPlan>>(
          success: false,
          data: null,
          message: response['message'] ?? 'Failed to load subscription plans',
          error: response['error'],
        );
      }

      // Fallback for unexpected response format
      return ApiResponse.fromJson(
        response,
        (data) => (data as List)
            .map((plan) => SubscriptionPlan.fromJson(plan))
            .toList(),
      );
    } catch (e) {
      print('Network error in getSubscriptionPlans: $e');
      return ApiResponse<List<SubscriptionPlan>>(
        success: false,
        data: null,
        message: 'Network error occurred',
        error: e.toString(),
      );
    }
  }

  static Future<ApiResponse<SubscriptionPlan>> getSubscriptionPlan(
      int planId) async {
    try {
      final response = await HttpService.get(
          '${ApiConfig.subscriptionBaseUrl}/subscription-plans/$planId');

      print('Get single plan response: $response');

      return ApiResponse.fromJson(
          response, (data) => SubscriptionPlan.fromJson(data));
    } catch (e) {
      print('Error getting subscription plan: $e');
      return ApiResponse<SubscriptionPlan>(
        success: false,
        data: null,
        message: 'Failed to load subscription plan',
        error: e.toString(),
      );
    }
  }

  static Future<ApiResponse<UserSubscription>> createSubscription({
    required String userId,
    required int planId,
    String? paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final requestBody = {
        'user_id': userId,
        'plan_id': planId,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (paymentDetails != null) 'payment_details': paymentDetails,
      };

      print('Creating subscription with data: $requestBody');

      final response = await HttpService.post(
        '${ApiConfig.subscriptionBaseUrl}/subscriptions',
        body: requestBody,
      );

      print('Create subscription response: $response');

      return ApiResponse.fromJson(
          response, (data) => UserSubscription.fromJson(data));
    } catch (e) {
      print('Error creating subscription: $e');
      return ApiResponse<UserSubscription>(
        success: false,
        data: null,
        message: 'Failed to create subscription',
        error: e.toString(),
      );
    }
  }

  static Future<ApiResponse<List<UserSubscription>>> getUserSubscriptions({
    required String userId,
    String? status,
  }) async {
    try {
      String url =
          '${ApiConfig.subscriptionBaseUrl}/users/$userId/subscriptions';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }

      print('Getting user subscriptions from: $url');

      final response = await HttpService.get(url);
      print('User subscriptions response: $response');

      return ApiResponse.fromJson(
        response,
        (data) => (data as List)
            .map((sub) => UserSubscription.fromJson(sub))
            .toList(),
      );
    } catch (e) {
      print('Error getting user subscriptions: $e');
      return ApiResponse<List<UserSubscription>>(
        success: false,
        data: null,
        message: 'Failed to load user subscriptions',
        error: e.toString(),
      );
    }
  }

  static Future<ApiResponse<UserSubscription>> getSubscription(
      String subscriptionId) async {
    try {
      final response = await HttpService.get(
          '${ApiConfig.subscriptionBaseUrl}/subscriptions/$subscriptionId');

      print('Get subscription response: $response');

      return ApiResponse.fromJson(
          response, (data) => UserSubscription.fromJson(data));
    } catch (e) {
      print('Error getting subscription: $e');
      return ApiResponse<UserSubscription>(
        success: false,
        data: null,
        message: 'Failed to load subscription',
        error: e.toString(),
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> cancelSubscription({
    required String subscriptionId,
    String? reason,
  }) async {
    try {
      // Option 1: If HttpService.delete doesn't support body, use query parameter
      String url =
          '${ApiConfig.subscriptionBaseUrl}/subscriptions/$subscriptionId';
      if (reason != null && reason.isNotEmpty) {
        url += '?reason=${Uri.encodeComponent(reason)}';
      }

      final response = await HttpService.delete(url);

      print('Cancel subscription response: $response');

      return ApiResponse.fromJson(response, (data) => data);
    } catch (e) {
      print('Error cancelling subscription: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        data: null,
        message: 'Failed to cancel subscription',
        error: e.toString(),
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> renewSubscription({
    required String subscriptionId,
    String? paymentMethod,
    bool autoRenewal = false,
  }) async {
    try {
      final response = await HttpService.post(
        '${ApiConfig.subscriptionBaseUrl}/subscriptions/$subscriptionId/renew',
        body: {
          if (paymentMethod != null) 'payment_method': paymentMethod,
          'auto_renewal': autoRenewal,
        },
      );

      print('Renew subscription response: $response');

      return ApiResponse.fromJson(response, (data) => data);
    } catch (e) {
      print('Error renewing subscription: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        data: null,
        message: 'Failed to renew subscription',
        error: e.toString(),
      );
    }
  }

  // Additional helper method to check subscription status
  static Future<ApiResponse<Map<String, dynamic>>> getSubscriptionStatus(
      String subscriptionId) async {
    try {
      final response = await HttpService.get(
          '${ApiConfig.subscriptionBaseUrl}/subscriptions/$subscriptionId/status');

      print('Subscription status response: $response');

      return ApiResponse.fromJson(response, (data) => data);
    } catch (e) {
      print('Error getting subscription status: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        data: null,
        message: 'Failed to check subscription status',
        error: e.toString(),
      );
    }
  }
}
