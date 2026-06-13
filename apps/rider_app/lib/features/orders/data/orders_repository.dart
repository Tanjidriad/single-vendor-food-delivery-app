import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrdersRepository(apiClient);
});

class OrdersRepository {
  final ApiClient _apiClient;

  OrdersRepository(this._apiClient);

  /// Accept a rider assignment
  Future<Map<String, dynamic>> acceptAssignment(String assignmentId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.acceptAssignment(assignmentId),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      debugPrint('Error accepting assignment: $message');
      throw Exception(message);
    }
  }

  /// Reject a rider assignment
  Future<Map<String, dynamic>> rejectAssignment(String assignmentId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.rejectAssignment(assignmentId),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      debugPrint('Error rejecting assignment: $message');
      throw Exception(message);
    }
  }

  /// Get a single order by ID
  Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.orderById(orderId),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      debugPrint('Error fetching order: $message');
      throw Exception(message);
    }
  }

  /// Update order status (PICKED_UP, ON_THE_WAY, DELIVERED)
  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status, {
    String? note,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.updateOrderStatus(orderId),
        data: {
          'status': status,
          if (note != null) 'note': note,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      debugPrint('Error updating order status: $message');
      throw Exception(message);
    }
  }

  /// Verify delivery OTP to complete the order
  Future<Map<String, dynamic>> verifyDeliveryOtp(
    String orderId,
    String otp, {
    String? dropoffPhotoUrl,
    String? pickupExperience,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyDelivery(orderId),
        data: {
          'otp': otp,
          if (dropoffPhotoUrl != null) 'dropoffPhotoUrl': dropoffPhotoUrl,
          if (pickupExperience != null) 'pickupExperience': pickupExperience,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      debugPrint('Error verifying delivery OTP: $message');
      throw Exception(message);
    }
  }

  /// Pending offers awaiting accept/reject (reconnect recovery).
  Future<List<Map<String, dynamic>>> fetchPendingAssignments() async {
    try {
      debugPrint('[AssignBridge] GET ${ApiEndpoints.pendingAssignments}');
      final response = await _apiClient.get(ApiEndpoints.pendingAssignments);
      final data = response.data;
      debugPrint('[AssignBridge] response type=${data.runtimeType} length=${data is List ? data.length : "N/A"}');
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      debugPrint('[AssignBridge] fetchPending DioError: $message (status=${e.response?.statusCode})');
      return [];
    }
  }

  Future<Map<String, dynamic>> reportDeliveryException(
    String orderId, {
    required String reason,
    String? note,
    bool foodReturned = false,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.deliveryException(orderId),
        data: {
          'reason': reason,
          if (note != null && note.isNotEmpty) 'note': note,
          'foodReturned': foodReturned,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      debugPrint('Error reporting delivery exception: $message');
      throw Exception(message);
    }
  }

  /// List rider's orders
  Future<List<dynamic>> listOrders({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.orders,
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      debugPrint('Error listing orders: $message');
      throw Exception(message);
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final message = e.response?.data['message'];
      if (message != null) {
        return message is List ? message.first.toString() : message.toString();
      }
    }
    return e.message ?? 'Request failed';
  }
}
