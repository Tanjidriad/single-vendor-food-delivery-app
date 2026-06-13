import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/commerce/premium_menu_item_card.dart';
import '../../../restaurant/data/restaurant_repository.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.categoryId, required this.categoryName});

  final String categoryId;
  final String categoryName;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = ref.read(restaurantIdProvider);
    if (id == null) return;
    final data = await ref.read(restaurantRepositoryProvider).filterMenu(
          id,
          categoryId: widget.categoryId,
        );
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final item = _items[i] as Map<String, dynamic>;
                final itemId = item['id'] as String;
                final cardData = premiumMenuItemCardDataFromJson(
                  item,
                  categoryName: widget.categoryName,
                );
                return PremiumMenuItemCard(
                  data: cardData,
                  onTap: () => context.push(RoutePaths.itemWithId(itemId)),
                  onCustomize: () => context.push(RoutePaths.itemWithId(itemId)),
                );
              },
            ),
    );
  }
}
