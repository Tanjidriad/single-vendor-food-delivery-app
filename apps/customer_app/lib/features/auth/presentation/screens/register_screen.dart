import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/utils/validators/validation.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/utils/popups/full_screen_loader.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  PhoneNumber? _phoneNumber;
  bool _privacyAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showPolicySheet(String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            AppButton(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_privacyAccepted) {
      AppLoaders.errorSnackBar(
        context,
        title: 'Consent required',
        message: 'Please accept the Privacy Policy and Terms of Use.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_phoneNumber == null || _phoneNumber!.number.isEmpty) {
      AppLoaders.errorSnackBar(
        context,
        title: 'Invalid number',
        message: 'Please enter a valid Bangladeshi phone number.',
      );
      return;
    }

    AppFullScreenLoader.openLoadingDialog(
      context,
      'Creating your account…',
      'assets/images/141397-loading-juggle.json',
    );

    await ref.read(authControllerProvider.notifier).phoneRegister(
          _phoneNumber!.completeNumber,
          _nameController.text.trim(),
        );

    if (!mounted) return;
    AppFullScreenLoader.stopLoading(context);

    ref.read(authControllerProvider).whenOrNull(
      data: (_) => context.go(RoutePaths.home),
      error: (e, _) => AppLoaders.errorSnackBar(
        context,
        title: 'Registration failed',
        message: authErrorMessage(e),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final linkStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RoutePaths.login),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Let's create your account",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      prefixIcon: const Icon(
                        Iconsax.user,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      validator: (v) => AppValidator.validateEmptyText('Name', v),
                    ),
                    const SizedBox(height: 16),
                    IntlPhoneField(
                      initialCountryCode: 'BD',
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        counterText: '',
                      ),
                      onChanged: (phone) => _phoneNumber = phone,
                      onCountryChanged: (_) => _phoneNumber = null,
                      validator: (phone) {
                        if (phone == null || phone.number.isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                      invalidNumberMessage: 'Invalid Bangladeshi phone number',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _privacyAccepted,
                            onChanged: isLoading
                                ? null
                                : (value) => setState(
                                      () => _privacyAccepted = value ?? false,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: Theme.of(context).textTheme.bodySmall,
                              children: [
                                const TextSpan(text: 'I agree to '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: linkStyle,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showPolicySheet(
                                          'Privacy Policy',
                                          'We collect account and order information to deliver food, process payments, and improve our service. We do not sell your personal data. Contact support for data requests.',
                                        ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Terms of Use',
                                  style: linkStyle,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showPolicySheet(
                                          'Terms of Use',
                                          'By using WASABI you agree to place accurate orders, pay for items you request, and treat riders and restaurant staff respectfully. Prices and availability may change.',
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Create Account',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
