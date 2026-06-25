import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'chat_message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRepository(apiClient);
});

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  /// Loads the full message history for [orderId], oldest first.
  Future<List<ChatMessage>> listMessages(String orderId) async {
    final response = await _apiClient.get(ApiEndpoints.orderMessages(orderId));
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Object>()
          .map((e) => ChatMessage.fromJson(
                e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }
    return const [];
  }

  /// Posts a new message to [orderId]'s thread and returns the created message.
  Future<ChatMessage?> sendMessage(String orderId, String body) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.orderMessages(orderId),
        data: {'body': body},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return ChatMessage.fromJson(data);
      if (data is Map) return ChatMessage.fromJson(Map<String, dynamic>.from(data));
      return null;
    } catch (e) {
      debugPrint('[ChatRepository] sendMessage failed: $e');
      rethrow;
    }
  }
}
