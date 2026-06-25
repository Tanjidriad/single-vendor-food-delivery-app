import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/map_dio_exception.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/models/user_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<UserModel> getMe() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.usersMe);
      final data = res.data;
      if (data == null) throw const ServerFailure('Could not load your profile.');
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.usersMe,
        data: {
          'fullName': ?fullName,
          'phone': ?phone,
          'avatarUrl': ?avatarUrl,
        },
      );
      final data = res.data;
      if (data == null) throw const ServerFailure('Could not update your profile.');
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<String> uploadAvatar(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.uploadsAvatar,
        data: formData,
      );
      final url = res.data?['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ServerFailure('Avatar upload failed. Please try again.');
      }
      return url;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
