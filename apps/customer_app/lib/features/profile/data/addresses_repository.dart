import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/map_dio_exception.dart';
import '../../../core/network/api_client.dart';

final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  return AddressesRepository(ref.watch(apiClientProvider));
});

class AddressesRepository {
  AddressesRepository(this._dio);

  final Dio _dio;

  Future<List<dynamic>> list() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.addresses);
      return res.data ?? [];
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) {
    return _writeMap(
      () => _dio.post<Map<String, dynamic>>(ApiEndpoints.addresses, data: body),
      emptyError: 'Could not save the address.',
    );
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> body) {
    return _writeMap(
      () => _dio.patch<Map<String, dynamic>>(ApiEndpoints.address(id), data: body),
      emptyError: 'Could not update the address.',
    );
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.address(id));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> geocode(String address) {
    return _writeMap(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.deliveryFeeGeocode,
        queryParameters: {'address': address},
      ),
      emptyError: 'Could not look up that address.',
    );
  }

  /// Runs a request returning a JSON object, null-safe + [DioException] →
  /// [Failure].
  Future<Map<String, dynamic>> _writeMap(
    Future<Response<Map<String, dynamic>>> Function() request, {
    required String emptyError,
  }) async {
    try {
      final res = await request();
      final body = res.data;
      if (body == null) throw ServerFailure(emptyError);
      return body;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
