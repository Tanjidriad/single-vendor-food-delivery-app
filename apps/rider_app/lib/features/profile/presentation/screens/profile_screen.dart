import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../onboarding/data/onboarding_repository.dart';
import '../../data/rider_profile.dart';
import '../providers/rider_profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(riderProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Classic native settings background
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.textPrimary),
        ),
        backgroundColor: const Color(0xFFF1F5F9),
        elevation: 0,
        centerTitle: false,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(riderProfileProvider),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(riderProfileProvider),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20), // Edge-to-edge lists don't need horizontal padding here
            children: [
              _HeroIdentity(profile: profile),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('WORK DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
              ),
              _WorkDetailsGroup(profile: profile),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('DOCUMENTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
              ),
              _DocumentsGroup(profile: profile),
              const SizedBox(height: 32),
              _LogoutTile(onTap: () => _onLogout(context, ref)),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.offline,
            ),
            child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;

    if (success) {
      context.go(RoutePaths.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout failed. Please try again.'),
          backgroundColor: AppColors.offline,
        ),
      );
    }
  }
}

// ── Hero Identity ───────────────────────────────────────────────────────────
class _HeroIdentity extends StatelessWidget {
  const _HeroIdentity({required this.profile});

  final RiderProfileView profile;

  String get _initials {
    final parts = profile.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          alignment: Alignment.center,
          child: _initials.isEmpty
              ? const Icon(LucideIcons.user, size: 40, color: AppColors.primary)
              : Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        if (profile.phone != null) ...[
          const SizedBox(height: 4),
          Text(
            profile.phone!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _ApprovalBadge(status: profile.approvalStatus),
      ],
    );
  }
}

class _ApprovalBadge extends StatelessWidget {
  const _ApprovalBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label) = switch (status) {
      'APPROVED' => (const Color(0xFF10B981), LucideIcons.checkCircle2, 'Active Rider'),
      'REJECTED' => (AppColors.offline, LucideIcons.xCircle, 'Application Rejected'),
      'SUSPENDED' => (AppColors.offline, LucideIcons.ban, 'Account Suspended'),
      _ => (const Color(0xFFF59E0B), LucideIcons.clock, 'Pending Approval'),
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grouped List Container ──────────────────────────────────────────────────
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ── Work details ────────────────────────────────────────────────────────────
class _WorkDetailsGroup extends StatelessWidget {
  const _WorkDetailsGroup({required this.profile});

  final RiderProfileView profile;

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      children: [
        _SettingsRow(icon: LucideIcons.gauge, label: 'Vehicle', value: profile.vehicleType),
        const Divider(height: 1, indent: 48, color: Color(0xFFF1F5F9)),
        _SettingsRow(icon: LucideIcons.tag, label: 'Model', value: profile.vehicleModel),
        const Divider(height: 1, indent: 48, color: Color(0xFFF1F5F9)),
        _SettingsRow(icon: LucideIcons.hash, label: 'Plate', value: profile.vehicleRegistration),
        const Divider(height: 1, indent: 48, color: Color(0xFFF1F5F9)),
        _SettingsRow(icon: LucideIcons.map, label: 'Zone', value: profile.zone, isLast: true),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon, 
    required this.label, 
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            (value == null || value!.isEmpty) ? '—' : value!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Documents ─────────────────────────────────────────────────────────────
class _DocumentsGroup extends ConsumerStatefulWidget {
  const _DocumentsGroup({required this.profile});

  final RiderProfileView profile;

  @override
  ConsumerState<_DocumentsGroup> createState() => _DocumentsGroupState();
}

class _DocumentsGroupState extends ConsumerState<_DocumentsGroup> {
  RiderDocType? _uploading;

  Future<void> _upload(RiderDocType type) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _uploading = type);
      await ref.read(onboardingRepositoryProvider).uploadDocument(
            type: type,
            filePath: picked.path,
            fileName: picked.name,
          );
      ref.invalidate(riderProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.offline,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  String? _statusFor(String wireType) {
    for (final d in widget.profile.documents) {
      if (d.type == wireType) return d.status;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      children: [
        for (int i = 0; i < RiderDocType.values.length; i++) ...[
          _DocRow(
            label: RiderDocType.values[i].label,
            status: _statusFor(RiderDocType.values[i].wire),
            busy: _uploading == RiderDocType.values[i],
            onUpload: _uploading == null ? () => _upload(RiderDocType.values[i]) : null,
          ),
          if (i != RiderDocType.values.length - 1)
            const Divider(height: 1, indent: 48, color: Color(0xFFF1F5F9)),
        ],
      ],
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.label,
    required this.status,
    required this.busy,
    required this.onUpload,
  });

  final String label;
  final String? status;
  final bool busy;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final bool uploaded = status != null;
    final (Color color, String text) = switch (status) {
      'APPROVED' => (const Color(0xFF10B981), 'Approved'),
      'REJECTED' => (AppColors.offline, 'Rejected'),
      'PENDING' => (const Color(0xFFF59E0B), 'In review'),
      _ => (AppColors.textSecondary, 'Missing'),
    };

    return InkWell(
      onTap: onUpload,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                uploaded ? LucideIcons.fileCheck2 : LucideIcons.fileWarning,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else if (onUpload != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  uploaded ? 'Update' : 'Upload',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              const Icon(LucideIcons.chevronRight, size: 20, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

// ── Logout ───────────────────────────────────────────────────────────────
class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.logOut, size: 18, color: AppColors.offline),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(color: AppColors.offline, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
