import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback/auth_error_sheet.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/layouts/clean_auth_scaffold.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(); // Or phone, but keeping text generalized
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty) {
      _showErrorBottomSheet('Please enter your email or phone number.');
      return;
    }
    if (password.isEmpty) {
      _showErrorBottomSheet('Please enter your password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authProvider.notifier).login(
            identifier,
            password,
          );

      if (success && mounted) {
        context.go(RoutePaths.home);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorBottomSheet(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorBottomSheet(String message) {
    final cleanMessage = message.replaceAll('Exception: ', '');
    final isPending = cleanMessage.contains('pending admin approval');
    AuthErrorSheet.show(
      context,
      title: isPending ? 'Account Under Review' : 'Login Failed',
      message: cleanMessage,
      isPending: isPending,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CleanAuthScaffold(
      title: 'Welcome back',
      subtitle: 'Access your orders, wishlist, and\nexclusive offers by logging in.',
      showBack: false,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          GestureDetector(
            onTap: _isLoading ? null : () => context.push(RoutePaths.onboarding),
            child: Text(
              'Sign up',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Email / Phone',
            hint: 'Enter your email or phone',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(RoutePaths.forgotPassword),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot password?',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          AppPrimaryButton(
            text: 'Sign in',
            isLoading: _isLoading,
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }
}
