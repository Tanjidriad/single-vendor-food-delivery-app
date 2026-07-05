import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// How far the stats card overlaps the crimson hero header.
const double _statsOverlap = 40;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
        data: (profile) => AnnotatedRegion<SystemUiOverlayStyle>(
          // White status-bar icons over the crimson hero.
          value: SystemUiOverlayStyle.light
              .copyWith(statusBarColor: Colors.transparent),
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(riderProfileProvider);
              ref.invalidate(profilePerformancePreviewProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _HeroHeader(
                        profile: profile,
                        performance: performance,
                        unreadCount: unreadCount,
                      ),
                      Positioned(
                        left: AppSpacing.screen,
                        right: AppSpacing.screen,
                        bottom: -_statsOverlap,
                        child: _StatsCard(performance: performance),
                      ),
                    ],
                  ),
                  const SizedBox(height: _statsOverlap + AppSpacing.section),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ProfileSectionLabel(label: 'Earnings'),
                        ProfileSectionCard(
                          child: Column(
                            children: [
                              ProfileMenuRow(
                                icon: LucideIcons.trophy,
                                iconColor: AppColors.primary,
                                iconBg: AppColors.primaryLight,
                                title: 'My performance',
                                subtitle: 'Stats, ratings & tips',
                                onTap: () =>
                                    context.push(RoutePaths.performance),
                              ),
                              ProfileMenuRow(
                                icon: LucideIcons.banknote,
                                iconColor: AppColors.primary,
                                iconBg: AppColors.primaryLight,
                                title: 'COD cash summary',
                                subtitle: 'Collected, remit & fees',
                                onTap: () => context.push(RoutePaths.cash),
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        const ProfileSectionLabel(label: 'Account'),
                        ProfileSectionCard(
                          child: Column(
                            children: [
                              ProfileMenuRow(
                                icon: LucideIcons.user,
                                iconColor: AppColors.textPrimary,
                                iconBg: AppColors.surfaceElevated,
                                title: 'Edit profile',
                                subtitle: 'Name, vehicle & zone',
                                onTap: () =>
                                    context.push(RoutePaths.profileEdit),
                              ),
                              ProfileMenuRow(
                                icon: LucideIcons.fileText,
                                iconColor: AppColors.textPrimary,
                                iconBg: AppColors.surfaceElevated,
                                title: 'Documents',
                                subtitle: 'NID, licence & registration',
                                trailing: _documentsBadge(profile),
                                onTap: () =>
                                    context.push(RoutePaths.profileDocuments),
                              ),
                              ProfileMenuRow(
                                icon: LucideIcons.bell,
                                iconColor: AppColors.textPrimary,
                                iconBg: AppColors.surfaceElevated,
                                title: 'Notifications',
                                subtitle: 'Delivery alerts & updates',
                                trailing: unreadCount > 0
                                    ? LabelChip(
                                        label: '$unreadCount',
                                        color: AppColors.primary,
                                      )
                                    : null,
                                onTap: () =>
                                    context.push(RoutePaths.notifications),
                              ),
                              ProfileMenuRow(
                                icon: LucideIcons.lifeBuoy,
                                iconColor: AppColors.textPrimary,
                                iconBg: AppColors.surfaceElevated,
                                title: 'Help center',
                                subtitle: 'FAQs & support',
                                onTap: () => context.push(RoutePaths.help),
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _LogoutCard(onTap: () => _onLogout(context, ref)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Status badge for the Documents row, summarising all uploads.
  static Widget? _documentsBadge(RiderProfileView profile) {
    final docs = profile.documents;
    if (docs.any((d) => d.status == 'REJECTED')) {
      return const LabelChip(label: 'Action needed', color: AppColors.offline);
    }
    final pending = docs.where((d) => d.status == 'PENDING').length;
    if (pending > 0) {
      return LabelChip(label: '$pending in review', color: AppColors.busy);
    }
    final complete = docs.length >= RiderDocType.values.length &&
        docs.every((d) => d.status == 'APPROVED');
    if (complete) {
      return const LabelChip(label: 'Verified', color: AppColors.online);
    }
    if (docs.isEmpty) {
      return const LabelChip(label: 'Missing', color: AppColors.neutral);
    }
    return const LabelChip(label: 'Incomplete', color: AppColors.neutral);
  }

  Future<void> _onLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title:
            const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
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

/// Full-bleed crimson header: screen title, notification bell, and the rider's
/// identity (avatar, name, phone, status + rating chips).
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.profile,
    required this.performance,
    required this.unreadCount,
  });

  final RiderProfileView profile;
  final PerformanceSummary? performance;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rating = profile.ratingAvg ?? performance?.ratingAvg;
    final trips = performance?.deliveries ?? 0;

    final (IconData statusIcon, String statusLabel) =
        switch (profile.approvalStatus) {
      'APPROVED' => (LucideIcons.shieldCheck, 'Active rider'),
      'REJECTED' => (LucideIcons.circleAlert, 'Rejected'),
      'SUSPENDED' => (LucideIcons.circleAlert, 'Suspended'),
      _ => (LucideIcons.clock, 'Pending approval'),
    };

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl + _statsOverlap),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Account',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  _BellButton(unreadCount: unreadCount),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: () => context.push(RoutePaths.profileEdit),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Row(
                  children: [
                    ProfileAvatar(
                      fullName: profile.fullName,
                      avatarUrl: profile.avatarUrl,
                      radius: 28,
                      showCameraBadge: false,
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
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (profile.phone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              profile.phone!,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _HeroChip(icon: statusIcon, label: statusLabel),
                              if (rating != null)
                                _HeroChip(
                                  icon: LucideIcons.star,
                                  label: trips > 0
                                      ? '${rating.toStringAsFixed(2)} · $trips trips'
                                      : rating.toStringAsFixed(2),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: Colors.white70,
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

/// Frosted white pill on the crimson header.
class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => context.push(RoutePaths.notifications),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          icon: const Icon(LucideIcons.bell, size: 20, color: Colors.white),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

/// White card floating over the header seam with the three key rates.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.performance});

  final PerformanceSummary? performance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        children: [
          _StatCell(
            value: performance != null ? '${performance!.completionRate}%' : '—',
            label: 'Completion',
          ),
          const _StatDivider(),
          _StatCell(
            value: performance != null ? '${performance!.acceptanceRate}%' : '—',
            label: 'Acceptance',
          ),
          const _StatDivider(),
          _StatCell(
            value: performance != null ? '${performance!.onTimeRate}%' : '—',
            label: 'On-time',
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.borderLight);
  }
}

/// Quiet destructive row — deliberately not a primary-styled button.
class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  static const Color _dangerTint = Color(0xFFFEF2F2);

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _dangerTint,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child:
                    const Icon(LucideIcons.logOut, size: 20, color: AppColors.offline),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Log out',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.offline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
