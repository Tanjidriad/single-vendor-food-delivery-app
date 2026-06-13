import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // Primary Scale
  static const primary50 = Color(0xFFEDF6EE);
  static const primary100 = Color(0xFFC7E3CB);
  static const primary200 = Color(0xFFACD5B2);
  static const primary300 = Color(0xFF86C28E);
  static const primary400 = Color(0xFF6FB679);
  static const primary500 = Color(0xFF4BA457);
  static const primary600 = Color(0xFF44954F);
  static const primary700 = Color(0xFF35743E);
  static const primary800 = Color(0xFF295A30);
  static const primary900 = Color(0xFF204525);

  // Secondary Scale
  static const secondary50 = Color(0xFFEBF6EE);
  static const secondary100 = Color(0xFFC0E4CA);
  static const secondary200 = Color(0xFFA2D7B0);
  static const secondary300 = Color(0xFF77C58C);
  static const secondary400 = Color(0xFF05A357);
  static const secondary500 = Color(0xFF34A853);
  static const secondary600 = Color(0xFF2F994C);
  static const secondary700 = Color(0xFF25773B);
  static const secondary800 = Color(0xFF1D5C2E);
  static const secondary900 = Color(0xFF164723);

  // White Scale
  static const white50 = Color(0xFFFFFFFF);
  static const white100 = Color(0xFFFFFFFF);
  static const white200 = Color(0xFFFFFFFF);
  static const white300 = Color(0xFFFFFFFF);
  static const white400 = Color(0xFFFFFFFF);
  static const white500 = Color(0xFFFFFFFF);
  static const white600 = Color(0xFFE8E8E8);
  static const white700 = Color(0xFFB5B5B5);
  static const white800 = Color(0xFF8C8C8C);
  static const white900 = Color(0xFF6B6B6B);

  // Black Scale
  static const black50 = Color(0xFFE6E6E6);
  static const black100 = Color(0xFFB0B0B0);
  static const black200 = Color(0xFF8A8A8A);
  static const black300 = Color(0xFF545454);
  static const black400 = Color(0xFF333333);
  static const black500 = Color(0xFF000000);
  static const black600 = Color(0xFF000000);
  static const black700 = Color(0xFF000000);
  static const black800 = Color(0xFF000000);
  static const black900 = Color(0xFF000000);

  // Gray Scale
  static const gray50 = Color(0xFFFDFDFD);
  static const gray100 = Color(0xFFFAFAFA);
  static const gray200 = Color(0xFFF7F7F7);
  static const gray300 = Color(0xFFF4F4F4);
  static const gray400 = Color(0xFFF1F1F1);
  static const gray500 = Color(0xFFEEEEEE);
  static const gray600 = Color(0xFFD9D9D9);
  static const gray700 = Color(0xFFA9A9A9);
  static const gray800 = Color(0xFF838383);
  static const gray900 = Color(0xFF646464);

  // Blue Scale
  static const blue50 = Color(0xFFE9F1FE);
  static const blue100 = Color(0xFFBCD2FB);
  static const blue200 = Color(0xFF9CBCF9);
  static const blue300 = Color(0xFF6E9EF6);
  static const blue400 = Color(0xFF528BF4);
  static const blue500 = Color(0xFF276EF1);
  static const blue600 = Color(0xFF2364DB);
  static const blue700 = Color(0xFF1C4EAB);
  static const blue800 = Color(0xFF153D85);
  static const blue900 = Color(0xFF102E65);

  // --- Custom Accents ---
  static const pandaPink = Color(0xFFD70F64);
  static const pandaPinkDark = Color(0xFFB00C52);
  static const pandaPinkLight = Color(0xFFFDE7EF);

  // --- Semantic ---
  static const primary = pandaPink;
  static const primaryDark = pandaPinkDark;
  static const primaryLight = pandaPinkLight;

  static const surface = white50; // White
  static const background = gray100; // Light Gray
  static const border = gray300;
  static const borderStrong = gray400;

  static const textPrimary = black500;
  static const textSecondary = gray800;
  static const textDisabled = gray700;
  static const onPrimary = white50;

  static const success = Color(0xFF10B981); // Emerald 500
  static const successLight = Color(0xFFD1FAE5); // Emerald 100
  static const warning = Color(0xFFF59E0B); // Amber 500
  static const warningLight = Color(0xFFFEF3C7); // Amber 100
  static const error = Color(0xFFEF4444); // Red 500
  static const errorLight = Color(0xFFFEE2E2); // Red 100
  static const info = Color(0xFF06B6D4); // Cyan 500
  static const infoLight = Color(0xFFCFFAFE); // Cyan 100

  // --- Dark theme tokens ---
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkBackground = Color(0xFF121212);
  static const darkElevated = Color(0xFF252525);
  static const darkBorder = Color(0xFF333333);
  static const darkBorderStrong = Color(0xFF444444);
  static const darkTextPrimary = Color(0xFFF5F5F5);
  static const darkTextSecondary = Color(0xFFB0B0B0);
}
