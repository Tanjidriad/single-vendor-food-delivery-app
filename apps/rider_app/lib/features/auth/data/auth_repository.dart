import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Login and store both access + refresh tokens.
  /// Returns the full response data on success.
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        if (accessToken != null && refreshToken != null) {
          await _apiClient.saveTokens(accessToken, refreshToken);
          return data;
        }
        throw Exception('Invalid login response');
      }
      throw Exception('Login failed');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'];
        if (message != null) {
          throw Exception(message is List ? message.first : message);
        }
      }
      throw Exception('Failed to login. Please try again.');
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _apiClient.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (e) {
      debugPrint('Logout API call failed (continuing anyway): $e');
    }
    await _apiClient.clearTokens();
  }

  Future<bool> checkAuthStatus() async {
    final token = await _apiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> sendPasswordResetOtp({required String email}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.otpSend,
        data: {'email': email, 'purpose': 'RESET_PASSWORD'},
      );
      final data = response.data as Map<String, dynamic>;
      return data['devCode'] as String?;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'];
        if (message != null) {
          throw Exception(message is List ? message.first : message);
        }
      }
      throw Exception('Could not send code.');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.forgotPasswordReset,
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'];
        if (message != null) {
          throw Exception(message is List ? message.first : message);
        }
      }
      throw Exception('Failed to reset password.');
    }
  }
}
