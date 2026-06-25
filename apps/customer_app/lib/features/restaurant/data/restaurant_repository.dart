import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/map_dio_exception.dart';
import '../../../core/network/api_client.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(ref.watch(apiClientProvider));
});

class RestaurantRepository {
  RestaurantRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getBySlug([String slug = AppConfig.restaurantSlug]) {
    return _getMap('/restaurant/slug/$slug', emptyError: 'Restaurant not found.');
  }

  Future<Map<String, dynamic>> getById(String id) {
    return _getMap('/restaurant/$id', emptyError: 'Restaurant not found.');
  }

  Future<List<dynamic>> getMenu(String restaurantId) {
    return _getList('/menu/restaurant/$restaurantId');
  }

  Future<List<dynamic>> getFeatured(String restaurantId) {
    return _getList('/menu/restaurant/$restaurantId/featured');
  }

  Future<List<dynamic>> getBanners(String restaurantId) {
    return _getList('/menu/restaurant/$restaurantId/banners');
  }

  Future<List<dynamic>> getRestaurantReviews(String restaurantId) {
    return _getList('/reviews/restaurant/$restaurantId');
  }

  Future<List<dynamic>> searchMenu(String restaurantId, String q) {
    return _getList(
      '/menu/restaurant/$restaurantId/search',
      query: {'q': q},
    );
  }

  Future<List<dynamic>> filterMenu(
    String restaurantId, {
    String? categoryId,
    String? q,
  }) {
    return _getList(
      '/menu/restaurant/$restaurantId/filter',
      query: {
        'categoryId': ?categoryId,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
  }

  Future<Map<String, dynamic>> getItem(String itemId) {
    return _getMap('/menu/items/$itemId', emptyError: 'Menu item not found.');
  }

  /// GET a JSON object, null-safe + [DioException] → [Failure].
  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, dynamic>? query,
    String emptyError = 'Something went wrong. Please try again.',
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      final body = res.data;
      if (body == null) throw ServerFailure(emptyError);
      return body;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// GET a JSON array, tolerating an empty body, + [DioException] → [Failure].
  Future<List<dynamic>> _getList(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get<List<dynamic>>(path, queryParameters: query);
      return res.data ?? [];
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final restaurantProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(restaurantRepositoryProvider).getBySlug();
});

final restaurantIdProvider = Provider<String?>((ref) {
  return ref.watch(restaurantProvider).valueOrNull?['id'] as String?;
});

final menuProvider = FutureProvider<List<dynamic>>((ref) async {
  final id = ref.watch(restaurantIdProvider);
  if (id == null) return [];
  return ref.watch(restaurantRepositoryProvider).getMenu(id);
});

final featuredMenuProvider = FutureProvider<List<dynamic>>((ref) async {
  final id = ref.watch(restaurantIdProvider);
  if (id == null) return [];
  return ref.watch(restaurantRepositoryProvider).getFeatured(id);
});

final bannersProvider = FutureProvider<List<dynamic>>((ref) async {
  final id = ref.watch(restaurantIdProvider);
  if (id == null) return [];
  return ref.watch(restaurantRepositoryProvider).getBanners(id);
});

class RestaurantReviewsSummary {
  const RestaurantReviewsSummary({this.averageRating, required this.count});

  final double? averageRating;
  final int count;
}

final restaurantReviewsSummaryProvider =
    FutureProvider<RestaurantReviewsSummary>((ref) async {
  final id = ref.watch(restaurantIdProvider);
  if (id == null) return const RestaurantReviewsSummary(count: 0);

  final reviews =
      await ref.watch(restaurantRepositoryProvider).getRestaurantReviews(id);
  if (reviews.isEmpty) return const RestaurantReviewsSummary(count: 0);

  var sum = 0.0;
  var count = 0;
  for (final raw in reviews) {
    final rating = (raw as Map<String, dynamic>)['rating'] as num?;
    if (rating == null || rating <= 0) continue;
    sum += rating.toDouble();
    count++;
  }

  if (count == 0) return const RestaurantReviewsSummary(count: 0);
  return RestaurantReviewsSummary(
    averageRating: sum / count,
    count: count,
  );
});
