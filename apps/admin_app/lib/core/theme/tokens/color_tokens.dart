import 'package:flutter/material.dart';

/// Design token class for all color values in the design system.
///
/// Provides both light and dark color palettes with neutral gray scale,
/// primary accent, semantic colors, surface/background/border tokens,
/// and text colors.
class ColorTokens {
  // Neutral gray scale (50–900)
  final Color gray50;
  final Color gray100;
  final Color gray200;
  final Color gray300;
  final Color gray400;
  final Color gray500;
  final Color gray600;
  final Color gray700;
  final Color gray800;
  final Color gray900;

  // Primary accent
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  // Semantic colors
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color error;
  final Color errorLight;
  final Color info;
  final Color infoLight;

  // Surface / Background / Border
  final Color surface;
  final Color background;
  final Color border;
  final Color borderStrong;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color onPrimary;

  const ColorTokens({
    required this.gray50,
    required this.gray100,
    required this.gray200,
    required this.gray300,
    required this.gray400,
    required this.gray500,
    required this.gray600,
    required this.gray700,
    required this.gray800,
    required this.gray900,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.surface,
    required this.background,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.onPrimary,
  });
}

/// Light color palette instance.
const ColorTokens lightColorTokens = ColorTokens(
  // Neutral gray scale
  gray50: Color(0xFFFAFAFA),
  gray100: Color(0xFFF5F5F5),
  gray200: Color(0xFFEEEEEE),
  gray300: Color(0xFFE0E0E0),
  gray400: Color(0xFFBDBDBD),
  gray500: Color(0xFF9E9E9E),
  gray600: Color(0xFF757575),
  gray700: Color(0xFF616161),
  gray800: Color(0xFF424242),
  gray900: Color(0xFF212121),

  // Primary accent (green-based, matching existing brand)
  primary: Color(0xFF4BA457),
  primaryLight: Color(0xFFEDF6EE),
  primaryDark: Color(0xFF35743E),

  // Semantic colors
  success: Color(0xFF2F994C),
  successLight: Color(0xFFEBF6EE),
  warning: Color(0xFFE9A23B),
  warningLight: Color(0xFFFFF8E1),
  error: Color(0xFFD62828),
  errorLight: Color(0xFFFFEBEE),
  info: Color(0xFF2364DB),
  infoLight: Color(0xFFE9F1FE),

  // Surface / Background / Border
  surface: Color(0xFFFFFFFF),
  background: Color(0xFFF8F9FA),
  border: Color(0xFFE0E0E0),
  borderStrong: Color(0xFFBDBDBD),

  // Text
  textPrimary: Color(0xFF212121),
  textSecondary: Color(0xFF757575),
  textDisabled: Color(0xFFBDBDBD),
  onPrimary: Color(0xFFFFFFFF),
);

/// Dark color palette instance.
const ColorTokens darkColorTokens = ColorTokens(
  // Neutral gray scale (inverted for dark mode)
  gray50: Color(0xFF1A1A1A),
  gray100: Color(0xFF212121),
  gray200: Color(0xFF2C2C2C),
  gray300: Color(0xFF383838),
  gray400: Color(0xFF4A4A4A),
  gray500: Color(0xFF6B6B6B),
  gray600: Color(0xFF9E9E9E),
  gray700: Color(0xFFBDBDBD),
  gray800: Color(0xFFE0E0E0),
  gray900: Color(0xFFF5F5F5),

  // Primary accent (slightly brighter for dark backgrounds)
  primary: Color(0xFF5CB868),
  primaryLight: Color(0xFF1E3A22),
  primaryDark: Color(0xFF86C28E),

  // Semantic colors (adjusted for 4.5:1 contrast on dark surfaces)
  success: Color(0xFF4CAF50),
  successLight: Color(0xFF1B3D1E),
  warning: Color(0xFFFFC107),
  warningLight: Color(0xFF3D3000),
  error: Color(0xFFEF5350),
  errorLight: Color(0xFF3D1515),
  info: Color(0xFF64B5F6),
  infoLight: Color(0xFF152A3D),

  // Surface / Background / Border
  surface: Color(0xFF1E1E1E),
  background: Color(0xFF121212),
  border: Color(0xFF383838),
  borderStrong: Color(0xFF4A4A4A),

  // Text
  textPrimary: Color(0xFFF5F5F5),
  textSecondary: Color(0xFFBDBDBD),
  textDisabled: Color(0xFF6B6B6B),
  onPrimary: Color(0xFFFFFFFF),
);
