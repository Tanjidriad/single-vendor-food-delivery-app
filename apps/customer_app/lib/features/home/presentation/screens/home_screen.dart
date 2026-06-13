import 'package:customer_app/features/home/presentation/widgets/floating_active_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../../../../core/utils/responsive/app_responsive.dart';
import '../../../../core/widgets/commerce/restaurant_card.dart';
import '../../../../core/widgets/shimmers/app_home_offer_card_shimmer.dart';
import '../../../../core/widgets/shimmers/app_promo_banner_shimmer.dart';
import '../../../restaurant/data/restaurant_repository.dart';
import '../../widgets/home_curved_header.dart';
import '../../widgets/home_filter_chip.dart';
import '../../widgets/home_offer_card.dart';
import '../../widgets/home_promo_banner_carousel.dart';
import '../../widgets/section_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategoryId;

  List<Map<String, dynamic>> _filteredMenuItems(List<dynamic> categories) {
    final items = <Map<String, dynamic>>[];
    for (final cat in categories) {
      final c = cat as Map<String, dynamic>;
      if (_selectedCategoryId != null && c['id'] != _selectedCategoryId)
        continue;
      final categoryName = c['name'] as String? ?? '';
      final menuItems = c['menuItems'] as List<dynamic>? ?? [];
      for (final m in menuItems) {
        final raw = m as Map<String, dynamic>;
        items.add({
          ...raw,
          'category': {'name': categoryName},
        });
      }
    }
    return items;
  }

  String? _emojiForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('burger')) return '🍔';
    if (n.contains('pizza')) return '🍕';
    if (n.contains('noodle')) return '🍜';
    return null;
  }

  HomeOfferCard _offerCard(
    BuildContext context, {
    required Map<String, dynamic> item,
    required String deliveryMeta,
    double? width,
    bool elevated = false,
  }) {
    final id = item['id'] as String?;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final salePrice = homeOfferSalePrice(item);
    final displayPrice = salePrice != null && salePrice > 0 ? salePrice : price;
    final priceLabel = AppFormatter.formatCurrency(displayPrice);

    return HomeOfferCard(
      title: item['name'] as String? ?? '',
      imageUrl: item['imageUrl'] as String?,
      itemId: id,
      deliveryMeta: priceLabel,
      rating: homeOfferRating(item),
      promoBadge: homeOfferPromoBadge(item, salePrice, price),
      width: width,
      elevated: elevated,
      onTap: id != null ? () => context.push(RoutePaths.itemWithId(id)) : null,
    );
  }

  RestaurantCard _recommendedDiscoveryCard(
    BuildContext context, {
    required Map<String, dynamic> item,
    required String deliveryMeta,
  }) {
    final id = item['id'] as String?;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final salePrice = homeOfferSalePrice(item);
    final category = item['category'] as Map<String, dynamic>?;
    final cuisines = <String>[];
    if (category != null && category['name'] != null) {
      cuisines.add(category['name'] as String);
    }
    final description = item['description'] as String?;
    if (description != null && description.isNotEmpty) {
      cuisines.add(description);
    }

    String? promoBadge;
    if (salePrice != null && salePrice > 0 && salePrice < price) {
      promoBadge = '${((price - salePrice) / price * 100).round()}% OFF';
    }

    return RestaurantCard(
      data: RestaurantCardData(
        id: id ?? '',
        name: item['name'] as String? ?? '',
        imageUrl: item['imageUrl'] as String?,
        cuisines: cuisines,
        rating: homeOfferRating(item),
        deliveryFee: deliveryMeta.contains('Free')
            ? 'Free'
            : deliveryMeta.split('•').first.trim(),
        promoBadge: promoBadge,
      ),
      onTap: id != null ? () => context.push(RoutePaths.itemWithId(id)) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final restaurant = ref.watch(restaurantProvider);
    final menu = ref.watch(menuProvider);
    final featured = ref.watch(featuredMenuProvider);
    final banners = ref.watch(bannersProvider);

    final fee = restaurant.valueOrNull?['deliveryFee'] as num?;
    final deliveryFeeLabel = fee != null && fee > 0
        ? 'Delivery ${AppFormatter.formatCurrency(fee.toDouble())}'
        : 'Free delivery';
    final deliveryMeta = homeOfferDeliveryMeta(deliveryFeeLabel);

    final pagePadding = AppResponsive.pagePadding(context);
    final carouselCardWidth = AppResponsive.homeOfferCarouselCardWidth(context);
    final carouselHeight = AppResponsive.homeOfferCarouselHeight(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          RefreshIndicator(
            color: scheme.primary,
            onRefresh: () async {
              ref.invalidate(restaurantProvider);
              ref.invalidate(menuProvider);
              ref.invalidate(featuredMenuProvider);
              ref.invalidate(bannersProvider);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
          slivers: [
            // --- CURVED HEADER ---
            const SliverToBoxAdapter(child: HomeCurvedHeader()),

            // --- SPECIAL OFFERS ---
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Special Offers',
                    topPadding: 24,
                    onAction: () => context.go(RoutePaths.offers),
                  ),
                  banners.when(
                    data: (list) => HomePromoBannerCarousel(
                      banners: list.cast<Map<String, dynamic>>(),
                      onBannerTap: (_) => context.go(RoutePaths.offers),
                      onDefaultTap: () => context.go(RoutePaths.offers),
                    ),
                    loading: () => const AppPromoBannerShimmer(),
                    error: (_, _) => HomePromoBannerCarousel(
                      banners: const [],
                      onDefaultTap: () => context.go(RoutePaths.offers),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // --- TODAY'S OFFERS CAROUSEL ---
            SliverToBoxAdapter(
              child: featured.when(
                data: (items) {
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: "Today's offers",
                        onAction: () => context.go(RoutePaths.menu),
                      ),
                      SizedBox(
                        height: carouselHeight,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: pagePadding,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (_, i) => _offerCard(
                            context,
                            item: items[i] as Map<String, dynamic>,
                            deliveryMeta: deliveryMeta,
                            width: carouselCardWidth,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
                loading: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: "Today's offers"),
                    AppHomeOfferCarouselShimmer(cardWidth: carouselCardWidth),
                  ],
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

            // --- RECOMMENDED HEADER + FILTER CHIPS ---
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Recommended for you',
                    onAction: () => context.go(RoutePaths.menu),
                  ),
                  menu.when(
                    data: (categories) {
                      final chips = <Map<String, dynamic>>[
                        {'id': null, 'name': 'All'},
                        ...categories.map((c) => c as Map<String, dynamic>),
                      ];
                      return SizedBox(
                        height: 44,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: pagePadding,
                          ),
                          itemCount: chips.length,
                          itemBuilder: (_, i) {
                            final id = chips[i]['id'] as String?;
                            final name = chips[i]['name'] as String? ?? 'All';
                            return HomeFilterChip(
                              label: name,
                              selected: _selectedCategoryId == id,
                              leadingEmoji: id == null
                                  ? null
                                  : _emojiForCategory(name),
                              onTap: () =>
                                  setState(() => _selectedCategoryId = id),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 44),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // --- RECOMMENDED DISH LIST ---
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pagePadding, 8, pagePadding, 120),
              sliver: menu.when(
                data: (categories) {
                  final items = _filteredMenuItems(categories);
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No dishes available',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _recommendedDiscoveryCard(
                          context,
                          item: items[i],
                          deliveryMeta: deliveryMeta,
                        ),
                      ),
                      childCount: items.length,
                    ),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: AppHomeOfferListShimmer()),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error: $e',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: scheme.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const FloatingActiveOrderCard(),
    ],
  ),
    );
  }
}
