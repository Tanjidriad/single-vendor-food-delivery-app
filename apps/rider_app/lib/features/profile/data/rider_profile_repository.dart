import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/map_dio_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

final riderProfileRepositoryProvider = Provider<RiderProfileRepository>((ref) {
  return RiderProfileRepository(ref.watch(apiClientProvider));
});

/// Rider profile mutations (name, avatar, work details).
class RiderProfileRepository {
  RiderProfileRepository(this._api);

  final ApiClient _api;

  Future<void> updateFullName(String fullName) async {
    try {
      await _api.patch(ApiEndpoints.me, data: {'fullName': fullName});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Uploads an image to Cloudinary and persists the URL on the rider profile.
  Future<String> updateProfilePhoto({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: _contentTypeFor(fileName),
        ),
      });
      final uploadRes = await _api.post(ApiEndpoints.uploadsAvatar, data: form);
      final data = uploadRes.data;
      final url = data is Map ? data['url']?.toString() : null;
      if (url == null || url.isEmpty) {
        throw const ServerFailure('Upload did not return a URL.');
      }
      await updateAvatarUrl(url);
      return url;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> updateAvatarUrl(String? avatarUrl) async {
    try {
      await _api.patch(
        ApiEndpoints.me,
        data: {'avatarUrl': avatarUrl ?? ''},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> removeProfilePhoto() => updateAvatarUrl(null);

  Future<void> updateWorkDetails({
    String? vehicleType,
    String? vehicleModel,
    String? vehicleRegistration,
    String? zone,
  }) async {
    try {
      await _api.patch(
        ApiEndpoints.riderProfile,
        data: {
          'vehicleType': ?vehicleType,
          'vehicleModel': ?vehicleModel,
          'vehicleRegistration': ?vehicleRegistration,
          'zone': ?zone,
        },
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  MediaType? _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }
}
