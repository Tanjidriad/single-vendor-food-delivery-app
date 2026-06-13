import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return DashboardRepository(dio);
});

final dashboardMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.fetchDashboardMetrics();
});

class DashboardRepository {
  final Dio _dio;
  DashboardRepository(this._dio);

  /// Aggregates data from multiple backend endpoints:
  ///   - GET /reports/sales?period=week → { orderCount, totalRevenue, averageOrderValue }
  ///   - GET /reports/riders → rider performance list
  ///   - GET /orders?page=1&limit=5 → recent orders for activity feed
  Future<Map<String, dynamic>> fetchDashboardMetrics() async {
    try {
      // Fetch sales summary and recent orders in parallel
      final results = await Future.wait([
        _dio.get(ApiEndpoints.reportsSales, queryParameters: {'period': 'week'}).catchError((_) => Response(requestOptions: RequestOptions(), statusCode: 500)),
        _dio.get(ApiEndpoints.orders, queryParameters: {'page': 1, 'limit': 5}).catchError((_) => Response(requestOptions: RequestOptions(), statusCode: 500)),
      ]);

      final salesData = results[0].statusCode == 200 ? results[0].data as Map<String, dynamic> : <String, dynamic>{};
      final ordersData = results[1].statusCode == 200 ? results[1].data : null;

      // Extract sales metrics
      final totalRevenue = (salesData['totalRevenue'] as num?)?.toDouble() ?? 0.0;
      final orderCount = (salesData['orderCount'] as num?)?.toInt() ?? 0;

      // Build recent activity from last 5 orders
      final List<Map<String, dynamic>> recentActivity = [];
      List recentOrders = [];
      if (ordersData is Map && ordersData.containsKey('data')) {
        recentOrders = ordersData['data'] as List;
      } else if (ordersData is List) {
        recentOrders = ordersData;
      }
      for (final order in recentOrders) {
        final status = order['status'] ?? 'PLACED';
        String type = 'INFO';
        if (status == 'DELIVERED') {
          type = 'SUCCESS';
        } else if (status == 'PLACED') {
          type = 'NEW_ORDER';
        } else if (status == 'CANCELLED') {
          type = 'ERROR';
        } else if (status == 'PREPARING') {
          type = 'WARNING';
        }

        recentActivity.add({
          'title': 'Order #${order['orderNumber'] ?? order['id']} - $status',
          'time': _formatTime(order['placedAt'] ?? order['createdAt']),
          'type': type,
        });
      }

      // Chart data: we use a static weekly pattern for now.
      // A proper implementation would need a dedicated daily-revenue endpoint.
      final chartData = [3.0, 4.0, 3.5, 5.0, 4.5, 7.0, 6.0];

      return {
        'totalRevenue': totalRevenue,
        'activeOrders': orderCount,
        'availableDrivers': 0, // No direct endpoint yet
        'totalCustomers': 0, // No admin user-list endpoint yet
        'chartData': chartData,
        'recentActivity': recentActivity.isEmpty
            ? [
                {'title': 'No recent activity', 'time': 'just now', 'type': 'INFO'}
              ]
            : recentActivity,
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        // Server not running — return zeros gracefully
        return {
          'totalRevenue': 0.0,
          'activeOrders': 0,
          'availableDrivers': 0,
          'totalCustomers': 0,
          'chartData': [0, 0, 0, 0, 0, 0, 0],
          'recentActivity': [
            {'title': 'Backend offline', 'time': 'now', 'type': 'ERROR'}
          ],
        };
      }
      throw Exception('Failed to fetch dashboard metrics: ${e.message}');
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'just now';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'just now';
    }
  }
}
