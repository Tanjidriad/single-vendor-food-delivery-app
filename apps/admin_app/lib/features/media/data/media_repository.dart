import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/media_item.dart';
import 'package:image_picker/image_picker.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MediaRepository(apiClient);
});

class MediaRepository {
  final Dio _apiClient;

  MediaRepository(this._apiClient);

  Future<List<MediaItem>> getMedia({String? category}) async {
    final response = await _apiClient.get(
      ApiEndpoints.adminMedia,
      queryParameters: category != null ? {'category': category} : null,
    );
    return (response.data as List)
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MediaItem> uploadMedia(XFile file, String category) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });

    final response = await _apiClient.post(
      ApiEndpoints.adminMedia,
      data: formData,
      queryParameters: {'category': category},
    );
    return MediaItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteMedia(String id) async {
    await _apiClient.delete('${ApiEndpoints.adminMedia}/$id');
  }
}
