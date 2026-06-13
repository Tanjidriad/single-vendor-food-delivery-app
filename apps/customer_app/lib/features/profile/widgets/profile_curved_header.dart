import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive/app_responsive.dart';
import '../../../core/widgets/shapes/app_primary_header_container.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// CWT-style curved header for the profile tab.
class ProfileCurvedHeader extends ConsumerWidget {
  const ProfileCurvedHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final pagePadding = AppResponsive.pagePadding(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final initial = (user?.fullName ?? user?.email ?? 'U').substring(0, 1).toUpperCase();

    return AppPrimaryHeaderContainer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(pagePadding, topInset + AppSpacing.lg, pagePadding, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My account',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.onPrimary,
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Guest',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user?.email != null && user!.email!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.email!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onPrimary.withValues(alpha: 0.85),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
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
