import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme_extension.dart';
import 'tokens/app_tokens.dart';

/// Central theme factory for the Wasabi Admin Panel.
///
/// Builds token-driven [ThemeData] instances for light and dark modes. Each
/// theme registers an [AppThemeExtension] so widgets can read the active design
/// tokens via `context.tokens`.
class AppTheme {
  AppTheme._();

  /// Light theme built from [AppTokens.light].
  static ThemeData get lightTheme =>
      _buildTheme(AppTokens.light, Brightness.light, AppThemeExtension.light);

  /// Dark theme built from [AppTokens.dark].
  static ThemeData get darkTheme =>
      _buildTheme(AppTokens.dark, Brightness.dark, AppThemeExtension.dark);

  /// Builds a [ThemeData] from the supplied design [tokens].
  static ThemeData _buildTheme(
    AppTokens tokens,
    Brightness brightness,
    AppThemeExtension extension,
  ) {
    final colors = tokens.colors;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryLight,
      onPrimaryContainer: colors.primaryDark,
      secondary: colors.primary,
      onSecondary: colors.onPrimary,
      error: colors.error,
      onError: colors.onPrimary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.gray100,
      outline: colors.border,
      outlineVariant: colors.borderStrong,
    );

    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme)
        .apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.surface,
      dividerColor: colors.border,
      textTheme: textTheme,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      inputDecorationTheme: _inputDecorationTheme(tokens),
      extensions: <ThemeExtension<dynamic>>[extension],
    );
  }

  /// Token-driven input decoration theme shared across both modes.
  static InputDecorationTheme _inputDecorationTheme(AppTokens tokens) {
    final colors = tokens.colors;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: RadiusTokens.borderRadiusMd,
          borderSide: BorderSide(width: width, color: color),
        );

    return InputDecorationTheme(
      errorMaxLines: 2,
      prefixIconColor: colors.textSecondary,
      suffixIconColor: colors.textSecondary,
      labelStyle: TextStyle(
        fontSize: TypographyTokens.md,
        color: colors.textPrimary,
        fontWeight: TypographyTokens.medium,
      ),
      hintStyle: TextStyle(
        fontSize: TypographyTokens.base,
        color: colors.textSecondary,
      ),
      errorStyle: TextStyle(
        fontSize: TypographyTokens.xs,
        color: colors.error,
      ),
      floatingLabelStyle: TextStyle(color: colors.textSecondary),
      border: border(colors.border, 1),
      enabledBorder: border(colors.border, 1),
      focusedBorder: border(colors.primary, 2),
      errorBorder: border(colors.error, 1),
      focusedErrorBorder: border(colors.error, 2),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.md,
      ),
    );
  }
}
