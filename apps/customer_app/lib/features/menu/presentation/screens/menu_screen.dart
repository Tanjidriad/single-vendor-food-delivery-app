import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../../../../core/widgets/commerce/menu_item_card.dart';
import '../../../../core/widgets/shimmers/category_shimmer.dart';
import '../../../../core/widgets/shimmers/menu_item_shimmer.dart';
import '../../../../core/widgets/shimmers/shimmer.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../restaurant/data/restaurant_repository.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = ref.watch(restaurantProvider);
    final menu = ref.watch(menuProvider);
    final featured = ref.watch(featuredMenuProvider);
    final reviewsSummary = ref.watch(restaurantReviewsSummaryProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: restaurant.when(
        data: (r) {
          // --- Main Scrollable Content ---
          return menu.when(
            data: (categories) {
              // Filter categories and items based on search and selected category tab
              final filteredCategories = categories
                  .map((cat) {
                    final c = cat as Map<String, dynamic>;
                    final items = c['menuItems'] as List<dynamic>? ?? [];
                    final filteredItems = items.where((raw) {
                      final item = raw as Map<String, dynamic>;
                      final name = (item['name'] as String? ?? '')
                          .toLowerCase();
                      final desc = (item['description'] as String? ?? '')
                          .toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      return name.contains(query) || desc.contains(query);
                    }).toList();

                    return {...c, 'menuItems': filteredItems};
                  })
                  .where((c) {
                    // Filter by category tab if selected
                    if (_selectedCategoryId != null &&
                        c['id'] != _selectedCategoryId) {
                      return false;
                    }
                    // Only show categories that have items matching the search query
                    final items = c['menuItems'] as List<dynamic>;
                    return items.isNotEmpty;
                  })
                  .toList();

              return SafeArea(
                bottom: false,
                child: CustomScrollView(
                  slivers: [
                    // --- Premium Parallax Hero Image Banner ---
                    // --- Restaurant Info Row ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['name'] as String? ?? 'Restaurant',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            reviewsSummary.when(
                              data: (summary) {
                                if (summary.count <= 0) {
                                  return const SizedBox.shrink();
                                }
                                final ratingText = summary.averageRating != null
                                    ? summary.averageRating!.toStringAsFixed(1)
                                    : '—';
                                return Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 22,
                                      color: Color(0xFFFABD00),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$ratingText (${summary.count}+ ratings)',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Hero / Featured Item ---
                    featured.when(
                      data: (items) {
                        if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                        final featuredItem = items.first as Map<String, dynamic>;
                        final featuredName = featuredItem['name'] as String? ?? 'Featured item';
                        final featuredDesc = featuredItem['description'] as String? ?? '';
                        final featuredPrice = (featuredItem['price'] as num?)?.toDouble() ?? 0;
                        final featuredId = featuredItem['id'] as String?;

                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.brutalistRed,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Transform.rotate(
                                    angle: -0.05,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.brutalistYellow,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.campaign,
                                            size: 20,
                                            color: Colors.black,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'FEATURED',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    featuredName,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                  if (featuredDesc.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      featuredDesc,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppFormatter.formatCurrency(featuredPrice),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFFABD00),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: featuredId == null
                                            ? null
                                            : () {
                                                final cartItem = CartItem(
                                                  menuItemId: featuredId,
                                                  name: featuredName,
                                                  unitPrice: featuredPrice,
                                                  quantity: 1,
                                                  imageUrl: featuredItem['imageUrl'] as String?,
                                                );
                                                ref.read(cartProvider.notifier).addItem(cartItem);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('$featuredName added to bag!'),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.brutalistYellow,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black,
                                                offset: Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'ADD TO BAG',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    ),

                    // --- Search Bar Inside Store ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search dishes in store...',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- Category Tabs Horizontal Row ---
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverCategoryTabsDelegate(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 16,
                          ),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final category =
                                  categories[index] as Map<String, dynamic>;
                              final id = category['id'] as String;
                              final isSelected = _selectedCategoryId == id;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId = isSelected
                                        ? null
                                        : id;
                                  });
                                },
                                child: Transform.rotate(
                                  angle: isSelected ? -0.02 : 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.brutalistRed
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        (category['name'] as String)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // --- Menu Items List ---
                    if (filteredCategories.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No items found matching your search.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            catIndex,
                          ) {
                            final category = filteredCategories[catIndex];
                            final categoryName = category['name'] as String;
                            final items =
                                category['menuItems'] as List<dynamic>;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 32.0,
                                    bottom: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Transform(
                                        transform: Matrix4.skewX(-0.15),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.brutalistRed,
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          child: Transform(
                                            transform: Matrix4.skewX(0.15),
                                            child: Text(
                                              categoryName.toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                                color: Colors.white,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            left: 16,
                                          ),
                                          height: 2,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...items.map((itemData) {
                                  final item = itemData as Map<String, dynamic>;
                                  final id = item['id'] as String;
                                  final isFeatured =
                                      item['isFeatured'] as bool? ?? false;

                                  return MenuItemCard(
                                    name:
                                        item['name'] as String? ??
                                        'Unnamed Item',
                                    price:
                                        (item['price'] as num?)?.toDouble() ??
                                        0,
                                    description: item['description'] as String?,
                                    imageUrl: item['imageUrl'] as String?,
                                    badge: isFeatured ? 'Popular' : null,
                                    onTap: () =>
                                        context.push(RoutePaths.itemWithId(id)),
                                    onAddTap: () {
                                      final cartItem = CartItem(
                                        menuItemId: id,
                                        name:
                                            item['name'] as String? ??
                                            'Unnamed Item',
                                        unitPrice:
                                            (item['price'] as num?)
                                                ?.toDouble() ??
                                            0,
                                        quantity: 1,
                                        imageUrl: item['imageUrl'] as String?,
                                      );
                                      ref
                                          .read(cartProvider.notifier)
                                          .addItem(cartItem);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${cartItem.name} added to bag!',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ],
                            );
                          }, childCount: filteredCategories.length),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: TMenuItemShimmer(itemCount: 6),
            ),
            error: (e, _) => Center(child: Text('$e')),
          );
        },
        loading: () => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TShimmerEffect(width: 200, height: 32),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TShimmerEffect(width: 150, height: 16),
              ),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TShimmerEffect(width: double.infinity, height: 280, radius: 24),
              ),
              const SizedBox(height: 24),
              const TCategoryShimmer(),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TMenuItemShimmer(itemCount: 3),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

// --- Delegate helper for Category sticky header tab bar ---
class _SliverCategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  _SliverCategoryTabsDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 50;

  @override
  double get maxExtent => 50;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverCategoryTabsDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
