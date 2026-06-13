import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../utils/placeholders/placeholder_images.dart';
import '../shimmers/app_shimmer_effect.dart';

/// Network image with shimmer loading and [PlaceholderImages] fallback.
class AppFoodImage extends StatelessWidget {
  const AppFoodImage({
    super.key,
    this.imageUrl,
    required this.placeholderSeed,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? imageUrl;
  final String placeholderSeed;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  String get _resolvedUrl {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) return imageUrl!.trim();
    final w = width?.round() ?? 400;
    final h = height?.round() ?? 400;
    return PlaceholderImages.food(seed: placeholderSeed, width: w, height: h);
  }

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: _resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => AppShimmerEffect(
            width: width ?? double.infinity,
            height: height ?? double.infinity,
            radius: borderRadius?.topLeft.x ?? 15,
          ),
      errorWidget: (_, __, ___) => _ErrorBox(width: width, height: height, borderRadius: borderRadius),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({this.width, this.height, this.borderRadius});

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      alignment: Alignment.center,
      child: const Icon(AppIcons.imageOff, color: AppColors.primary, size: 28),
    );
  }
}
