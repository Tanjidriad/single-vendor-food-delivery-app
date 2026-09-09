import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'notification_model.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> listNotifications() async {
    try {
      final res = await _api.get(ApiEndpoints.notifications);
      final raw = res.data;
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Could not load notifications.'));
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.patch(ApiEndpoints.notificationRead(id));
    } on DioException catch (e) {
      throw Exception(_message(e, 'Could not mark notification as read.'));
    }
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
