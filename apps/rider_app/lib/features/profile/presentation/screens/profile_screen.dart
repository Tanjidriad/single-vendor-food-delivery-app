import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/tab_loading_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../onboarding/data/onboarding_repository.dart';
import '../../../performance/data/performance_summary.dart';
import '../../../performance/presentation/providers/performance_provider.dart';
import '../../data/rider_profile.dart';
import '../providers/rider_profile_provider.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_ui_primitives.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _onTimePurple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(riderProfileProvider);
    final performanceAsync = ref.watch(profilePerformancePreviewProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final performance = performanceAsync.whenOrNull(data: (d) => d);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: profileAsync.when(
        loading: () => const TabLoadingView(),
        error: (err, _) => ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(riderProfileProvider),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(riderProfileProvider);
            ref.invalidate(profilePerformancePreviewProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(unreadCount: unreadCount),
                const SizedBox(height: AppSpacing.lg),
                _HeroCard(
                  profile: profile,
                  performance: performance,
                ),
                const SizedBox(height: AppSpacing.section),
                ProfileSectionHeader(
                  title: 'Work details',
                  actionLabel: 'Edit profile',
                  onAction: () => context.push(RoutePaths.profileEdit),
                ),
                const SizedBox(height: AppSpacing.md),
                _WorkDetailsCard(profile: profile),
                const SizedBox(height: AppSpacing.section),
                const ProfileSectionHeader(title: 'Documents'),
                const SizedBox(height: AppSpacing.md),
                _DocumentsCard(profile: profile),
                const SizedBox(height: AppSpacing.section),
                const ProfileSectionHeader(title: 'Account settings'),
                const SizedBox(height: AppSpacing.md),
                ProfileSectionCard(
                  child: Column(
                    children: [
                      ProfileMenuRow(
                        icon: LucideIcons.trophy,
                        iconColor: AppColors.primary,
                        iconBg: AppColors.primaryLight,
                        title: 'My performance',
                        subtitle: 'Stats, ratings & tips',
                        onTap: () => context.push(RoutePaths.performance),
                      ),
                      ProfileMenuRow(
                        icon: LucideIcons.banknote,
                        iconColor: AppColors.online,
                        iconBg: const Color(0xFFECFDF5),
                        title: 'COD cash summary',
                        subtitle: 'Collected, remit & fees',
                        onTap: () => context.push(RoutePaths.cash),
                      ),
                      ProfileMenuRow(
                        icon: LucideIcons.bell,
                        iconColor: AppColors.inProgress,
                        iconBg: const Color(0xFFEFF6FF),
                        title: 'Notifications',
                        subtitle: 'Delivery alerts & updates',
                        onTap: () => context.push(RoutePaths.notifications),
                      ),
                      ProfileMenuRow(
                        icon: LucideIcons.lifeBuoy,
                        iconColor: AppColors.busy,
                        iconBg: const Color(0xFFFFF7ED),
                        title: 'Help center',
                        subtitle: 'FAQs & support',
                        onTap: () => context.push(RoutePaths.help),
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _onLogout(context, ref),
                    icon: const Icon(LucideIcons.logOut, size: 18),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.offline),
            child: const Text('Log out'),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => context.push(RoutePaths.notifications),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  icon: const Icon(
                    LucideIcons.bell,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.performance,
  });

  final RiderProfileView profile;
  final PerformanceSummary? performance;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rating = profile.ratingAvg ?? performance?.ratingAvg;
    final trips = performance?.deliveries ?? 0;

    return ProfileSectionCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                fullName: profile.fullName,
                avatarUrl: profile.avatarUrl,
                showOnlineDot: true,
                isOnline: profile.isOnline,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.phone!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _ApprovalBadge(status: profile.approvalStatus),
                    if (rating != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      GestureDetector(
                        onTap: () => context.push(RoutePaths.performance),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.star,
                              size: 14,
                              color: AppColors.busy,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${rating.toStringAsFixed(2)}${trips > 0 ? ' ($trips trips)' : ''}',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push(RoutePaths.profileEdit),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  minimumSize: const Size(40, 40),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(
                  LucideIcons.pencil,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),
          Row(
            children: [
              ProfileMetricPill(
                icon: LucideIcons.packageCheck,
                iconColor: AppColors.online,
                iconBg: const Color(0xFFECFDF5),
                value: performance != null
                    ? '${performance!.completionRate}%'
                    : '—',
                label: 'Completion',
              ),
              const SizedBox(width: AppSpacing.sm),
              ProfileMetricPill(
                icon: LucideIcons.checkCheck,
                iconColor: AppColors.inProgress,
                iconBg: const Color(0xFFEFF6FF),
                value: performance != null
                    ? '${performance!.acceptanceRate}%'
                    : '—',
                label: 'Acceptance',
              ),
              const SizedBox(width: AppSpacing.sm),
              ProfileMetricPill(
                icon: LucideIcons.timer,
                iconColor: ProfileScreen._onTimePurple,
                iconBg: const Color(0xFFF3E8FF),
                value: performance != null
                    ? '${performance!.onTimeRate}%'
                    : '—',
                label: 'On-time',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkDetailsCard extends StatelessWidget {
  const _WorkDetailsCard({required this.profile});

  final RiderProfileView profile;

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!profile.hasWorkDetails)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                'Tap Edit profile to add your vehicle and zone.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ProfileDetailRow(
            icon: LucideIcons.bike,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryLight,
            label: 'Vehicle type',
            value: profile.vehicleType ?? '',
          ),
          ProfileDetailRow(
            icon: LucideIcons.tag,
            iconColor: AppColors.inProgress,
            iconBg: const Color(0xFFEFF6FF),
            label: 'Model',
            value: profile.vehicleModel ?? '',
          ),
          ProfileDetailRow(
            icon: LucideIcons.hash,
            iconColor: AppColors.busy,
            iconBg: const Color(0xFFFFF7ED),
            label: 'Plate number',
            value: profile.vehicleRegistration ?? '',
          ),
          ProfileDetailRow(
            icon: LucideIcons.mapPin,
            iconColor: AppColors.online,
            iconBg: const Color(0xFFECFDF5),
            label: 'Zone',
            value: profile.zone ?? '',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _ApprovalBadge extends StatelessWidget {
  const _ApprovalBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      'APPROVED' => (AppColors.online, 'Active Rider'),
      'REJECTED' => (AppColors.offline, 'Rejected'),
      'SUSPENDED' => (AppColors.offline, 'Suspended'),
      _ => (AppColors.busy, 'Pending Approval'),
    };

    return LabelChip(label: label, color: color);
  }
}

class _DocumentsCard extends ConsumerStatefulWidget {
  const _DocumentsCard({required this.profile});

  final RiderProfileView profile;

  @override
  ConsumerState<_DocumentsCard> createState() => _DocumentsCardState();
}

class _DocumentsCardState extends ConsumerState<_DocumentsCard> {
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
    return ProfileSectionCard(
      child: Column(
        children: [
          for (var i = 0; i < RiderDocType.values.length; i++)
            _DocumentRow(
              label: RiderDocType.values[i].label,
              status: _statusFor(RiderDocType.values[i].wire),
              busy: _uploading == RiderDocType.values[i],
              onTap: _uploading == null
                  ? () => _upload(RiderDocType.values[i])
                  : null,
              showDivider: i < RiderDocType.values.length - 1,
            ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.label,
    required this.status,
    required this.busy,
    required this.onTap,
    required this.showDivider,
  });

  final String label;
  final String? status;
  final bool busy;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final (Color color, String text) = switch (status) {
      'APPROVED' => (AppColors.online, 'Approved'),
      'REJECTED' => (AppColors.offline, 'Rejected'),
      'PENDING' => (AppColors.busy, 'In review'),
      _ => (AppColors.textSecondary, 'Missing'),
    };

    final needsUpload = status == null || status == 'REJECTED';

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else ...[
                  LabelChip(label: text, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    needsUpload
                        ? LucideIcons.cloudUpload
                        : LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textDisabled,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.borderLight),
      ],
    );
  }
}
