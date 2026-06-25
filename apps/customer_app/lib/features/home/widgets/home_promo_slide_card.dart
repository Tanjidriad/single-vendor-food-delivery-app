import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/home_promo_banner_layout.dart';
import '../../../core/widgets/media/app_food_image.dart';

/// Uber Eats–style promo slide: colored panel + copy + CTA | photo.
class HomePromoSlideCard extends StatelessWidget {
  const HomePromoSlideCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.backgroundColor,
    this.ctaLabel = 'Browse offer',
    this.onTap,
    this.onCtaTap,
  });

  final String title;
  final String? imageUrl;
  final Color backgroundColor;
  final String ctaLabel;
  final VoidCallback? onTap;
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(HomePromoBannerLayout.cardRadius);

    return Material(
      color: backgroundColor,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: HomePromoBannerLayout.cardHeight,
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: HomePromoBannerLayout.titleFontSize,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: _BrowseOfferButton(
                          label: ctaLabel,
                          onTap: onCtaTap ?? onTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 10,
                child: AppFoodImage(
                  imageUrl: imageUrl,
                  placeholderSeed: title,
                  fit: BoxFit.cover,
                  height: HomePromoBannerLayout.cardHeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseOfferButton extends StatelessWidget {
  const _BrowseOfferButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: HomePromoBannerLayout.ctaFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(AppIcons.arrowRight, size: 16, color: AppColors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
