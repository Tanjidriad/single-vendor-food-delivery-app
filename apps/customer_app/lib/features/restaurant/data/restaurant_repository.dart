import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(ref.watch(apiClientProvider));
});

class RestaurantRepository {
  RestaurantRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getBySlug([String slug = AppConfig.restaurantSlug]) async {
    final res = await _dio.get<Map<String, dynamic>>('/restaurant/slug/$slug');
    return res.data!;
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/restaurant/$id');
    return res.data!;
  }

  Future<List<dynamic>> getMenu(String restaurantId) async {
    final res = await _dio.get<List<dynamic>>('/menu/restaurant/$restaurantId');
    return res.data ?? [];
  }

  Future<List<dynamic>> getFeatured(String restaurantId) async {
    final res = await _dio.get<List<dynamic>>('/menu/restaurant/$restaurantId/featured');
    return res.data ?? [];
  }

  Future<List<dynamic>> getBanners(String restaurantId) async {
    final res = await _dio.get<List<dynamic>>('/menu/restaurant/$restaurantId/banners');
    return res.data ?? [];
  }

  Future<List<dynamic>> getRestaurantReviews(String restaurantId) async {
    final res = await _dio.get<List<dynamic>>('/reviews/restaurant/$restaurantId');
    return res.data ?? [];
  }

  Future<List<dynamic>> searchMenu(String restaurantId, String q) async {
    final res = await _dio.get<List<dynamic>>(
      '/menu/restaurant/$restaurantId/search',
      queryParameters: {'q': q},
    );
    return res.data ?? [];
  }

  Future<List<dynamic>> filterMenu(
    String restaurantId, {
    String? categoryId,
    String? q,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/menu/restaurant/$restaurantId/filter',
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    return res.data ?? [];
  }

  Future<Map<String, dynamic>> getItem(String itemId) async {
    final res = await _dio.get<Map<String, dynamic>>('/menu/items/$itemId');
    return res.data!;
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
