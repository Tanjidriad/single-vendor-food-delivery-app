import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  return AddressesRepository(ref.watch(apiClientProvider));
});

class AddressesRepository {
  AddressesRepository(this._dio);

  final Dio _dio;

  Future<List<dynamic>> list() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.addresses);
    return res.data ?? [];
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.addresses, data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> body) async {
    final res = await _dio.patch<Map<String, dynamic>>(ApiEndpoints.address(id), data: body);
    return res.data!;
  }

  Future<void> delete(String id) async {
    await _dio.delete(ApiEndpoints.address(id));
  }

  Future<Map<String, dynamic>> geocode(String address) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.deliveryFeeGeocode,
      queryParameters: {'address': address},
    );
    return res.data!;
  }
}
