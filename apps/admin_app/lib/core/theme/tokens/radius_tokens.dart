import 'package:flutter/material.dart';

/// Design token class for border radius values.
///
/// Provides named radii as doubles and convenience [BorderRadius] getters.
class RadiusTokens {
  const RadiusTokens();

  // Named radii (in logical pixels)
  static const double none = 0;
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
  static const double xxl = 16;

  // Convenience BorderRadius getters
  static BorderRadius get borderRadiusNone => BorderRadius.zero;
  static BorderRadius get borderRadiusSm => BorderRadius.circular(sm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(md);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(lg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(xl);
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(xxl);
}
