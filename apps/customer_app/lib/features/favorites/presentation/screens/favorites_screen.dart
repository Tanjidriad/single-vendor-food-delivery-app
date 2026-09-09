import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/commerce/menu_item_card.dart';
import '../../../../core/widgets/cwt/empty_state_widget.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.when(
        data: (list) {
          if (list.isEmpty) {
            return const AppEmptyStateWidget(
              title: 'No favorites yet',
              subtitle: 'Save dishes you love for quick reorder',
              animation: 'assets/images/72785-searching.json',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final fav = list[i] as Map<String, dynamic>;
              final item = fav['menuItem'] as Map<String, dynamic>? ?? fav;
              return MenuItemCard(
                name: item['name'] as String? ?? '',
                price: (item['price'] as num?)?.toDouble() ?? 0,
                imageUrl: item['imageUrl'] as String?,
                onTap: () => context.push(RoutePaths.itemWithId(item['id'] as String)),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
