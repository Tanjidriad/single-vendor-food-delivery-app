import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<List<dynamic>> list() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.notifications);
    return res.data ?? [];
  }

  Future<void> markRead(String id) async {
    await _dio.patch(ApiEndpoints.notificationRead(id));
  }
}
