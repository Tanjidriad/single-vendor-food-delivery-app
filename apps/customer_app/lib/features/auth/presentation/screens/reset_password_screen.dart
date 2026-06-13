import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/utils/validators/validation.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/inputs/app_otp_input.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _otpCode = '';
  bool _isSubmitting = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_isResending || _resendCooldown > 0) return;
    setState(() => _isResending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetOtp(email: widget.email);
      if (mounted) {
        AppLoaders.successSnackBar(
          context,
          title: 'Code sent',
          message: 'Check your email for a new verification code.',
        );
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(
          context,
          title: 'Could not resend',
          message: authErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _submit() async {
    if (_otpCode.length != 6) {
      AppLoaders.errorSnackBar(
        context,
        title: 'Invalid code',
        message: 'Enter the 6-digit code from your email.',
      );
      return;
    }

    final passwordError =
        AppValidator.validatePassword(_passwordController.text);
    if (passwordError != null) {
      AppLoaders.errorSnackBar(
        context,
        title: 'Invalid password',
        message: passwordError,
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      AppLoaders.errorSnackBar(
        context,
        title: 'Passwords do not match',
        message: 'Please confirm your new password.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: widget.email,
            code: _otpCode,
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      AppLoaders.successSnackBar(
        context,
        title: 'Password updated',
        message: 'You can now sign in with your new password.',
      );
      context.go(RoutePaths.login);
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(
          context,
          title: 'Reset failed',
          message: authErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => context.go(RoutePaths.login),
            icon: const Icon(CupertinoIcons.clear),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/sammy-line-man-receives-a-mail.png',
                width: MediaQuery.of(context).size.width * 0.6,
                alignment: Alignment.center,
              ),
              const SizedBox(height: 32),
              Text(
                'Reset your password',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the verification code we sent to your email, then choose a new password.',
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppOtpInput(
                onCompleted: (code) => _otpCode = code,
                onChanged: (code) => _otpCode = code,
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _passwordController,
                label: 'New password',
                obscureText: true,
                showObscureToggle: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                obscureText: true,
                showObscureToggle: true,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Update password',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_isResending || _resendCooldown > 0)
                    ? null
                    : _resendOtp,
                child: Text(
                  _resendCooldown > 0
                      ? 'Resend code in ${_resendCooldown}s'
                      : _isResending
                          ? 'Sending…'
                          : 'Resend code',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
