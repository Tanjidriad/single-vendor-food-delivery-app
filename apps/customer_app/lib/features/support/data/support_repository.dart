import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiClientProvider));
});

class SupportRepository {
  SupportRepository(this._dio);

  final Dio _dio;

  Future<void> createComplaint(Map<String, dynamic> body) async {
    await _dio.post(ApiEndpoints.complaints, data: body);
  }

  Future<List<dynamic>> myComplaints() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.complaintsMe);
    return res.data ?? [];
  }
}
