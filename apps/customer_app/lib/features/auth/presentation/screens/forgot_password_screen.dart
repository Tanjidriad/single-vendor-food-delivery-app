import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/utils/validators/validation.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetOtp(
            email: _emailController.text.trim(),
          );
      if (!mounted) return;
      context.go(
        RoutePaths.resetPasswordWithEmail(_emailController.text.trim()),
      );
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(
          context,
          title: 'Request failed',
          message: authErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Headings
              Text('Forgot password', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                'Don\'t worry sometimes people can forget too, enter your email and we will send you a password reset link.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 32),

              /// Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _emailController,
                      label: 'E-Mail',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Iconsax.direct_right, size: 20, color: AppColors.textSecondary),
                      validator: AppValidator.validateEmail,
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Submit',
                      isLoading: _sending,
                      onPressed: _sending ? null : _submit,
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
