import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/local_storage/storage_utility.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/utils/validators/validation.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cwt/cwt_auth_widgets.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/utils/popups/full_screen_loader.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';

const _rememberMeKey = 'remember_me';
const _rememberMeEmailKey = 'remember_me_email';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRememberMe());
  }

  Future<void> _loadRememberMe() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final remember = prefs.getBool(_rememberMeKey) ?? false;
    final email = prefs.getString(_rememberMeEmailKey);
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember && email != null && email.isNotEmpty) {
        _emailController.text = email;
      }
    });
  }

  Future<void> _persistRememberMe(String email) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (_rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_rememberMeEmailKey, email);
    } else {
      await prefs.setBool(_rememberMeKey, false);
      await prefs.remove(_rememberMeEmailKey);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    AppFullScreenLoader.openLoadingDialog(
      context,
      'Logging you in...',
      'assets/images/141397-loading-juggle.json',
    );

    await ref.read(authControllerProvider.notifier).login(
          email,
          _passwordController.text,
        );

    if (!mounted) return;
    AppFullScreenLoader.stopLoading(context);

    ref.read(authControllerProvider).whenOrNull(
      data: (_) async {
        await _persistRememberMe(email);
        if (mounted) context.go(RoutePaths.home);
      },
      error: (e, _) => AppLoaders.errorSnackBar(
        context,
        title: 'Sign in failed',
        message: authErrorMessage(e),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CwtLoginHeader(),
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
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
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        obscureText: true,
                        showObscureToggle: true,
                        prefixIcon: const Icon(Iconsax.password_check, size: 20, color: AppColors.textSecondary),
                        validator: AppValidator.validatePassword,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: isLoading
                                    ? null
                                    : (value) => setState(
                                          () => _rememberMe = value ?? false,
                                        ),
                              ),
                              const Text('Remember Me'),
                            ],
                          ),
                          TextButton(
                            onPressed: () => context.push(RoutePaths.forgotPassword),
                            child: const Text('Forget Password?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Sign In',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _submit,
                      ),
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
