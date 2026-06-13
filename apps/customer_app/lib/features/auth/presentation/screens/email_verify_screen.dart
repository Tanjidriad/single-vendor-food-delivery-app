import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/inputs/app_otp_input.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';

class EmailVerifyScreen extends ConsumerStatefulWidget {
  const EmailVerifyScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends ConsumerState<EmailVerifyScreen> {
  String _otpCode = '';
  bool _isVerifying = false;
  bool _isResending = false;
  bool _verified = false;
  bool _sentInitialOtp = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendInitialOtp());
  }

  @override
  void dispose() {
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

  Future<void> _sendInitialOtp() async {
    if (_sentInitialOtp) return;
    _sentInitialOtp = true;
    await _sendOtp(showSuccess: false);
  }

  Future<void> _sendOtp({bool showSuccess = true}) async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendVerifyEmailOtp(email: widget.email);
      if (mounted) {
        if (showSuccess) {
          AppLoaders.successSnackBar(
            context,
            title: 'Code sent',
            message: 'Check your email for the verification code.',
          );
        }
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(
          context,
          title: 'Could not send code',
          message: authErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verify() async {
    if (_verified) {
      context.go(RoutePaths.home);
      return;
    }

    if (_otpCode.length != 6) {
      AppLoaders.errorSnackBar(
        context,
        title: 'Invalid code',
        message: 'Enter the 6-digit code from your email.',
      );
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await ref.read(authRepositoryProvider).verifyEmailOtp(
            email: widget.email,
            code: _otpCode,
          );
      if (!mounted) return;
      setState(() => _verified = true);
      AppLoaders.successSnackBar(
        context,
        title: 'Email verified',
        message: 'Your account is ready.',
      );
      context.go(RoutePaths.home);
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(
          context,
          title: 'Verification failed',
          message: authErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                'assets/images/sammy-line-travel-backpack-with-passport-and-air-ticket.gif',
                width: MediaQuery.of(context).size.width * 0.6,
                alignment: Alignment.center,
              ),
              const SizedBox(height: 32),
              Text(
                'Verify your email',
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
                'Enter the verification code we sent to your email to continue.',
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppOtpInput(
                onCompleted: (code) => _otpCode = code,
                onChanged: (code) => _otpCode = code,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _verified ? 'Continue' : 'Verify email',
                isLoading: _isVerifying,
                onPressed: _isVerifying ? null : _verify,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_isResending || _resendCooldown > 0)
                    ? null
                    : () => _sendOtp(),
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
