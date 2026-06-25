import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/success_snack.dart';
import '../../../../core/widgets/feedback/tab_loading_view.dart';
import '../../data/rider_profile.dart';
import '../../data/rider_profile_repository.dart';
import '../providers/rider_profile_provider.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _plateCtrl.dispose();
    _zoneCtrl.dispose();
    super.dispose();
  }

  void _seedFields(RiderProfileView profile) {
    if (_initialized) return;
    _nameCtrl.text = profile.fullName;
    _vehicleTypeCtrl.text = profile.vehicleType ?? '';
    _vehicleModelCtrl.text = profile.vehicleModel ?? '';
    _plateCtrl.text = profile.vehicleRegistration ?? '';
    _zoneCtrl.text = profile.zone ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(riderProfileRepositoryProvider);
      await repo.updateFullName(name);
      await repo.updateWorkDetails(
        vehicleType: _vehicleTypeCtrl.text.trim(),
        vehicleModel: _vehicleModelCtrl.text.trim(),
        vehicleRegistration: _plateCtrl.text.trim(),
        zone: _zoneCtrl.text.trim(),
      );
      ref.invalidate(riderProfileProvider);
      if (!mounted) return;
      SuccessSnack.show(context, 'Profile updated');
      context.pop();
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.offline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(riderProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.chevronLeft),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceLight,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save changes',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const TabLoadingView(),
        error: (err, _) => ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(riderProfileProvider),
        ),
        data: (profile) {
          _seedFields(profile);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.lg,
            ),
            children: [
              Center(
                child: ProfileAvatar(
                  fullName: profile.fullName,
                  avatarUrl: profile.avatarUrl,
                  radius: 44,
                  showCameraBadge: true,
                  onPhotoUpdated: () => ref.invalidate(riderProfileProvider),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Tap photo to update',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              _FormSection(
                icon: LucideIcons.user,
                title: 'Personal Information',
                child: _ProfileField(
                  label: 'Full name',
                  controller: _nameCtrl,
                  hint: 'Your full name',
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              _FormSection(
                icon: LucideIcons.briefcase,
                title: 'Work Details',
                child: Column(
                  children: [
                    _ProfileField(
                      label: 'Vehicle type',
                      controller: _vehicleTypeCtrl,
                      hint: 'e.g. Motorcycle',
                      showChevron: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ProfileField(
                      label: 'Vehicle model',
                      controller: _vehicleModelCtrl,
                      hint: 'e.g. Honda CB150',
                      showChevron: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ProfileField(
                      label: 'Registration / plate',
                      controller: _plateCtrl,
                      hint: 'Plate number',
                      showChevron: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ProfileField(
                      label: 'Delivery zone',
                      controller: _zoneCtrl,
                      hint: 'Your primary zone',
                      showChevron: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        child,
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    required this.hint,
    this.showChevron = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            suffixIcon: showChevron
                ? const Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: AppColors.textDisabled,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
