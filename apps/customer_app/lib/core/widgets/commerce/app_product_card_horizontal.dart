import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../media/app_food_image.dart';
import '../shapes/app_rounded_container.dart';
import '../texts/app_product_price_text.dart';
import '../texts/app_product_title_text.dart';
import 'app_favorite_button.dart';
import 'widgets/app_product_card_add_button.dart';
import 'widgets/app_product_sale_tag.dart';

/// CWT [TProductCardHorizontal] adapted for menu items.
class AppProductCardHorizontal extends StatelessWidget {
  const AppProductCardHorizontal({
    super.key,
    required this.menuItemId,
    required this.title,
    required this.price,
    this.imageUrl,
    this.salePrice,
    this.subtitle,
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
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final double width;

  String? get _saleLabel {
    if (salePrice == null || salePrice! <= 0 || salePrice! >= price) return null;
    final pct = ((price - salePrice!) / price * 100).round();
    return '-$pct%';
  }

  double get _displayPrice => (salePrice != null && salePrice! > 0) ? salePrice! : price;

  @override
  Widget build(BuildContext context) {
    final saleLabel = _saleLabel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          color: AppColors.inputFill,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppRoundedContainer(
              height: 120,
              width: 120,
              padding: const EdgeInsets.all(AppSpacing.sm),
              backgroundColor: AppColors.surface,
              showBorder: false,
              child: Stack(
                children: [
                  AppFoodImage(
                    imageUrl: imageUrl,
                    placeholderSeed: menuItemId,
                    width: 108,
                    height: 108,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  if (saleLabel != null) AppProductSaleTag(label: saleLabel),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: AppFavoriteButton(menuItemId: menuItemId, size: 32),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              width: width - 120,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm, top: AppSpacing.sm, right: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppProductTitleText(title: title, compact: true, maxLines: 2),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (saleLabel != null)
                              AppProductPriceText(price: price, lineThrough: true),
                            AppProductPriceText(price: _displayPrice),
                          ],
                        ),
                        AppProductCardAddButton(
                          menuItemId: menuItemId,
                          name: title,
                          unitPrice: _displayPrice,
                          imageUrl: imageUrl,
                          onNavigateToDetail: onAddToCart ?? onTap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
