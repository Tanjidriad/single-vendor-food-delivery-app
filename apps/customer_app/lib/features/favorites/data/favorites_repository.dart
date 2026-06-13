import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(apiClientProvider));
});

class FavoritesRepository {
  FavoritesRepository(this._dio);

  final Dio _dio;

  Future<List<dynamic>> list() async {
    final res = await _dio.get<List<dynamic>>('/favorites');
    return res.data ?? [];
  }

  Future<void> add(String menuItemId) async {
    await _dio.post('/favorites/$menuItemId');
  }

  Future<void> remove(String menuItemId) async {
    await _dio.delete('/favorites/$menuItemId');
  }
}
