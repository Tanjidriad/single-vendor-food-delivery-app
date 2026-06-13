import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/home_offer_card_layout.dart';
import '../../../core/widgets/media/app_food_image.dart';
import '../../../features/favorites/presentation/providers/favorites_provider.dart';

/// Uber-style card: photo → title + delivery line → optional rating.
/// Layout numbers: [HomeOfferCardLayout] in `core/theme/home_offer_card_layout.dart`.
class HomeOfferCard extends ConsumerWidget {
  const HomeOfferCard({
    super.key,
    required this.title,
    required this.deliveryMeta,
    this.imageUrl,
    this.itemId,
    this.rating,
    this.promoBadge,
    this.onTap,
    this.width,
    this.elevated = false,
  });

  final String title;
  final String deliveryMeta;
  final String? imageUrl;
  final String? itemId;
  final double? rating;
  final String? promoBadge;
  final VoidCallback? onTap;
  final double? width;
  final bool elevated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final imageRadius = elevated
        ? const BorderRadius.vertical(top: Radius.circular(16))
        : BorderRadius.circular(HomeOfferCardLayout.imageCornerRadius);

    final favorites = itemId != null ? ref.watch(favoriteMenuItemIdsProvider) : null;
    final isFavorite = itemId != null && (favorites?.valueOrNull?.contains(itemId!) ?? false);

    final content = Material(
      color: scheme.surface,
      borderRadius: elevated ? BorderRadius.circular(16) : null,
      clipBehavior: elevated ? Clip.antiAlias : Clip.none,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHOTO ---
            ClipRRect(
              borderRadius: imageRadius,
              child: AspectRatio(
                aspectRatio: HomeOfferCardLayout.imageAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppFoodImage(
                      imageUrl: imageUrl,
                      placeholderSeed: itemId ?? title,
                      fit: BoxFit.cover,
                    ),
                    if (promoBadge != null)
                      Positioned(
                        top: 10,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Text(
                            promoBadge!,
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: HomeOfferCardLayout.promoFontSize,
                            ),
                          ),
                        ),
                      ),
                    if (itemId != null)
                      Positioned(
                        top: HomeOfferCardLayout.heartTapPadding,
                        right: HomeOfferCardLayout.heartTapPadding,
                        child: GestureDetector(
                          onTap: favorites!.isLoading
                              ? null
                              : () => ref.read(favoriteMenuItemIdsProvider.notifier).toggle(itemId!),
                          child: Icon(
                            isFavorite ? AppIcons.heartFilled : AppIcons.heart,
                            size: HomeOfferCardLayout.heartIconSize,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Color(0x99000000), blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: HomeOfferCardLayout.gapBelowImage),

            // --- TITLE + DELIVERY + RATING ---
            Padding(
              padding: EdgeInsets.fromLTRB(elevated ? 16 : 0, 0, elevated ? 16 : 0, elevated ? 16 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: HomeOfferCardLayout.titleFontSize,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deliveryMeta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: HomeOfferCardLayout.subtitleFontSize,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rating != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: HomeOfferCardLayout.ratingSize,
                      height: HomeOfferCardLayout.ratingSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        rating!.toStringAsFixed(1),
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    Widget card = content;
    if (width != null) {
      card = SizedBox(width: width, child: card);
    }
    if (elevated) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: card,
      );
    }
    return card;
  }
}

// --- Menu item helpers (used by home_screen) ---

String homeOfferDeliveryMeta(String deliveryFeeLabel, {String? eta}) {
  if (eta != null && eta.isNotEmpty) {
    if (deliveryFeeLabel.toLowerCase().contains('free')) {
      return 'Free delivery • $eta';
    }
    final fee = deliveryFeeLabel.replaceFirst(RegExp(r'^Delivery\s+', caseSensitive: false), '');
    return '$fee Delivery Fee • $eta';
  }

  if (deliveryFeeLabel.toLowerCase().contains('free')) {
    return 'Free delivery';
  }
  final fee = deliveryFeeLabel.replaceFirst(RegExp(r'^Delivery\s+', caseSensitive: false), '');
  return '$fee Delivery Fee';
}

String? homeOfferPromoBadge(Map<String, dynamic> item, double? salePrice, double price) {
  if (salePrice != null && salePrice > 0 && salePrice < price) {
    final pct = ((price - salePrice) / price * 100).round();
    return '$pct% off';
  }
  final badge = item['promoLabel'] as String?;
  if (badge != null && badge.isNotEmpty) return badge;
  return null;
}

double? homeOfferRating(Map<String, dynamic> item) {
  final r = item['averageRating'] ?? item['rating'];
  if (r is num && r > 0) return r.toDouble();
  return null;
}

double? homeOfferSalePrice(Map<String, dynamic> item) {
  final sale = item['salePrice'] ?? item['discountedPrice'];
  if (sale is num && sale > 0) return sale.toDouble();
  return null;
}
