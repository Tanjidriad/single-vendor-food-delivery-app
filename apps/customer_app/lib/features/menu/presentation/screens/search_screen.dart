import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/commerce/premium_menu_item_card.dart';
import '../../../../core/widgets/feedback/empty_state.dart';
import '../../../../core/widgets/inputs/app_search_bar.dart';
import '../../../restaurant/data/restaurant_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;

  Future<void> _search(String q) async {
    final id = ref.read(restaurantIdProvider);
    if (id == null || q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ref.read(restaurantRepositoryProvider).searchMenu(id, q);
      setState(() => _results = data);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              style: AppSearchBarStyle.uberGrayPill,
              controller: _controller,
              readOnly: false,
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const AppEmptyState(
                        title: 'No dishes found',
                        subtitle: 'Try a different search term',
                        assetPath: 'assets/illustrations/empty_cart.svg',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (_, i) {
                          final item = _results[i] as Map<String, dynamic>;
                          final itemId = item['id'] as String;
                          final cardData = premiumMenuItemCardDataFromJson(item);
                          return PremiumMenuItemCard(
                            data: cardData,
                            onTap: () => context.push(RoutePaths.itemWithId(itemId)),
                            onCustomize: () => context.push(RoutePaths.itemWithId(itemId)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
