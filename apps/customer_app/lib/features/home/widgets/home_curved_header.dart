import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive/app_responsive.dart';
import '../../../core/widgets/inputs/app_search_container.dart';
import '../../../core/widgets/shapes/app_primary_header_container.dart';
import '../../../core/widgets/shimmers/app_home_header_shimmer.dart';
import '../../../features/restaurant/data/restaurant_repository.dart';
import 'home_header_categories.dart';
import 'home_top_bar.dart';

/// CWT-style curved primary header: location, search, horizontal categories.
class HomeCurvedHeader extends ConsumerWidget {
  const HomeCurvedHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurant = ref.watch(restaurantProvider);
    final menu = ref.watch(menuProvider);
    final pagePadding = AppResponsive.pagePadding(context);
    final topInset = MediaQuery.paddingOf(context).top;

    final locationLabel =
        restaurant.valueOrNull?['addressLine'] as String? ??
        restaurant.valueOrNull?['name'] as String? ??
        'Add delivery address';

    return AppPrimaryHeaderContainer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          pagePadding,
          topInset + 8,
          pagePadding,
          AppSpacing.xl,
        ),
        child: restaurant.when(
          data: (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeTopBar(
                locationLabel: locationLabel,
                variant: HomeTopBarVariant.onPrimary,
                onLocationTap: () => context.push(RoutePaths.addresses),
                onNotificationsTap: () => context.push(RoutePaths.notifications),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppSearchContainer(
                hint: 'Search in Store',
                showBorder: false,
                onTap: () => context.push(RoutePaths.search),
              ),
              const SizedBox(height: AppSpacing.xl),
              menu.when(
                data: (categories) =>
                    HomeHeaderCategories(categories: categories),
                loading: () =>
                    const HomeHeaderCategories(categories: [], isLoading: true),
                error: (_, _) => const HomeHeaderCategories(categories: []),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
          loading: () => const AppHomeHeaderShimmer(onPrimary: true),
          error: (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeTopBar(
                locationLabel: locationLabel,
                variant: HomeTopBarVariant.onPrimary,
                onLocationTap: () => context.push(RoutePaths.addresses),
                onNotificationsTap: () => context.push(RoutePaths.notifications),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSearchContainer(
                hint: 'Search in Store',
                showBorder: false,
                onTap: () => context.push(RoutePaths.search),
              ),
              const SizedBox(height: AppSpacing.lg),
              menu.when(
                data: (categories) =>
                    HomeHeaderCategories(categories: categories),
                loading: () =>
                    const HomeHeaderCategories(categories: [], isLoading: true),
                error: (_, _) => const HomeHeaderCategories(categories: []),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
