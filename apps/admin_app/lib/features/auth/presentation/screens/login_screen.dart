import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/w_button.dart';
import '../../providers/auth_provider.dart';

/// Validates an email string for the login form (Requirement 19.6, Property 13).
///
/// Returns `true` if and only if [value] is non-empty and contains at least one
/// `@` character followed by at least one `.` character, with at least one
/// character between the `@` and the `.` and at least one character after the
/// `.`. Empty strings and strings without this pattern are rejected.
///
/// Exposed as a top-level, side-effect-free function so it can be imported and
/// exercised directly by property-based tests.
bool isValidEmail(String value) {
  if (value.isEmpty) return false;

  final atIndex = value.indexOf('@');
  if (atIndex < 0) return false;

  // The dot must appear at least two positions after the `@` so that there is
  // at least one character between the `@` and the `.`. If there aren't enough
  // characters after the `@` for a `.x` suffix, reject without searching —
  // `String.indexOf` throws a RangeError when the start index exceeds the
  // string length (e.g. trailing-`@` inputs such as "c.a@").
  final dotStart = atIndex + 2;
  if (dotStart > value.length) return false;

  final dotIndex = value.indexOf('.', dotStart);
  if (dotIndex < 0) return false;

  // There must be at least one character after the dot.
  if (dotIndex >= value.length - 1) return false;

  return true;
}

/// The Wasabi Admin login screen.
///
/// Presents a dark gradient background with a centered glassmorphic card
/// (backdrop blur, semi-transparent fill, 1px border at 10% white opacity) and
/// the brand mark above the form title (Requirement 19.1, 19.2). All visual
/// values are sourced from the design token system and every translucent color
/// uses [Color.withValues] (Requirement 19.3).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  /// Inline validation error for the email field.
  String? _emailError;

  /// Inline validation error for the password field.
  String? _passwordError;

  /// Server-side credential error shown below the form fields. Remains visible
  /// until the user modifies either input field or resubmits (Requirement 19.4).
  String? _credentialError;

  /// Fixed dark gradient backdrop for the login surface. Intentionally
  /// independent of the active light/dark theme.
  static const _backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const double _cardWidth = 400;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Resubmitting clears any previous credential error (Requirement 19.4).
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = isValidEmail(email)
        ? null
        : email.isEmpty
            ? 'Please enter your email'
            : 'Please enter a valid email';
    final passwordError =
        password.isEmpty ? 'Please enter your password' : null;

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _credentialError = null;
    });

    // Do not submit if validation fails (Requirement 19.7).
    if (emailError != null || passwordError != null) return;

    ref.read(authProvider.notifier).login(email, password);
  }

  void _onEmailChanged(String _) {
    if (_emailError != null || _credentialError != null) {
      setState(() {
        _emailError = null;
        _credentialError = null;
      });
    }
  }

  void _onPasswordChanged(String _) {
    if (_passwordError != null || _credentialError != null) {
      setState(() {
        _passwordError = null;
        _credentialError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState == AuthState.loading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next == AuthState.error) {
        final error = ref.read(authProvider.notifier).errorMessage;
        if (error != null && mounted) {
          setState(() => _credentialError = error);
        }
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.xxl),
            child: _buildGlassCard(context, isLoading),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, bool isLoading) {
    return ClipRRect(
      borderRadius: RadiusTokens.borderRadiusXxl,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: _cardWidth,
          padding: const EdgeInsets.all(SpacingTokens.xxxxl),
          decoration: BoxDecoration(
            // Semi-transparent fill for the glassmorphic surface.
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: RadiusTokens.borderRadiusXxl,
            // 1px border at 10% white opacity (Requirement 19.1).
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: _buildForm(context, isLoading),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand mark above the form title (Requirement 19.1).
        Center(
          child: Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: colors.primary,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: SpacingTokens.xxl),
        Text(
          'Wasabi Admin',
          textAlign: TextAlign.center,
          style: typography.style(
            size: TypographyTokens.xxxl,
            weight: TypographyTokens.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Welcome back, please log in to continue.',
          textAlign: TextAlign.center,
          style: typography.style(
            size: TypographyTokens.md,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: SpacingTokens.xxxxl),

        // Email field
        _buildTextField(
          context: context,
          controller: _emailController,
          hint: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onChanged: _onEmailChanged,
          errorText: _emailError,
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Password field
        _buildTextField(
          context: context,
          controller: _passwordController,
          hint: 'Password',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          onChanged: _onPasswordChanged,
          errorText: _passwordError,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        // Credential error below the form fields (Requirement 19.4).
        if (_credentialError != null) ...[
          const SizedBox(height: SpacingTokens.lg),
          Text(
            _credentialError!,
            textAlign: TextAlign.center,
            style: typography.style(
              size: TypographyTokens.md, // 14px
              color: colors.error,
            ),
          ),
        ],
        const SizedBox(height: SpacingTokens.xxxxl),

        // Submit button (loading state replaces the label with a spinner and
        // disables interaction — Requirement 19.5).
        SizedBox(
          width: double.infinity,
          child: WButton(
            label: 'Sign In',
            size: WButtonSize.lg,
            isLoading: isLoading,
            isDisabled: isLoading,
            onPressed: _handleLogin,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    String? errorText,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final whiteBorder = Colors.white.withValues(alpha: 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscure,
          keyboardType: keyboardType,
          cursorColor: colors.primary,
          style: typography.style(
            size: TypographyTokens.md,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: typography.style(
              size: TypographyTokens.md,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: RadiusTokens.borderRadiusMd,
              borderSide: BorderSide(color: whiteBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: RadiusTokens.borderRadiusMd,
              borderSide: BorderSide(color: whiteBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: RadiusTokens.borderRadiusMd,
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: SpacingTokens.xs),
          Text(
            errorText,
            style: typography.style(
              size: TypographyTokens.md, // 14px (Requirement 19.4)
              color: colors.error,
            ),
          ),
        ],
      ],
    );
  }
}
