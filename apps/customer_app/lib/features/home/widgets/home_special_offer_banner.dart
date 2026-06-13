import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive/app_responsive.dart';
import '../../../core/widgets/media/app_food_image.dart';

/// Green gradient promo card (Special Offers section).
class HomeSpecialOfferBanner extends StatelessWidget {
  const HomeSpecialOfferBanner({
    super.key,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.placeholderSeed = 'special-offer-banner',
    this.embedInPadding = true,
    this.onTap,
  });

  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String placeholderSeed;
  /// When false, parent (e.g. carousel) supplies horizontal inset.
  final bool embedInPadding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final headline = title ?? '30%';
    final line = subtitle ?? 'DISCOUNT ONLY\nVALID FOR TODAY!';
    final height = AppResponsive.homeOfferBannerHeight(context);
    final padding = AppResponsive.pagePadding(context);

    final banner = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: AppResponsive.value(context, mobile: 40.0, tablet: 44.0),
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          line,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onPrimary.withValues(alpha: 0.95),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: -8,
                    bottom: -12,
                    top: 8,
                    width: AppResponsive.value(context, mobile: 160.0, tablet: 180.0, desktop: 200.0),
                    child: AppFoodImage(
                      imageUrl: imageUrl,
                      placeholderSeed: placeholderSeed,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );

    if (!embedInPadding) return banner;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: banner,
    );
  }
}
