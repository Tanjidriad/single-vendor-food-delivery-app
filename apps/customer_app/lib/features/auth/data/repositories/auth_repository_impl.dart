import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _remote.login(email: email, password: password);
      return _mapAuthResponse(data);
    } on DioException catch (e) {
      throw AuthRepositoryException(ServerFailure(_dioMessage(e)));
    } on AuthRepositoryException {
      rethrow;
    } catch (e) {
      throw AuthRepositoryException(ServerFailure(e.toString()));
    }
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final data = await _remote.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      return _mapAuthResponse(data);
    } on DioException catch (e) {
      throw AuthRepositoryException(ServerFailure(_dioMessage(e)));
    } on AuthRepositoryException {
      rethrow;
    } catch (e) {
      throw AuthRepositoryException(ServerFailure(e.toString()));
    }
  }

  @override
  Future<String?> sendPasswordResetOtp({required String email}) async {
    try {
      final data = await _remote.sendOtp(
        email: email,
        purpose: 'RESET_PASSWORD',
      );
      return data['devCode'] as String?;
    } on DioException catch (e) {
      throw AuthRepositoryException(ServerFailure(_dioMessage(e)));
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _remote.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
    } on DioException catch (e) {
      throw AuthRepositoryException(ServerFailure(_dioMessage(e)));
    }
  }

  @override
  Future<String?> sendVerifyEmailOtp({required String email}) async {
    try {
      final data = await _remote.sendOtp(
        email: email,
        purpose: 'VERIFY_PHONE',
      );
      return data['devCode'] as String?;
    } on DioException catch (e) {
      throw AuthRepositoryException(ServerFailure(_dioMessage(e)));
    }
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    try {
      await _remote.verifyOtp(
        email: email,
        code: code,
        purpose: 'VERIFY_PHONE',
      );
    } on DioException catch (e) {
      throw AuthRepositoryException(ServerFailure(_dioMessage(e)));
    }
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    try {
      await _remote.logout(refreshToken);
    } on DioException catch (e) {
      throw AuthRepositoryException(ServerFailure(e.message ?? 'Logout failed'));
    }
  }

  AuthResult _mapAuthResponse(Map<String, dynamic> data) {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) {
      throw AuthRepositoryException(
        const ServerFailure('Invalid auth response from server'),
      );
    }
    final user = UserModel.fromJson(data).toEntity();
    return (
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List) {
        return message.map((m) => m.toString()).join(', ');
      }
      final nested = data['error'];
      if (nested is String && nested.isNotEmpty) return nested;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach server. Is the API running at ${e.requestOptions.baseUrl}?';
    }
    return e.message ?? 'Request failed';
  }
}
