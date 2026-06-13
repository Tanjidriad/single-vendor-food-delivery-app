import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});

class OrdersRepository {
  OrdersRepository(this._dio);

  final Dio _dio;

  Future<List<dynamic>> listOrders() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.orders);
    return res.data ?? [];
  }

  Future<Map<String, dynamic>> getOrder(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.order(id));
    return res.data!;
  }

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.orders, data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> deliveryFeeQuote(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.deliveryFeeQuote, data: body);
    return res.data!;
  }

  Future<List<dynamic>> listPublicCoupons(String restaurantId) async {
    final res = await _dio.get<List<dynamic>>(
      ApiEndpoints.couponsPublic,
      queryParameters: {'restaurantId': restaurantId},
    );
    return res.data ?? [];
  }

  Future<Map<String, dynamic>> validateCoupon(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.couponsValidate, data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> confirmDelivery(String id) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.orderConfirmDelivery(id));
    return res.data!;
  }

  Future<Map<String, dynamic>> cancelOrder(String id, {String? reason}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.orderCancel(id),
      data: {if (reason != null) 'reason': reason},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> reorder(String id) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.orderReorder(id));
    return res.data!;
  }

  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.orderReview(orderId),
      data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    return res.data!;
  }
}
