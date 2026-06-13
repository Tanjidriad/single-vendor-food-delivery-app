import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../buttons/app_button.dart';

/// CWT success layout — order placed, account verified, etc.
class AppSuccessScreen extends StatelessWidget {
  const AppSuccessScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onContinue,
    this.continueLabel = 'Continue',
    this.icon = Icons.check_circle_rounded,
  });

  final String title;
  final String subtitle;
  final String continueLabel;
  final VoidCallback onContinue;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, top + AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Icon(icon, size: 120, color: AppColors.primary),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              AppButton(
                label: continueLabel,
                onPressed: onContinue,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
