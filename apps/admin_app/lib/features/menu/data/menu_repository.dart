import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return MenuRepository(dio);
});

final menuItemsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(menuRepositoryProvider);
  return repository.fetchMenuItems();
});

final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(menuRepositoryProvider);
  return repository.fetchCategories();
});

final addonsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(menuRepositoryProvider);
  return repository.fetchAddons();
});

class MenuRepository {
  final Dio _dio;
  MenuRepository(this._dio);

  /// Fetches menu from GET /menu/restaurant/:restaurantId
  /// The public menu endpoint returns categories with nested menuItems.
  /// We flatten that into a list of items for the data table.
  Future<List<Map<String, dynamic>>> fetchMenuItems() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminMenu);
      final data = response.data;
      // Backend returns a list of categories, each with menuItems nested
      final List<Map<String, dynamic>> items = [];
      if (data is List) {
        for (final category in data) {
          final categoryName = category['name'] ?? '';
          final categoryId = category['id'] ?? '';
          final menuItems = category['menuItems'] as List? ?? [];
          for (final item in menuItems) {
            items.add({
              'id': item['id'],
              'name': item['name'],
              'description': item['description'],
              'category': categoryName,
              'categoryId': categoryId,
              'price': item['price'],
              'compareAtPrice': item['compareAtPrice'],
              'tags': item['tags'],
              'isAvailable': item['isAvailable'] ?? true,
              'isFeatured': item['isFeatured'] ?? false,
              'imageUrl': item['imageUrl'],
              'addons': item['addons'], // preserve linked addons for pre-selection in editor
            });
          }
        }
      }
      return items;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.type == DioExceptionType.connectionError) {
        return [];
      }
      throw Exception('Failed to fetch menu items: ${e.message}');
    }
  }

  /// Fetches categories from the public menu endpoint
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminMenu);
      final data = response.data;
      final List<Map<String, dynamic>> categories = [];
      if (data is List) {
        for (final category in data) {
          categories.add({
            'id': category['id'],
            'name': category['name'],
          });
        }
      }
      return categories;
    } on DioException {
      return [];
    }
  }

  /// POST /admin/menu/items
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> data) async {
    final response = await _dio.post(
      ApiEndpoints.adminMenuItems,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /admin/menu/items/:id
  Future<Map<String, dynamic>> updateItem(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch(
      '${ApiEndpoints.adminMenuItems}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /admin/menu/items/:id
  Future<void> deleteItem(String id) async {
    await _dio.delete('${ApiEndpoints.adminMenuItems}/$id');
  }

  /// Fetches addons from GET /admin/menu/addons
  Future<List<Map<String, dynamic>>> fetchAddons() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminMenuAddons);
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException {
      return [];
    }
  }

  /// POST /admin/menu/addons
  Future<Map<String, dynamic>> createAddon(Map<String, dynamic> data) async {
    final response = await _dio.post(
      ApiEndpoints.adminMenuAddons,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /admin/menu/addons/:id
  Future<Map<String, dynamic>> updateAddon(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch(
      '${ApiEndpoints.adminMenuAddons}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /admin/menu/addons/:id
  Future<void> deleteAddon(String id) async {
    await _dio.delete('${ApiEndpoints.adminMenuAddons}/$id');
  }

  /// POST /admin/menu/items/:itemId/addons/:addonId
  Future<void> linkAddon(String itemId, String addonId) async {
    await _dio.post('${ApiEndpoints.adminMenuItems}/$itemId/addons/$addonId');
  }

  /// DELETE /admin/menu/items/:itemId/addons/:addonId
  Future<void> unlinkAddon(String itemId, String addonId) async {
    await _dio.delete('${ApiEndpoints.adminMenuItems}/$itemId/addons/$addonId');
  }
}
