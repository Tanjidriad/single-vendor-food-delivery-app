import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/map_dio_exception.dart';
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
      return _asMap(response.data, 'Could not accept the assignment.');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Reject a rider assignment
  Future<Map<String, dynamic>> rejectAssignment(String assignmentId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.rejectAssignment(assignmentId),
      );
      return _asMap(response.data, 'Could not reject the assignment.');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Get a single order by ID
  Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.orderById(orderId),
      );
      return _asMap(response.data, 'Order not found.');
    } on DioException catch (e) {
      throw mapDioException(e);
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
          'note': ?note,
        },
      );
      return _asMap(response.data, 'Could not update the order status.');
    } on DioException catch (e) {
      throw mapDioException(e);
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
          'dropoffPhotoUrl': ?dropoffPhotoUrl,
          'pickupExperience': ?pickupExperience,
        },
      );
      return _asMap(response.data, 'Could not verify the delivery code.');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Pending offers awaiting accept/reject (reconnect recovery).
  ///
  /// Intentionally swallows errors and returns an empty list: this runs during
  /// reconnect and must never surface an error to the rider.
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
      debugPrint('[AssignBridge] fetchPending DioError: ${e.message} (status=${e.response?.statusCode})');
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
      return _asMap(response.data, 'Could not report the delivery exception.');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// List rider's orders
  Future<List<dynamic>> listOrders({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.orders,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      return data is List ? data : const [];
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Coerces a response body into a JSON object, or throws a [ServerFailure]
  /// with [emptyError] when the body is missing / the wrong shape.
  Map<String, dynamic> _asMap(Object? data, String emptyError) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ServerFailure(emptyError);
  }
}
