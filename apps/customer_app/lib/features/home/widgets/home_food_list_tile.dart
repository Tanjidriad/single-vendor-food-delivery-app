import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters/formatter.dart';
import '../../../core/utils/responsive/app_responsive.dart';
import '../../../core/widgets/commerce/app_favorite_button.dart';
import '../../../core/widgets/media/app_food_image.dart';

/// “Recommended For You” row — image left, details right.
class HomeFoodListTile extends ConsumerWidget {
  const HomeFoodListTile({
    super.key,
    required this.name,
    required this.price,
    this.imageUrl,
    this.itemId,
    this.meta,
    this.deliveryLabel,
    this.onTap,
  });

  final String name;
  final double price;
  final String? imageUrl;
  final String? itemId;
  final String? meta;
  final String? deliveryLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageSize = AppResponsive.value(context, mobile: 88.0, tablet: 96.0, desktop: 104.0);

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppFoodImage(
                imageUrl: imageUrl,
                placeholderSeed: itemId ?? name,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      AppFormatter.formatCurrency(price),
                      style: AppTypography.price(size: 15).copyWith(color: AppColors.primary),
                    ),
                    if (deliveryLabel != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(AppIcons.bike, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            deliveryLabel!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (itemId != null) AppFavoriteButton(menuItemId: itemId!),
            ],
          ),
        ),
      ),
    );
  }
}
