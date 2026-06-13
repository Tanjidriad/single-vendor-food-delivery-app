import 'package:flutter/material.dart';

/// Design token class for typography values.
///
/// Defines named sizes, font weights, font family, and a convenience
/// [style] builder for creating TextStyle instances from tokens.
class TypographyTokens {
  const TypographyTokens();

  // Named sizes (in logical pixels)
  static const double xs = 11;
  static const double sm = 12;
  static const double base = 13;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 20;
  static const double xxxl = 24;

  // Named font weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Font family
  static const String fontFamily = 'Plus Jakarta Sans';

  /// Convenience builder for creating a [TextStyle] from token values.
  ///
  /// Defaults to [base] size, [regular] weight, and [fontFamily].
  TextStyle style({
    double size = base,
    FontWeight weight = regular,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }
}
