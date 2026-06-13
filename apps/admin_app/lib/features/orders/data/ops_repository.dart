import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

final opsRepositoryProvider = Provider<OpsRepository>((ref) {
  return OpsRepository(ref.watch(apiClientProvider));
});

final opsQueuesProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(opsRepositoryProvider).fetchOpsQueues();
});

final pendingRefundsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(opsRepositoryProvider).fetchPendingRefunds();
});

class OpsRepository {
  OpsRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchOpsQueues() async {
    final response = await _dio.get(ApiEndpoints.ordersOpsQueues);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<List<Map<String, dynamic>>> fetchPendingRefunds() async {
    final response = await _dio.get(ApiEndpoints.adminRefundsPending);
    final data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<void> forceUnassign(String orderId, {String? reason}) async {
    await _dio.post(
      ApiEndpoints.forceUnassignOrder(orderId),
      data: {if (reason != null) 'reason': reason},
    );
  }

  Future<void> resolveException(
    String orderId, {
    required String action,
    String? note,
  }) async {
    await _dio.post(
      ApiEndpoints.resolveOrderException(orderId),
      data: {
        'action': action,
        if (note != null) 'note': note,
      },
    );
  }

  Future<void> updateRefund(
    String refundId, {
    required String status,
    String? adminNote,
    String? gatewayRef,
  }) async {
    await _dio.patch(
      ApiEndpoints.adminRefundUpdate(refundId),
      data: {
        'status': status,
        if (adminNote != null) 'adminNote': adminNote,
        if (gatewayRef != null) 'gatewayRef': gatewayRef,
      },
    );
  }
}
