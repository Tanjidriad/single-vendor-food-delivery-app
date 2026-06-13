import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

final ridersRepositoryProvider = Provider<RidersRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return RidersRepository(dio);
});

class RidersRepository {
  final Dio _dio;

  RidersRepository(this._dio);

  Future<List<Map<String, dynamic>>> fetchActiveRiders() async {
    final response = await _dio.get(ApiEndpoints.adminRiders);
    if (response.statusCode == 200) {
      final List data = response.data;
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Failed to fetch active riders');
  }

  Future<List<Map<String, dynamic>>> fetchPendingRiders() async {
    final response = await _dio.get(ApiEndpoints.adminRidersPending);
    if (response.statusCode == 200) {
      final List data = response.data;
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Failed to fetch pending riders');
  }

  Future<void> updateRiderApproval(String id, String status) async {
    final response = await _dio.patch(
      ApiEndpoints.adminRidersApprove(id),
      data: {'status': status},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update rider status');
    }
  }
}
