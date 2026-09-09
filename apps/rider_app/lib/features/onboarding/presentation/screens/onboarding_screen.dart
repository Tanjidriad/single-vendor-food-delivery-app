import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rider_app/core/theme/app_colors.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/inputs/app_otp_input.dart';
import '../../../../core/widgets/layouts/clean_auth_scaffold.dart';
import '../../data/onboarding_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();


  final _vehicleTypeCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _vehicleRegCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();

  final Map<RiderDocType, String> _docs = {};

  bool _busy = false;
  bool _registered = false;
  String? _error;

  String _otp = '';
  bool _sendingOtp = false;
  String? _devCode;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _vehicleRegCtrl.dispose();
    _zoneCtrl.dispose();
    super.dispose();
  }

  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);

  void _nextStep(int step) {
    setState(() {
      _step = step;
      _error = null;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_sendingOtp) return;
    setState(() {
      _sendingOtp = true;
      _error = null;
    });
    try {
      final email = _emailCtrl.text.trim();
      final devCode = await _repo.sendEmailOtp(email);
      if (mounted) {
        setState(() => _devCode = devCode);
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      setState(() => _error = 'Please enter the 6-digit verification code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _emailCtrl.text.trim();
      await _repo.verifyEmailOtp(email, _otp);
      if (mounted) {
        _nextStep(2);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitPersonalAndRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (name.length < 2) {
      setState(() => _error = 'Please enter your full name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    if (phone.length < 11 ||
        !phone.startsWith('+880') && !phone.startsWith('01')) {
      setState(
        () => _error =
            'Please enter a valid Bangladeshi phone number (e.g. +880...)',
      );
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_registered) {
        await _repo.register(
          fullName: name,
          email: email,
          phone: phone,
          password: password,
        );
        _registered = true;
      }
      if (mounted) {
        unawaited(_sendOtp());
        _nextStep(1);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDocument(RiderDocType type) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() {
        _busy = true;
        _error = null;
      });
      await _repo.uploadDocument(
        type: type,
        filePath: picked.path,
        fileName: picked.name,
      );
      if (mounted) setState(() => _docs[type] = picked.path);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitWorkDetails() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.updateWorkDetails(
        vehicleType: _vehicleTypeCtrl.text.trim(),
        vehicleModel: _vehicleModelCtrl.text.trim(),
        vehicleRegistration: _vehicleRegCtrl.text.trim(),
        zone: _zoneCtrl.text.trim(),
      );
      if (mounted) _nextStep(4);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    String subtitle = '';
    Widget content = const SizedBox();
    Widget? footer;

    switch (_step) {
      case 0:
        title = 'Sign up Account';
        subtitle = 'Join now for a faster, smarter\ndelivering experience.';
        content = _personalStep();
        footer = _LoginFooter(busy: _busy);
        break;
      case 1:
        title = 'Email Verification';
        subtitle =
            'Enter the 6-digit code sent to\nyour email address ${_emailCtrl.text}';
        content = _otpStep();
        break;
      case 2:
        title = 'Upload Documents';
        subtitle = 'Please provide clear photos of\nyour required documents.';
        content = _documentsStep();
        break;
      case 3:
        title = 'Work Details';
        subtitle = 'Tell us about your vehicle and\nwhere you want to ride.';
        content = _workDetailsStep();
        break;
      case 4:
        title = 'Verification Pending';
        subtitle =
            'Check your email. We will notify you once\nyour application is approved.';
        content = _VerificationStep(
          onDone: () async {
            await _repo.clearSession();
            if (context.mounted) context.go(RoutePaths.login);
          },
        );
        break;
    }

    return CleanAuthScaffold(
      title: title,
      subtitle: subtitle,
      showBack: _step > 0 && _step < 4,
      onBack: _step > 0 && _step < 4 ? () => _nextStep(_step - 1) : null,
      footer: footer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: (_step + 1) / 5,
              minHeight: 4,
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(key: ValueKey<int>(_step), child: content),
          ),
        ],
      ),
    );
  }

  // ── Steps ────────────────────────────────────────────────────────────────
  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Name',
          hint: 'Enter your name',
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Email Address',
          hint: 'Enter your email',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Phone Number',
          hint: '+880...',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Password',
          hint: 'Enter your password',
          controller: _passwordCtrl,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 32),
        AppPrimaryButton(
          text: 'Sign up',
          isLoading: _busy,
          onPressed: _submitPersonalAndRegister,
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kDebugMode && _devCode != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dev mode — use code: $_devCode',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        AppOtpInput(
          length: 6,
          onChanged: (v) => setState(() => _otp = v),
          onCompleted: (v) {
            setState(() => _otp = v);
            _verifyOtp();
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't receive a code? ",
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            GestureDetector(
              onTap: _secondsLeft == 0 && !_sendingOtp ? _sendOtp : null,
              child: Text(
                _secondsLeft > 0 ? 'Resend in ${_secondsLeft}s' : 'Resend',
                style: TextStyle(
                  color: _secondsLeft == 0 && !_sendingOtp
                      ? AppColors.primary
                      : const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 32),
        AppPrimaryButton(
          text: 'Verify & Continue',
          isLoading: _busy,
          onPressed: (_busy || _otp.length != 6) ? null : _verifyOtp,
        ),
      ],
    );
  }

  Widget _documentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < RiderDocType.values.length; i++) ...[
          _DocTile(
            label: RiderDocType.values[i].label,
            uploaded: _docs.containsKey(RiderDocType.values[i]),
            onTap: _busy ? null : () => _pickDocument(RiderDocType.values[i]),
          ),
          if (i < RiderDocType.values.length - 1) const SizedBox(height: 16),
        ],
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 32),
        AppPrimaryButton(
          text: _docs.isEmpty ? 'Skip for now' : 'Continue',
          isLoading: _busy,
          onPressed: () => _nextStep(3),
        ),
      ],
    );
  }

  Widget _workDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Vehicle Type',
          hint: 'e.g. Bike, Car',
          controller: _vehicleTypeCtrl,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Vehicle Model',
          hint: 'e.g. Honda CB125',
          controller: _vehicleModelCtrl,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Registration Number (Optional)',
          hint: 'Leave blank for bicycles',
          controller: _vehicleRegCtrl,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Preferred Zone',
          hint: 'e.g. Dhanmondi',
          controller: _zoneCtrl,
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 32),
        AppPrimaryButton(
          text: 'Submit Application',
          isLoading: _busy,
          onPressed: _submitWorkDetails,
        ),
      ],
    );
  }
}

// ── Shared UI ─────────────────────────────────────────────────────────────
class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.label,
    required this.uploaded,
    required this.onTap,
  });
  final String label;
  final bool uploaded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = uploaded ? const Color(0xFF10B981) : Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), // Gray fill like inputs
          border: Border.all(
            color: uploaded ? color : Colors.transparent,
            width: uploaded ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              uploaded ? LucideIcons.checkCircle2 : LucideIcons.upload,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            Text(
              uploaded ? 'Uploaded' : 'Upload',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circleAlert,
            size: 16,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              const Icon(LucideIcons.clock, size: 48, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Application submitted',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We will review your documents and notify you when approved.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        AppPrimaryButton(text: 'Back to login', onPressed: onDone),
      ],
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter({required this.busy});
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account? ",
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        GestureDetector(
          onTap: busy ? null : () => context.go(RoutePaths.login),
          child: const Text(
            "Log in",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
