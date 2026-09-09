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

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({super.key, required this.phone});

  /// E.164 formatted phone number e.g. +8801712345678
  final String phone;

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  String _otpCode = '';
  bool _isResending = false;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
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

  Future<void> _resend() async {
    if (_isResending || _resendCooldown > 0) return;
    setState(() => _isResending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPhoneLoginOtp(phone: widget.phone);
      if (mounted) {
        AppLoaders.successSnackBar(
          context,
          title: 'Code sent',
          message: 'Check your SMS for the new verification code.',
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

  Future<void> _verify() async {
    if (_otpCode.length != 6) {
      AppLoaders.errorSnackBar(
        context,
        title: 'Invalid code',
        message: 'Enter the 6-digit code from your SMS.',
      );
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .phoneLogin(widget.phone, _otpCode);

    if (!mounted) return;

    ref.read(authControllerProvider).whenOrNull(
      data: (_) => context.go(RoutePaths.home),
      error: (e, _) => AppLoaders.errorSnackBar(
        context,
        title: 'Verification failed',
        message: authErrorMessage(e),
      ),
    );
  }

  String get _maskedPhone {
    if (widget.phone.length < 5) return widget.phone;
    final visible = widget.phone.substring(widget.phone.length - 4);
    return '${widget.phone.substring(0, widget.phone.length - 7)}***$visible';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

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
                'Verify your phone',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _maskedPhone,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code we sent to your phone via SMS.',
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
                label: 'Verify',
                isLoading: isLoading,
                onPressed: isLoading ? null : _verify,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_isResending || _resendCooldown > 0) ? null : _resend,
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
