import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class MenuNotifier extends AsyncNotifier<List<dynamic>> {
  late final ApiClient _apiClient;
  final _logger = Logger();

  @override
  Future<List<dynamic>> build() async {
    _apiClient = ref.watch(apiClientProvider);
    return _fetchMenu();
  }

  Future<List<dynamic>> _fetchMenu() async {
    try {
      _logger.i('--- START FETCHING MENU ---');
      final response = await _apiClient.get(ApiEndpoints.menuItems);
      _logger.d('Response Data: ${response.data}');
      
      // If response.data has a different shape (e.g. { data: [...] }), it will fail here:
      final categories = response.data as List<dynamic>;
      final List<dynamic> allItems = [];
      for (var category in categories) {
        if (category['menuItems'] != null) {
          // Add category name to each item for display purposes
          final items = category['menuItems'] as List<dynamic>;
          for (var item in items) {
            item['category'] = {'name': category['name']};
            allItems.add(item);
          }
        }
      }
      _logger.i('Parsed ${allItems.length} menu items.');
      return allItems;
    } catch (e, st) {
      _logger.e('!!! ERROR FETCHING MENU !!!', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> fetchMenu() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMenu());
  }

  Future<void> toggleItemAvailability(String itemId, bool isAvailable) async {
    final previousState = state;
    
    // Optimistic update
    if (state.hasValue) {
      final currentItems = List<dynamic>.from(state.value!);
      final index = currentItems.indexWhere((item) => item['id'] == itemId);
      if (index != -1) {
        currentItems[index] = {...currentItems[index], 'isAvailable': isAvailable};
        state = AsyncValue.data(currentItems);
      }
    }
    
    try {
      await _apiClient.patch(
        ApiEndpoints.updateMenuItem(itemId),
        data: {'isAvailable': isAvailable},
      );
    } catch (e) {
      // Revert on failure
      state = previousState;
    }
  }
}

final menuProvider = AsyncNotifierProvider<MenuNotifier, List<dynamic>>(() {
  return MenuNotifier();
});
