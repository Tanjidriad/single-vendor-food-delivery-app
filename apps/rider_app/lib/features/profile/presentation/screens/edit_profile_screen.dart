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
import '../widgets/profile_ui_primitives.dart';

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
          'Edit profile',
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
                  radius: 40,
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
              const ProfileSectionLabel(label: 'Personal'),
              _FilledField(
                label: 'Full name',
                controller: _nameCtrl,
                hint: 'Your full name',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.sm),
              _LockedField(
                label: 'Phone',
                value: profile.phone ?? '—',
              ),
              const SizedBox(height: AppSpacing.section),
              const ProfileSectionLabel(label: 'Vehicle'),
              _FilledField(
                label: 'Vehicle type',
                controller: _vehicleTypeCtrl,
                hint: 'e.g. Motorcycle',
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FilledField(
                      label: 'Model',
                      controller: _vehicleModelCtrl,
                      hint: 'e.g. TVS Apache',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _FilledField(
                      label: 'Plate no.',
                      controller: _plateCtrl,
                      hint: 'DHK-L-12-3456',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _FilledField(
                label: 'Zone',
                controller: _zoneCtrl,
                hint: 'Your primary zone',
                suffixIcon: const Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  top: AppSpacing.sm,
                ),
                child: Text(
                  'Zone changes apply after your current shift ends.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Filled white field with the label floating inside the card, matching the
/// grouped-card look of the profile screen.
class _FilledField extends StatelessWidget {
  const _FilledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: AppColors.textDisabled,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        suffixIcon: suffixIcon,
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.primary, width: 1.5),
      ),
    );
  }
}

/// Read-only field for values that can't be edited in-app (login identity).
class _LockedField extends StatelessWidget {
  const _LockedField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.lock,
            size: 16,
            color: AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}
