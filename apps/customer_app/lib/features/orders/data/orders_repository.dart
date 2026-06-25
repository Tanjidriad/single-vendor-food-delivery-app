import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/map_dio_exception.dart';
import '../../../core/network/api_client.dart';
import 'models/order_model.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});

class OrdersRepository {
  OrdersRepository(this._dio);

  final Dio _dio;

  /// Lists the current user's orders as typed [OrderModel]s.
  Future<List<OrderModel>> listOrders() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.orders);
      final list = res.data ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Fetches a single order by [id] as a typed [OrderModel].
  Future<OrderModel> getOrder(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.order(id));
      final data = res.data;
      if (data == null) throw const ServerFailure('Order not found.');
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> body) async {
    return _postMap(ApiEndpoints.orders, data: body, emptyError: 'Could not place your order.');
  }

  Future<Map<String, dynamic>> deliveryFeeQuote(Map<String, dynamic> body) async {
    return _postMap(ApiEndpoints.deliveryFeeQuote, data: body);
  }

  Future<List<dynamic>> listPublicCoupons(String restaurantId) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.couponsPublic,
        queryParameters: {'restaurantId': restaurantId},
      );
      return res.data ?? [];
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> validateCoupon(Map<String, dynamic> body) async {
    return _postMap(ApiEndpoints.couponsValidate, data: body);
  }

  Future<Map<String, dynamic>> confirmDelivery(String id) async {
    return _postMap(ApiEndpoints.orderConfirmDelivery(id));
  }

  Future<Map<String, dynamic>> cancelOrder(String id, {String? reason}) async {
    return _postMap(ApiEndpoints.orderCancel(id), data: {'reason': ?reason});
  }

  Future<Map<String, dynamic>> reorder(String id) async {
    return _postMap(ApiEndpoints.orderReorder(id));
  }

  Future<List<dynamic>> listMessages(String orderId) async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.orderMessages(orderId));
      return res.data ?? [];
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> sendMessage(String orderId, String body) async {
    return _postMap(ApiEndpoints.orderMessages(orderId), data: {'body': body});
  }

  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    return _postMap(ApiEndpoints.orderReview(orderId), data: {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  /// Shared POST helper: null-safe body handling + [DioException] → [Failure].
  Future<Map<String, dynamic>> _postMap(
    String path, {
    Map<String, dynamic>? data,
    String emptyError = 'Something went wrong. Please try again.',
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: data);
      final body = res.data;
      if (body == null) throw ServerFailure(emptyError);
      return body;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
