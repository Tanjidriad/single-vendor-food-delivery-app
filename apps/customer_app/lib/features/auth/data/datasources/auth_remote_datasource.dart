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
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authRegister,
      data: {
        'email': email,
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
    required String email,
    required String purpose,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authOtpSend,
      data: {'email': email, 'purpose': purpose},
    );
    return response.data!;
  }

  Future<void> verifyOtp({
    required String email,
    required String code,
    required String purpose,
  }) async {
    await _dio.post(
      ApiEndpoints.authOtpVerify,
      data: {'email': email, 'code': code, 'purpose': purpose},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.authForgotPasswordReset,
      data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      },
    );
  }
}
