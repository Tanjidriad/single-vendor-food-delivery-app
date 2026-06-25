import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // Primary Scale (Red — derived from brand #D21F3C)
  static const primary50 = Color(0xFFFDF2F4);
  static const primary100 = Color(0xFFFCE4E8);
  static const primary200 = Color(0xFFF9C5CD);
  static const primary300 = Color(0xFFF49AAA);
  static const primary400 = Color(0xFFED6A81);
  static const primary500 = Color(0xFFD21F3C);
  static const primary600 = Color(0xFFB91A33);
  static const primary700 = Color(0xFF9A1629);
  static const primary800 = Color(0xFF801425);
  static const primary900 = Color(0xFF6E1324);

  // Accent Scale (Green — for success states and secondary callouts)
  static const accent50 = Color(0xFFEBF6EE);
  static const accent100 = Color(0xFFC0E4CA);
  static const accent200 = Color(0xFFA2D7B0);
  static const accent300 = Color(0xFF77C58C);
  static const accent400 = Color(0xFF05A357);
  static const accent500 = Color(0xFF34A853);
  static const accent600 = Color(0xFF2F994C);
  static const accent700 = Color(0xFF25773B);
  static const accent800 = Color(0xFF1D5C2E);
  static const accent900 = Color(0xFF164723);

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

  // --- Semantic (Figma 215:1135 + app-wide) ---
  /// Main CTA — Switched to Brutalist Red.
  static const primary = brutalistRed;
  static const primaryDark = primary700;
  static const primaryLight = primary100;

  static const surface = white50;
  static const background = gray100;
  static const border = gray500;
  static const borderStrong = gray600;

  static const textPrimary = black500;
  static const textSecondary = black300;
  static const textDisabled = gray800;
  static const onPrimary = white50;

  static const success = accent600;
  static const successLight = accent50;
  static const warning = Color(0xFFE9C46A);
  static const warningLight = Color(0xFFFFF9E5);
  static const error = Color(0xFFD62828);
  static const errorLight = Color(0xFFFFEBEE);
  static const info = blue600;
  static const infoLight = blue50;

  /// Figma input fill (#EEEEEE).
  static const inputFill = gray500;
  static const inputPlaceholder = Color(0xFF7F7F7F);
  static const inputFocusBorder = black500;

  /// Alt search bar shadow (0 1 4 rgba(0,0,0,0.25)).
  static const searchBarShadow = Color(0x40000000);

  // --- Brutalist / Custom Accents ---
  static const brutalistRed = Color(0xFFD21F3C);
  static const brutalistYellow = Color(0xFFFABD00);
}
