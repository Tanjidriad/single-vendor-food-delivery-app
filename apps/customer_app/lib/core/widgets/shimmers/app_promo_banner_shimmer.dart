import 'package:flutter/material.dart';

import '../../theme/home_promo_banner_layout.dart';
import '../../utils/responsive/app_responsive.dart';
import 'app_shimmer_effect.dart';

/// Promo carousel placeholder (split-card shape).
class AppPromoBannerShimmer extends StatelessWidget {
  const AppPromoBannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final height = AppResponsive.homeOfferBannerHeight(context);
    final padding = AppResponsive.pagePadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: AppShimmerEffect(
        width: double.infinity,
        height: height,
        radius: HomePromoBannerLayout.cardRadius,
      ),
    );
  }
}
