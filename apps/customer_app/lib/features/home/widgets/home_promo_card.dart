import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/commerce/app_favorite_button.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters/formatter.dart';
import '../../../core/utils/responsive/app_responsive.dart';
import '../../../core/widgets/media/app_food_image.dart';

/// Horizontal “Discount Guaranteed” card.
class HomePromoCard extends ConsumerWidget {
  const HomePromoCard({
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
    final cardWidth = AppResponsive.homePromoCardWidth(context);

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusMd),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.15,
                      child: AppFoodImage(
                        imageUrl: imageUrl,
                        placeholderSeed: itemId ?? name,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PROMO',
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (itemId != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: AppFavoriteButton(menuItemId: itemId!, size: 32),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 14),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      AppFormatter.formatCurrency(price),
                      style: AppTypography.price(
                        size: 15,
                      ).copyWith(color: AppColors.primary),
                    ),
                    if (deliveryLabel != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            AppIcons.bike,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              deliveryLabel!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
