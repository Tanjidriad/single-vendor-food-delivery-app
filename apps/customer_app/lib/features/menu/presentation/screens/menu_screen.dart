import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/commerce/menu_item_card.dart';
import '../../../../core/widgets/shimmers/menu_item_shimmer.dart';
import '../../../../core/widgets/shimmers/shimmer.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../restaurant/data/restaurant_repository.dart';
import '../../widgets/menu_featured_banner.dart';
import '../../widgets/menu_search_field.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: restaurant.when(
        data: (r) {
          return menu.when(
            data: (categories) {
              final filteredCategories = categories
                  .map((cat) {
                    final c = cat as Map<String, dynamic>;
                    final items = c['menuItems'] as List<dynamic>? ?? [];
                    final filteredItems = items.where((raw) {
                      final item = raw as Map<String, dynamic>;
                      final name =
                          (item['name'] as String? ?? '').toLowerCase();
                      final desc =
                          (item['description'] as String? ?? '').toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      return name.contains(query) || desc.contains(query);
                    }).toList();
                    return {...c, 'menuItems': filteredItems};
                  })
                  .where((c) {
                    final items = c['menuItems'] as List<dynamic>;
                    return items.isNotEmpty;
                  })
                  .toList();

              return SafeArea(
                bottom: false,
                child: CustomScrollView(
                  slivers: [
                    // --- Restaurant Info ---
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
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            reviewsSummary.when(
                              data: (summary) {
                                if (summary.count <= 0) {
                                  return const SizedBox.shrink();
                                }
                                final ratingText =
                                    summary.averageRating != null
                                        ? summary.averageRating!
                                            .toStringAsFixed(1)
                                        : '—';
                                return Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 22,
                                        color: Color(0xFFFABD00)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$ratingText (${summary.count}+ ratings)',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Featured Item Banner ---
                    featured.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const SliverToBoxAdapter(
                              child: SizedBox.shrink());
                        }
                        final featuredItem =
                            items.first as Map<String, dynamic>;
                        final featuredName =
                            featuredItem['name'] as String? ?? 'Featured item';
                        final featuredDesc =
                            featuredItem['description'] as String? ?? '';
                        final featuredPrice =
                            (featuredItem['price'] as num?)?.toDouble() ?? 0;
                        final featuredId = featuredItem['id'] as String?;

                        return SliverToBoxAdapter(
                          child: MenuFeaturedBanner(
                            name: featuredName,
                            description: featuredDesc,
                            price: featuredPrice,
                            onAddToBag: featuredId == null
                                ? null
                                : () {
                                    final cartItem = CartItem(
                                      menuItemId: featuredId,
                                      name: featuredName,
                                      unitPrice: featuredPrice,
                                      quantity: 1,
                                      imageUrl:
                                          featuredItem['imageUrl'] as String?,
                                    );
                                    ref
                                        .read(cartProvider.notifier)
                                        .addItem(cartItem);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$featuredName added!'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  },
                          ),
                        );
                      },
                      loading: () =>
                          const SliverToBoxAdapter(child: SizedBox.shrink()),
                      error: (_, _) =>
                          const SliverToBoxAdapter(child: SizedBox.shrink()),
                    ),

                    // --- Search Bar ---
                    SliverToBoxAdapter(
                      child: MenuSearchField(
                        controller: _searchController,
                        query: _searchQuery,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ),

                    // --- Menu Items ---
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
                          delegate: SliverChildBuilderDelegate(
                            (context, catIndex) {
                              final category = filteredCategories[catIndex];
                              final categoryName =
                                  category['name'] as String;
                              final items =
                                  category['menuItems'] as List<dynamic>;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 24, bottom: 8),
                                    child: Text(
                                      categoryName,
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  ...items.map((itemData) {
                                    final item =
                                        itemData as Map<String, dynamic>;
                                    final id = item['id'] as String;
                                    final isFeatured =
                                        item['isFeatured'] as bool? ?? false;

                                    return MenuItemCard(
                                      name: item['name'] as String? ??
                                          'Unnamed Item',
                                      price: (item['price'] as num?)
                                              ?.toDouble() ??
                                          0,
                                      description:
                                          item['description'] as String?,
                                      imageUrl: item['imageUrl'] as String?,
                                      badge: isFeatured ? 'Popular' : null,
                                      onTap: () => context
                                          .push(RoutePaths.itemWithId(id)),
                                      onAddTap: () {
                                        final cartItem = CartItem(
                                          menuItemId: id,
                                          name: item['name'] as String? ??
                                              'Unnamed Item',
                                          unitPrice: (item['price'] as num?)
                                                  ?.toDouble() ??
                                              0,
                                          quantity: 1,
                                          imageUrl:
                                              item['imageUrl'] as String?,
                                        );
                                        ref
                                            .read(cartProvider.notifier)
                                            .addItem(cartItem);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${cartItem.name} added!'),
                                            behavior:
                                                SnackBarBehavior.floating,
                                            backgroundColor: AppColors.primary,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ],
                              );
                            },
                            childCount: filteredCategories.length,
                          ),
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
                child: TShimmerEffect(
                    width: double.infinity, height: 280, radius: 24),
              ),
              const SizedBox(height: 24),
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

