import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../theme/home_offer_card_layout.dart';
import '../../theme/home_promo_banner_layout.dart';

/// Helpers on top of [responsive_framework] breakpoints.
abstract final class AppResponsive {
  AppResponsive._();

  static const mobile = MOBILE;
  static const tablet = TABLET;
  static const desktop = DESKTOP;

  static ResponsiveBreakpointsData of(BuildContext context) =>
      ResponsiveBreakpoints.of(context);

  static bool isMobile(BuildContext context) => of(context).isMobile;

  static bool isTablet(BuildContext context) => of(context).isTablet;

  static bool isDesktop(BuildContext context) => of(context).isDesktop;

  /// Pick a value for the current breakpoint (mobile → tablet → desktop).
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final bp = of(context);
    if (bp.largerThan(TABLET) && desktop != null) return desktop;
    if (bp.largerThan(MOBILE) && tablet != null) return tablet;
    return mobile;
  }

  static double pagePadding(BuildContext context) => value(
        context,
        mobile: 16,
        tablet: 24,
        desktop: 32,
      );

  static int homeCategoryColumns(BuildContext context) => value(
        context,
        mobile: 4,
        tablet: 6,
        desktop: 8,
      );

  /// Uber-style carousel card (~82% viewport width for peek).
  static double homeOfferCarouselCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return value(
      context,
      mobile: screenWidth * 0.82,
      tablet: 320,
      desktop: 360,
    );
  }

  static double homeOfferCarouselHeight(BuildContext context) {
    final cardWidth = homeOfferCarouselCardWidth(context);
    return cardWidth / HomeOfferCardLayout.imageAspectRatio + 72;
  }

  @Deprecated('Use homeOfferCarouselCardWidth')
  static double homePromoCardWidth(BuildContext context) => homeOfferCarouselCardWidth(context);

  @Deprecated('Use homeOfferCarouselHeight')
  static double homePromoRowHeight(BuildContext context) => homeOfferCarouselHeight(context);

  static int productGridColumns(BuildContext context) => value(
        context,
        mobile: 2,
        tablet: 3,
        desktop: 4,
      );

  static double productGridCardExtent(BuildContext context) => value(
        context,
        mobile: 300,
        tablet: 310,
        desktop: 320,
      );

  /// Promo split-card carousel height.
  static double homeOfferBannerHeight(BuildContext context) =>
      HomePromoBannerLayout.cardHeight;

  static double homeCategoryTileSize(BuildContext context) => value(
        context,
        mobile: 64,
        tablet: 72,
        desktop: 80,
      );
}
