import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

final couponsRepositoryProvider = Provider<CouponsRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return CouponsRepository(dio);
});

final couponsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(couponsRepositoryProvider);
  return repository.fetchCoupons();
});

class CouponsRepository {
  final Dio _dio;

  CouponsRepository(this._dio);

  Future<List<Map<String, dynamic>>> fetchCoupons() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminCoupons);
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.type == DioExceptionType.connectionError) {
        return [];
      }
      throw Exception('Failed to fetch coupons: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.adminCoupons, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to create coupon';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> updateCoupon(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('${ApiEndpoints.adminCoupons}/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to update coupon';
      throw Exception(message);
    }
  }

  Future<void> deleteCoupon(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.adminCoupons}/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to delete coupon';
      throw Exception(message);
    }
  }
}
