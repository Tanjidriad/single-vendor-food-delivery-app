import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/map_dio_exception.dart';
import '../../../core/network/api_client.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(apiClientProvider));
});

class PaymentsRepository {
  PaymentsRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> initiateOnline(String orderId) {
    return _postMap(ApiEndpoints.paymentOnlineInitiate(orderId),
        emptyError: 'Could not start the payment.');
  }

  Future<Map<String, dynamic>> executeOnline({
    required String orderId,
    required String paymentId,
  }) {
    return _postMap(
      ApiEndpoints.paymentOnlineExecute(orderId),
      data: {'paymentId': paymentId},
      emptyError: 'Could not complete the payment.',
    );
  }

  Future<Map<String, dynamic>> _postMap(
    String path, {
    Map<String, dynamic>? data,
    required String emptyError,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: data);
      final body = res.data;
      if (body == null) throw ServerFailure(emptyError);
      return body;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
