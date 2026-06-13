import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/favorites_repository.dart';

final favoritesListProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(favoritesRepositoryProvider).list();
});

final favoriteMenuItemIdsProvider =
    AsyncNotifierProvider<FavoriteMenuItemIdsNotifier, Set<String>>(
  FavoriteMenuItemIdsNotifier.new,
);

class FavoriteMenuItemIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final list = await ref.watch(favoritesRepositoryProvider).list();
    return _idsFromList(list);
  }

  Set<String> _idsFromList(List<dynamic> list) {
    final ids = <String>{};
    for (final raw in list) {
      final fav = raw as Map<String, dynamic>;
      final item = fav['menuItem'] as Map<String, dynamic>? ?? fav;
      final id = item['id'] as String? ?? fav['menuItemId'] as String?;
      if (id != null) ids.add(id);
    }
    return ids;
  }

  Future<void> toggle(String menuItemId) async {
    final repo = ref.read(favoritesRepositoryProvider);
    final current = state.valueOrNull ?? await future;

    if (current.contains(menuItemId)) {
      await repo.remove(menuItemId);
      state = AsyncData({...current}..remove(menuItemId));
    } else {
      await repo.add(menuItemId);
      state = AsyncData({...current, menuItemId});
    }
    ref.invalidate(favoritesListProvider);
  }
}
