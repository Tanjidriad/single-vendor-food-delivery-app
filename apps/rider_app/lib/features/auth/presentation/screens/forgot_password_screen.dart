import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/layouts/clean_auth_scaffold.dart';
import '../../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final devCode = await ref.read(authRepositoryProvider).sendPasswordResetOtp(
            email: email,
          );
      if (!mounted) return;
      if (devCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dev OTP: $devCode'), backgroundColor: const Color(0xFFF59E0B)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent!'), backgroundColor: Color(0xFF10B981)),
        );
      }
      context.push('${RoutePaths.resetPassword}?email=${Uri.encodeComponent(email)}');
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CleanAuthScaffold(
      title: 'Forgot password?',
      subtitle: 'We will send a 6-digit code to your email to reset your password.',
      showBack: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'john@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 32),
          AppPrimaryButton(
            text: 'Send reset code',
            isLoading: _loading,
            onPressed: _loading ? null : _sendCode,
          ),
        ],
      ),
    );
  }
}
