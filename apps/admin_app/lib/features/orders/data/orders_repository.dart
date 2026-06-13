import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return OrdersRepository(dio);
});

final liveOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(ordersRepositoryProvider);
  return repository.fetchLiveOrders();
});

class OrdersRepository {
  final Dio _dio;
  OrdersRepository(this._dio);

  /// Fetches orders from GET /orders
  /// Backend returns paginated results based on the authenticated user's role:
  ///   - OWNER/MANAGER/CASHIER/KITCHEN → gets restaurant orders
  ///   - CUSTOMER → gets their own orders
  Future<List<Map<String, dynamic>>> fetchLiveOrders({int page = 1, int limit = 50}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.orders,
        queryParameters: {'page': page, 'limit': limit},
      );
      // The backend's listForUser returns { data: [...], meta: {...} }
      final data = response.data;
      if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      // Fallback: if backend returns a plain list
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } on DioException catch (e) {
      // If unauthorized or server not running, return empty for now
      if (e.response?.statusCode == 401 || e.type == DioExceptionType.connectionError) {
        return [];
      }
      throw Exception('Failed to fetch orders: ${e.message}');
    }
  }

  /// Updates an order's status via PATCH /orders/:id/status.
  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.updateOrderStatus(orderId),
        data: {'status': status},
      );
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {};
    } on DioException catch (e) {
      throw Exception('Failed to update order status: ${e.message}');
    }
  }
}
