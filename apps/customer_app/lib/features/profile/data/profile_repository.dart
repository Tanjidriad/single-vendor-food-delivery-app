import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/models/user_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<UserModel> getMe() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.usersMe);
    return UserModel.fromJson(res.data!);
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.usersMe,
      data: {
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    return UserModel.fromJson(res.data!);
  }

  Future<String> uploadAvatar(File file) async {
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
    return res.data!['url'] as String;
  }
}
