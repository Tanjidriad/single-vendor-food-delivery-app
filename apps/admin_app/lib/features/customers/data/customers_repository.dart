import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return CustomersRepository(dio);
});

final customersListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(customersRepositoryProvider);
  return repository.fetchCustomers();
});

class CustomersRepository {
  final Dio _dio;
  CustomersRepository(this._dio);

  /// NOTE: Your backend currently has NO admin endpoint to list all customers.
  /// The /users controller only exposes GET /users/me (current user's profile).
  ///
  /// To make this screen work with real data, you would need to add a new
  /// endpoint in the backend like:
  ///   GET /admin/users?role=CUSTOMER&page=1&limit=50
  ///
  /// For now, this calls GET /users/me as a placeholder (returns current admin user).
  /// Replace with the proper admin endpoint once you build it.
  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    try {
      final response = await _dio.get(ApiEndpoints.usersMe);
      final data = response.data;
      // Until a proper admin list endpoint exists, wrap the single user result
      if (data is Map<String, dynamic>) {
        return [data];
      }
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.type == DioExceptionType.connectionError) {
        return [];
      }
      throw Exception('Failed to fetch customers: ${e.message}');
    }
  }
}
