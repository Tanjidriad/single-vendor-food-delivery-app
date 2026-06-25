import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

final uploadsRepositoryProvider = Provider<UploadsRepository>((ref) {
  return UploadsRepository(ref.watch(apiClientProvider));
});

/// Uploads images to the backend (Cloudinary) and returns the hosted URL.
///
/// Proof-of-delivery photos must be a real, server-hosted URL — a local device
/// file path is meaningless to the backend and to the customer/support views.
class UploadsRepository {
  UploadsRepository(this._api);

  final ApiClient _api;

  /// Uploads a proof-of-delivery photo and returns its hosted URL.
  ///
  /// Throws an [Exception] with a user-facing message on failure so the caller
  /// can keep the rider on the step and let them retry.
  Future<String> uploadDeliveryProof(String filePath) async {
    try {
      final fileName = filePath.split(Platform.pathSeparator).last;
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: _contentTypeFor(fileName),
        ),
      });
      final res = await _api.post(
        ApiEndpoints.uploadsDeliveryProof,
        data: form,
      );
      final data = res.data;
      final url = data is Map ? data['url']?.toString() : null;
      if (url == null || url.isEmpty) {
        throw Exception('Upload did not return a URL.');
      }
      return url;
    } on DioException catch (e) {
      throw Exception(_message(e, 'Could not upload the photo. Please retry.'));
    }
  }

  MediaType _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  String _message(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      return m is List ? m.first.toString() : m.toString();
    }
    return fallback;
  }
}
