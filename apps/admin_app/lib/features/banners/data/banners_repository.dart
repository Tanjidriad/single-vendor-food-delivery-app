import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

final bannersRepositoryProvider = Provider<BannersRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return BannersRepository(dio);
});

final bannersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(bannersRepositoryProvider);
  return repository.fetchBanners();
});

class BannersRepository {
  final Dio _dio;

  BannersRepository(this._dio);

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminBanners);
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.type == DioExceptionType.connectionError) {
        return [];
      }
      throw Exception('Failed to fetch banners: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createBanner(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.adminBanners, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to create banner';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> updateBanner(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('${ApiEndpoints.adminBanners}/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to update banner';
      throw Exception(message);
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.adminBanners}/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to delete banner';
      throw Exception(message);
    }
  }
}
