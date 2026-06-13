import 'package:customer_app/features/offers/presentation/widgets/promo_carousel.dart';
import 'package:customer_app/features/offers/presentation/widgets/promo_ticket_card.dart';
import 'package:customer_app/features/restaurant/data/restaurant_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers/helper_functions.dart';
import '../../../../core/widgets/cwt/empty_state_widget.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/shimmers/shimmer.dart';
import '../../../../core/widgets/shimmers/menu_item_shimmer.dart';
import '../providers/offers_providers.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(bannersProvider);
    final coupons = ref.watch(publicCouponsProvider);
    final isDark = AppHelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      body: banners.when(
        data: (bannerList) => coupons.when(
          data: (couponList) {
            if (couponList.isEmpty && bannerList.isEmpty) {
              return const AppEmptyStateWidget(
                title: 'No offers right now',
                subtitle: 'Check back later for exciting deals',
                animation: 'assets/images/72785-searching.json',
              );
            }

            return CustomScrollView(
              slivers: [
                if (bannerList.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 12),
                      child: PromoCarousel(banners: bannerList),
                    ),
                  ),

                if (couponList.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final c = couponList[index] as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: PromoTicketCard(coupon: c, isDark: isDark),
                        );
                      }, childCount: couponList.length),
                    ),
                  ),

                // Extra padding at bottom
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
          loading: () => _buildShimmer(),
          error: (e, _) => AppErrorState(
            message: friendlyErrorMessage(e),
            onRetry: () => ref.invalidate(publicCouponsProvider),
          ),
        ),
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: friendlyErrorMessage(e),
          onRetry: () => ref.invalidate(bannersProvider),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const TShimmerEffect(width: double.infinity, height: 160, radius: 16),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TMenuItemShimmer(itemCount: 4),
          ),
        ],
      ),
    );
  }
}
