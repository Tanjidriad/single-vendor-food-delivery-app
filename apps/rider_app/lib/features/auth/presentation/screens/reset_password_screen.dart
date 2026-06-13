import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_otp_input.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/layouts/clean_auth_scaffold.dart';
import '../../data/auth_repository.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  String _otp = '';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_otp.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code');
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: widget.email,
            code: _otp,
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Color(0xFF10B981)),
      );
      // Go back to login screen
      context.go(RoutePaths.login);
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
      title: 'Reset password',
      subtitle: 'Enter the code sent to ${widget.email}',
      showBack: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppOtpInput(
            length: 6,
            onChanged: (v) => _otp = v,
            onCompleted: (v) => _otp = v,
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _passwordController,
            label: 'New password',
            hint: 'At least 8 characters',
            obscureText: true,
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
            text: 'Update password',
            isLoading: _loading,
            onPressed: _loading ? null : _reset,
          ),
        ],
      ),
    );
  }
}
