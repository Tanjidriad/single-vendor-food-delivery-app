import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(apiClientProvider));
});

class PaymentsRepository {
  PaymentsRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> initiateOnline(String orderId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.paymentOnlineInitiate(orderId),
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> executeOnline({
    required String orderId,
    required String paymentId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.paymentOnlineExecute(orderId),
      data: {'paymentId': paymentId},
    );
    return res.data!;
  }
}
