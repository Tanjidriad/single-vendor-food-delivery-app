import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // We use the base dioProvider here so that login requests don't get intercepted
  // and trigger an infinite loop of 401 token refreshes.
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authLogin,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      // Backend returns { accessToken, refreshToken, user: { ... } }
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'] ?? 'Login failed';
        throw Exception(message);
      }
      throw Exception('Failed to connect to the server.');
    }
  }
}
