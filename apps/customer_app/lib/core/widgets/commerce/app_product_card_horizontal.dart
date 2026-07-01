import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../media/app_food_image.dart';
import '../texts/app_product_price_text.dart';
import '../texts/app_product_title_text.dart';
import 'app_favorite_button.dart';
import 'widgets/app_product_card_add_button.dart';
import 'widgets/app_product_sale_tag.dart';

/// CWT [TProductCardHorizontal] adapted for menu items.
///
/// Soft light surface (no hard white box), image left, details right, with the
/// signature corner-seated add-to-cart button. Layout is fully flex-based so a
/// long title or price ellipsises instead of overflowing.
class AppProductCardHorizontal extends StatelessWidget {
  const AppProductCardHorizontal({
    super.key,
    required this.menuItemId,
    required this.title,
    required this.price,
    this.imageUrl,
    this.salePrice,
    this.subtitle,
    this.showVerifiedBadge = true,
    this.onTap,
    this.onAddToCart,
    this.width = 310,
  });

  final String menuItemId;
  final String title;
  final double price;
  final double? salePrice;
  final String? imageUrl;
  final String? subtitle;
  final bool showVerifiedBadge;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final double width;

  static const double _thumbSize = 120;

  String? get _saleLabel {
    if (salePrice == null || salePrice! <= 0 || salePrice! >= price) {
      return null;
    }
    final pct = ((price - salePrice!) / price * 100).round();
    return '-$pct%';
  }

  double get _displayPrice =>
      (salePrice != null && salePrice! > 0) ? salePrice! : price;

  @override
  Widget build(BuildContext context) {
    final saleLabel = _saleLabel;
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.black400 : AppColors.gray300;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- THUMBNAIL ---
            SizedBox(
              height: _thumbSize,
              width: _thumbSize,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AppFoodImage(
                        imageUrl: imageUrl,
                        placeholderSeed: menuItemId,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                    if (saleLabel != null) AppProductSaleTag(label: saleLabel),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: AppFavoriteButton(
                        menuItemId: menuItemId,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- DETAILS ---
            Expanded(
              child: SizedBox(
                height: _thumbSize,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    top: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AppProductTitleText(
                          title: title,
                          compact: true,
                          maxLines: 2,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _SubtitleLine(
                          text: subtitle!,
                          showVerified: showVerifiedBadge,
                        ),
                      ],
                      const Spacer(),

                      // --- PRICE + ADD ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (saleLabel != null)
                                  AppProductPriceText(
                                    price: price,
                                    lineThrough: true,
                                  ),
                                AppProductPriceText(price: _displayPrice),
                              ],
                            ),
                          ),
                          AppProductCardAddButton(
                            menuItemId: menuItemId,
                            name: title,
                            unitPrice: _displayPrice,
                            imageUrl: imageUrl,
                            onNavigateToDetail: onAddToCart,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand / category line with the CWT verified badge.
class _SubtitleLine extends StatelessWidget {
  const _SubtitleLine({required this.text, required this.showVerified});

  final String text;
  final bool showVerified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Row(
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (showVerified) ...[
            const SizedBox(width: 4),
            const Icon(AppIcons.verified, size: 14, color: AppColors.info),
          ],
        ],
      ),
    );
  }
}
