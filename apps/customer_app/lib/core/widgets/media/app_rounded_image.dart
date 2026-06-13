import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../shimmers/app_shimmer_effect.dart';

/// Rounded network/asset image (ported from CWT [TRoundedImage]).
class AppRoundedImage extends StatelessWidget {
  const AppRoundedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
    this.backgroundColor,
    this.onTap,
    this.isNetworkImage = true,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: isNetworkImage
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: fit,
                width: width,
                height: height,
                placeholder: (_, __) => AppShimmerEffect(
                  width: width ?? double.infinity,
                  height: height ?? 190,
                  radius: borderRadius,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: backgroundColor,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              )
            : Image.asset(imageUrl, fit: fit, width: width, height: height),
      ),
    );

    if (onTap == null) return child;

    return GestureDetector(onTap: onTap, child: child);
  }
}
