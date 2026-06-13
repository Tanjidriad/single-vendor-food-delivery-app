import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../features/cart/domain/entities/cart_item.dart';
import '../../../features/cart/presentation/providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters/formatter.dart';
import '../media/app_food_image.dart';

enum MenuItemDietType { veg, nonVeg }

enum PremiumMenuItemCardVariant { expanded, compact }

class PremiumMenuItemCardData {
  const PremiumMenuItemCardData({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.discountedPrice,
    this.dietType,
    this.badge,
    this.isCustomizable = false,
    this.rating,
    this.ratingCount,
    this.highlightLabel,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double price;
  final double? discountedPrice;
  final MenuItemDietType? dietType;
  final String? badge;
  final bool isCustomizable;
  final double? rating;
  final int? ratingCount;
  final String? highlightLabel;

  double get displayPrice =>
      discountedPrice != null && discountedPrice! > 0 && discountedPrice! < price
          ? discountedPrice!
          : price;

  bool get hasDiscount =>
      discountedPrice != null && discountedPrice! > 0 && discountedPrice! < price;
}

class PremiumMenuItemCard extends ConsumerWidget {
  const PremiumMenuItemCard({
    super.key,
    required this.data,
    this.variant = PremiumMenuItemCardVariant.expanded,
    this.onTap,
    this.onCustomize,
    this.elevated = true,
    this.width,
  });

  final PremiumMenuItemCardData data;
  final PremiumMenuItemCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onCustomize;
  final bool elevated;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final cart = ref.watch(cartProvider);
    final quantity = cart.items
        .where((item) => item.menuItemId == data.id)
        .fold<int>(0, (sum, item) => sum + item.quantity);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. DETAILS COLUMN (LEFT) ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Diet Indicator & Title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data.dietType != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 3.0, right: 6.0),
                              child: _DietIndicator(type: data.dietType!),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              data.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Description
                      if (data.description != null && data.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          data.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      // Rating & Quality badges row
                      if (data.highlightLabel != null || data.rating != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (data.highlightLabel != null)
                              _SoftPill(
                                icon: Iconsax.heart5,
                                label: data.highlightLabel!,
                                iconColor: AppColors.primary,
                                bgColor: AppColors.primaryLight,
                              ),
                            if (data.rating != null)
                              _SoftPill(
                                icon: Iconsax.star1,
                                label: data.ratingCount != null
                                    ? '${data.rating!.toStringAsFixed(1)} (${data.ratingCount})'
                                    : data.rating!.toStringAsFixed(1),
                                iconColor: AppColors.warning,
                                bgColor: AppColors.warningLight,
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Price and Quantity Add Button Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppFormatter.formatCurrency(data.displayPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                ),
                              ),
                              if (data.hasDiscount) ...[
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatter.formatCurrency(data.price),
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (data.isCustomizable) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '• Custom',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // --- 2. IMAGE COLUMN & ACTION (RIGHT) ---
                Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: AppFoodImage(
                              imageUrl: data.imageUrl,
                              placeholderSeed: data.id,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (data.badge != null)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                data.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Action add/increment button sits safely right below the image container
                    _MenuItemCartAction(
                      quantity: quantity,
                      isCustomizable: data.isCustomizable,
                      onAdd: () {
                        if (data.isCustomizable && onCustomize != null) {
                          onCustomize!();
                          return;
                        }
                        ref.read(cartProvider.notifier).addItem(
                              CartItem(
                                menuItemId: data.id,
                                name: data.name,
                                unitPrice: data.displayPrice,
                                quantity: 1,
                                imageUrl: data.imageUrl,
                              ),
                            );
                      },
                      onIncrement: () {
                        ref.read(cartProvider.notifier).addItem(
                              CartItem(
                                menuItemId: data.id,
                                name: data.name,
                                unitPrice: data.displayPrice,
                                quantity: 1,
                                imageUrl: data.imageUrl,
                              ),
                            );
                      },
                      onDecrement: () {
                        ref
                            .read(cartProvider.notifier)
                            .updateQuantity(data.id, quantity - 1);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemCartAction extends StatelessWidget {
  const _MenuItemCartAction({
    required this.quantity,
    required this.isCustomizable,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final bool isCustomizable;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    if (quantity > 0 && !isCustomizable) {
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onDecrement,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50),
                bottomLeft: Radius.circular(50),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Icon(Iconsax.minus, size: 14, color: Colors.white),
              ),
            ),
            SizedBox(
              width: 16,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            InkWell(
              onTap: onIncrement,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Icon(AppIcons.add, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        height: 32,
        padding: EdgeInsets.symmetric(
          horizontal: isCustomizable ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.primary, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCustomizable ? Iconsax.setting_4 : AppIcons.add,
              size: 13,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              isCustomizable ? 'Customize' : 'ADD',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DietIndicator extends StatelessWidget {
  const _DietIndicator({required this.type});

  final MenuItemDietType type;

  @override
  Widget build(BuildContext context) {
    final color = type == MenuItemDietType.veg ? AppColors.primary : AppColors.error;

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.3),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  const _SoftPill({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

PremiumMenuItemCardData premiumMenuItemCardDataFromJson(
  Map<String, dynamic> json, {
  String? categoryName,
}) {
  final id = json['id'] as String? ?? '';
  final name = json['name'] as String? ?? '';
  final description = json['description'] as String?;
  final imageUrl = json['imageUrl'] as String?;
  final price = (json['price'] as num?)?.toDouble() ?? 0.0;
  final discountedPrice = (json['discountedPrice'] ?? json['salePrice']) as num?;
  
  MenuItemDietType? dietType;
  final isVeg = json['isVeg'] as bool? ?? false;
  if (isVeg) {
    dietType = MenuItemDietType.veg;
  } else if (json['isVeg'] != null) {
    dietType = MenuItemDietType.nonVeg;
  }
  
  final isCustomizable = (json['addons'] as List?)?.isNotEmpty ?? json['isCustomizable'] as bool? ?? false;
  
  final ratingVal = json['averageRating'] ?? json['rating'];
  final rating = ratingVal is num ? ratingVal.toDouble() : null;
  final ratingCount = json['ratingCount'] as int?;
  
  final isFeatured = json['isFeatured'] as bool? ?? false;
  final highlightLabel = isFeatured ? 'Most Loved' : null;

  return PremiumMenuItemCardData(
    id: id,
    name: name,
    description: description,
    imageUrl: imageUrl,
    price: price,
    discountedPrice: discountedPrice?.toDouble(),
    dietType: dietType,
    badge: isFeatured ? 'Popular' : null,
    isCustomizable: isCustomizable,
    rating: rating,
    ratingCount: ratingCount,
    highlightLabel: highlightLabel,
  );
}

