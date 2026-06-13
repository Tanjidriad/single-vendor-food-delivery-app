import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/app_icons.dart';
import '../media/app_food_image.dart';

/// Data model for rendering a restaurant card.
class RestaurantCardData {
  const RestaurantCardData({
    required this.id,
    required this.name,
    this.imageUrl,
    this.cuisines = const [],
    this.rating,
    this.reviewCount,
    this.deliveryEta,
    this.deliveryFee,
    this.distance,
    this.promoBadge,
    this.statusLabel,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final List<String> cuisines;
  final double? rating;
  final int? reviewCount;
  final String? deliveryEta;
  final String? deliveryFee;
  final String? distance;
  final String? promoBadge;
  final RestaurantStatusLabel? statusLabel;
  final bool isFavorite;
}

enum RestaurantStatusLabel { busy, newRestaurant, trending }

/// Premium restaurant listing card — Uber Eats / DoorDash inspired.
///
/// Image-first layout with clean metadata row, optional promo badge,
/// heart button, and status label. Uses project theme and design tokens.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.data,
    this.onTap,
    this.onFavoriteToggle,
    this.width,
  });

  final RestaurantCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget card = Container(
      width: width,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- COVER IMAGE ---
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppFoodImage(
                        imageUrl: data.imageUrl,
                        placeholderSeed: data.name,
                        fit: BoxFit.cover,
                      ),

                      // --- PROMO BADGE ---
                      if (data.promoBadge != null)
                        Positioned(
                          top: 12,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Text(
                              data.promoBadge!,
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                      // --- STATUS LABEL (Busy / New / Trending) ---
                      if (data.statusLabel != null)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: _StatusChip(label: data.statusLabel!, scheme: scheme, textTheme: textTheme),
                        ),

                      // --- FAVORITE HEART BUTTON ---
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.28),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              data.isFavorite ? AppIcons.heartFilled : AppIcons.heart,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- INFO SECTION ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- NAME + RATING ---
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (data.rating != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.star1, size: 14, color: scheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  data.rating!.toStringAsFixed(1),
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (data.reviewCount != null) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    '(${_compactCount(data.reviewCount!)})',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // --- CUISINE TAG LINE ---
                    if (data.cuisines.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          data.cuisines.join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                    // --- DELIVERY META ROW ---
                    Row(
                      children: [
                        if (data.deliveryEta != null)
                          _MetaChip(
                            icon: Iconsax.clock,
                            label: data.deliveryEta!,
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                        if (data.deliveryFee != null) ...[
                          if (data.deliveryEta != null) _dot(scheme),
                          _MetaChip(
                            icon: AppIcons.bike,
                            label: data.deliveryFee!,
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                        ],
                        if (data.distance != null) ...[
                          if (data.deliveryEta != null || data.deliveryFee != null) _dot(scheme),
                          _MetaChip(
                            icon: AppIcons.location,
                            label: data.distance!,
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return card;
  }

  Widget _dot(ColorScheme scheme) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('•', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
      );

  String _compactCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

// --- FEATURED VARIANT ---

/// Wider card with a taller image for highlighted / promoted restaurants.
class FeaturedRestaurantCard extends StatelessWidget {
  const FeaturedRestaurantCard({
    super.key,
    required this.data,
    this.onTap,
    this.onFavoriteToggle,
    this.width,
  });

  final RestaurantCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- FEATURED COVER IMAGE (taller) ---
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppFoodImage(
                        imageUrl: data.imageUrl,
                        placeholderSeed: data.name,
                        fit: BoxFit.cover,
                      ),

                      // Subtle bottom gradient for text legibility
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Bottom overlay text
                      Positioned(
                        bottom: 14,
                        left: 16,
                        right: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data.promoBadge != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  data.promoBadge!,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: scheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            Text(
                              data.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (data.cuisines.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  data.cuisines.join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Heart button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              data.isFavorite ? AppIcons.heartFilled : AppIcons.heart,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Status label
                      if (data.statusLabel != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _StatusChip(label: data.statusLabel!, scheme: scheme, textTheme: textTheme),
                        ),
                    ],
                  ),
                ),
              ),

              // --- FEATURED INFO ROW ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    if (data.rating != null) ...[
                      Icon(Iconsax.star1, size: 16, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        data.rating!.toStringAsFixed(1),
                        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (data.deliveryEta != null) ...[
                      Icon(Iconsax.clock, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        data.deliveryEta!,
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (data.deliveryFee != null)
                      Text(
                        data.deliveryFee!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

// --- PRIVATE SHARED WIDGETS ---

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.scheme,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.scheme,
    required this.textTheme,
  });

  final RestaurantStatusLabel label;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final (text, bgColor, fgColor) = switch (label) {
      RestaurantStatusLabel.busy => ('Busy', scheme.errorContainer, scheme.error),
      RestaurantStatusLabel.newRestaurant => ('New', scheme.primaryContainer, scheme.primary),
      RestaurantStatusLabel.trending => ('Trending', scheme.tertiaryContainer, scheme.tertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: textTheme.labelSmall?.copyWith(
          color: fgColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
