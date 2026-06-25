import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/layouts/rider_stack_scaffold.dart';
import '../../../../core/widgets/layouts/section_header.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const _faqs = <(String, String)>[
    (
      'How do I go online and receive orders?',
      'Open the Home tab, toggle Go Online, and stay on the app. '
          'New delivery offers appear as full-screen alerts with a countdown timer.',
    ),
    (
      'How does COD cash work?',
      'For cash-on-delivery orders, collect the full amount from the customer. '
          'Remit the food portion to the restaurant and keep your delivery fee. '
          'See the COD Cash summary under Earnings for a breakdown.',
    ),
    (
      'How do I complete a delivery?',
      'At drop-off, ask the customer for their 4-digit OTP and enter it in the '
          'proof-of-delivery screen. You can optionally add a drop-off photo.',
    ),
    (
      'Why is my account pending approval?',
      'New riders must be approved by operations before going online. '
          'Upload all required documents in Profile and wait for approval.',
    ),
    (
      'What app permissions are required?',
      'Location (while using the app), notifications, and camera (for document '
          'upload and proof-of-delivery photos) help the app work correctly.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RiderStackScaffold(
      title: 'Help Center',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBright, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.glow(AppColors.primary),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.lifeBuoy, color: Colors.white, size: 36),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    'Need help on the road? Browse FAQs or contact dispatch.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(
            title: 'Frequently asked',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          ..._faqs.map(
            (faq) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _FaqTile(question: faq.$1, answer: faq.$2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            title: 'Contact',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          _ContactTile(
            icon: LucideIcons.phone,
            label: 'Call dispatch',
            subtitle: '+880 1XXX-XXXXXX',
            onTap: () => _launch(Uri.parse('tel:+8801000000000')),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactTile(
            icon: LucideIcons.mail,
            label: 'Email support',
            subtitle: 'support@fooddelivery.app',
            onTap: () => _launch(Uri.parse('mailto:support@fooddelivery.app')),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Center(
            child: Text(
              'Food Delivery Rider',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
