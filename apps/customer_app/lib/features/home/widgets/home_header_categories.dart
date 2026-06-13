import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/media/app_food_image.dart';
import '../../../core/widgets/shimmers/app_category_shimmer.dart';
import 'home_category_grid.dart';

/// Horizontal category row inside the curved home header (CWT-style).
class HomeHeaderCategories extends StatelessWidget {
  const HomeHeaderCategories({
    super.key,
    required this.categories,
    this.isLoading = false,
  });

  final List<dynamic> categories;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Categories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLoading)
          const AppCategoryShimmer(itemCount: 5)
        else if (categories.isEmpty)
          Text(
            'No categories yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.8),
                ),
          )
        else
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) {
                final item = categoryFromApi(categories[i] as Map<String, dynamic>);
                return _HeaderCategoryTile(
                  item: item,
                  onTap: () {
                    if (item.id != null) {
                      context.push(
                        '${RoutePaths.category}/${item.id}?name=${Uri.encodeComponent(item.name)}',
                      );
                    } else {
                      context.go(RoutePaths.menu);
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _HeaderCategoryTile extends StatelessWidget {
  const _HeaderCategoryTile({required this.item, required this.onTap});

  final HomeCategoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: const BoxDecoration(
                color: AppColors.onPrimary,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: AppFoodImage(
                imageUrl: item.imageUrl,
                placeholderSeed: item.placeholderSeed,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
