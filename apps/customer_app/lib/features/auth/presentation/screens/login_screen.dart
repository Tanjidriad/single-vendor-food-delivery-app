import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cwt/cwt_auth_widgets.dart';
import '../../../../core/utils/popups/full_screen_loader.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  PhoneNumber? _phoneNumber;

  Future<void> _submit() async {
    // IntlPhoneField's built-in length check runs inside validate() and shows
    // its own inline error, so we only need to guard against a null number.
    if (!_formKey.currentState!.validate() || _phoneNumber == null) {
      return;
    }

    final phone = _phoneNumber!.completeNumber;

    AppFullScreenLoader.openLoadingDialog(
      context,
      'Sending verification code…',
      'assets/images/141397-loading-juggle.json',
    );

    try {
      await ref.read(authRepositoryProvider).sendPhoneLoginOtp(phone: phone);
      if (!mounted) return;
      AppFullScreenLoader.stopLoading(context);
      unawaited(context.push(RoutePaths.phoneOtpWithPhone(phone)));
    } catch (e) {
      if (!mounted) return;
      AppFullScreenLoader.stopLoading(context);
      AppLoaders.errorSnackBar(
        context,
        title: 'Could not send code',
        message: authErrorMessage(e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CwtLoginHeader()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Enter your phone number',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      IntlPhoneField(
                        initialCountryCode: 'BD',
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          counterText: '',
                        ),
                        onChanged: (phone) => _phoneNumber = phone,
                        onSaved: (phone) => _phoneNumber = phone,
                        invalidNumberMessage: 'Invalid Bangladeshi phone number',
                      )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 400.ms)
                          .slideY(begin: 0.08, end: 0, delay: 100.ms, duration: 400.ms, curve: Curves.easeOut),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Send OTP',
                        onPressed: _submit,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.08, end: 0, delay: 200.ms, duration: 400.ms, curve: Curves.easeOut),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                          ),
                          onPressed: () => context.push(RoutePaths.register),
                          child: const Text('Create Account'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
