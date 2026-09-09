import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> register({
    String? email,
    String? phone,
    required String password,
    required String fullName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authRegister,
      data: {
        'email': ?email,
        'phone': ?phone,
        'password': password,
        'fullName': fullName,
      },
    );
    return response.data!;
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post(ApiEndpoints.authLogout, data: {'refreshToken': refreshToken});
  }

  Future<Map<String, dynamic>> sendOtp({
    String? phone,
    String? email,
    required String purpose,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authOtpSend,
      data: {
        'phone': ?phone,
        'email': ?email,
        'purpose': purpose,
      },
    );
    return response.data!;
  }

  /// Verifies OTP and returns auth tokens (used for LOGIN purpose).
  Future<Map<String, dynamic>> verifyOtpLogin({
    String? phone,
    String? email,
    required String code,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authOtpVerify,
      data: {
        'phone': ?phone,
        'email': ?email,
        'code': code,
        'purpose': 'LOGIN',
      },
    );
    return response.data!;
  }

  /// Verifies OTP without returning tokens (used for VERIFY_PHONE purpose).
  Future<void> verifyOtp({
    String? phone,
    String? email,
    required String code,
    required String purpose,
  }) async {
    await _dio.post(
      ApiEndpoints.authOtpVerify,
      data: {
        'phone': ?phone,
        'email': ?email,
        'code': code,
        'purpose': purpose,
      },
    );
  }

  Future<void> resetPassword({
    String? email,
    String? phone,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.authForgotPasswordReset,
      data: {
        'email': ?email,
        'phone': ?phone,
        'code': code,
        'newPassword': newPassword,
      },
    );
  }
}
