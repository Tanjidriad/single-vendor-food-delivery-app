import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../media/app_food_image.dart';
import '../shapes/app_rounded_container.dart';
import '../texts/app_product_price_text.dart';
import '../texts/app_product_title_text.dart';
import 'app_favorite_button.dart';
import 'widgets/app_product_card_add_button.dart';
import 'widgets/app_product_sale_tag.dart';

/// CWT [TProductCardVertical] adapted for menu items.
class AppProductCardVertical extends StatelessWidget {
  const AppProductCardVertical({
    super.key,
    required this.menuItemId,
    required this.title,
    required this.price,
    this.imageUrl,
    this.salePrice,
    this.subtitle,
    this.onTap,
    this.onAddToCart,
    this.width = 180,
  });

  final String menuItemId;
  final double width;
  final String title;
  final double price;
  final double? salePrice;
  final String? imageUrl;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

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
        decoration: BoxDecoration(
          boxShadow: const [AppShadows.verticalProduct],
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          color: AppColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppRoundedContainer(
              height: width,
              width: width,
              padding: const EdgeInsets.all(AppSpacing.sm),
              backgroundColor: AppColors.inputFill,
              showBorder: false,
              radius: AppSpacing.radiusLg,
              child: Stack(
                children: [
                  Center(
                    child: AppFoodImage(
                      imageUrl: imageUrl,
                      placeholderSeed: menuItemId,
                      width: width - 20,
                      height: width - 20,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  if (saleLabel != null) AppProductSaleTag(label: saleLabel),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: AppFavoriteButton(menuItemId: menuItemId),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppProductTitleText(title: title, compact: true),
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
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (saleLabel != null)
                        AppProductPriceText(price: price, lineThrough: true, isLarge: false),
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
            ),
          ],
        ),
      ),
    );
  }
}
