import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../utils/responsive/app_responsive.dart';

enum AppLayoutSize { mobile, tablet, desktop }

abstract final class AppBreakpoints {
  static const double tablet = 451;
  static const double desktop = 801;

  static AppLayoutSize of(BuildContext context) {
    try {
      final bp = ResponsiveBreakpoints.of(context);
      if (bp.isDesktop) return AppLayoutSize.desktop;
      if (bp.isTablet) return AppLayoutSize.tablet;
      return AppLayoutSize.mobile;
    } catch (_) {
      final w = MediaQuery.sizeOf(context).width;
      if (w >= 1024) return AppLayoutSize.desktop;
      if (w >= 600) return AppLayoutSize.tablet;
      return AppLayoutSize.mobile;
    }
  }

  static double pagePadding(BuildContext context) => AppResponsive.pagePadding(context);

  static int menuGridColumns(BuildContext context) {
    return switch (of(context)) {
      AppLayoutSize.mobile => 1,
      AppLayoutSize.tablet => 2,
      AppLayoutSize.desktop => 3,
    };
  }
}
