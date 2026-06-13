import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers/helper_functions.dart';
import '../../../../core/widgets/feedback/empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../data/notifications_repository.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsListProvider);
    final isDark = AppHelperFunctions.isDarkMode(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.gray100,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Notifications',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: notifications.when(
        data: (list) {
          if (list.isEmpty) {
            return const AppEmptyState(
              title: 'All caught up',
              subtitle: 'Order updates and offers will show up here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = list[i] as Map<String, dynamic>;
                final read = n['readAt'] != null;
                final title = n['title'] as String? ?? 'Notification';
                final body = n['body'] as String? ?? '';
                final created = n['createdAt'] != null
                    ? DateTime.tryParse(n['createdAt'] as String)
                    : null;

                return Material(
                  color: isDark ? AppColors.black400 : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    onTap: () async {
                      if (!read) {
                        await ref
                            .read(notificationsRepositoryProvider)
                            .markRead(n['id'] as String);
                        ref.invalidate(notificationsListProvider);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: read
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : AppColors.border)
                              : AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(
                                alpha: isDark ? 0.2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Iconsax.notification,
                              color: read ? AppColors.textSecondary : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: read ? FontWeight.w600 : FontWeight.w800,
                                  ),
                                ),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppColors.white700
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                if (created != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    AppHelperFunctions.formatDate(created),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorState(
          message: friendlyErrorMessage(e),
          onRetry: () => ref.invalidate(notificationsListProvider),
        ),
      ),
    );
  }
}
