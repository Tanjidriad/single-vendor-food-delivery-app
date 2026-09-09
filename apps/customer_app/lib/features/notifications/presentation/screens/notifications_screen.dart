import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers/helper_functions.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/empty_state.dart';
import '../../data/notification_model.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final isDark = AppHelperFunctions.isDarkMode(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.gray100,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: notifications.when(
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyNotifications();
          }

          final rows = _groupByDay(list);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: rows.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _UnreadHeader(unread: unread);
                }
                final row = rows[index - 1];
                return switch (row) {
                  _SectionHeader(:final label) => Padding(
                      padding: EdgeInsets.only(
                        top: index == 1 ? 4 : AppSpacing.lg,
                        bottom: AppSpacing.sm,
                      ),
                      child: Text(
                        label,
                        style: textTheme.labelMedium?.copyWith(
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  _NotificationRow(:final notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotificationTile(
                        notification: notification,
                        isDark: isDark,
                        onTap: () => _onTap(context, ref, notification),
                      ),
                    ),
                };
              },
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => AppErrorState(
          message: friendlyErrorMessage(e),
          onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
        ),
      ),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.isRead) {
      await ref.read(notificationsProvider.notifier).markRead(notification.id);
    }
    if (!context.mounted) return;

    final orderId = notification.orderId;
    if (orderId != null) {
      unawaited(context.push(RoutePaths.trackingWithId(orderId)));
      return;
    }

    if (notification.kind == CustomerNotificationKind.promo) {
      context.go(RoutePaths.offers);
    }
  }

  /// Splits a server-ordered (newest-first) list into Today / Yesterday /
  /// Earlier sections, interleaving header rows.
  List<_Row> _groupByDay(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String bucket(DateTime dt) {
      final d = DateTime(dt.year, dt.month, dt.day);
      if (d == today) return 'TODAY';
      if (d == yesterday) return 'YESTERDAY';
      return 'EARLIER';
    }

    final rows = <_Row>[];
    String? current;
    for (final n in items) {
      final label = bucket(n.createdAt);
      if (label != current) {
        current = label;
        rows.add(_SectionHeader(label));
      }
      rows.add(_NotificationRow(n));
    }
    return rows;
  }
}

// ---------------------------------------------------------------------------
// Rows
// ---------------------------------------------------------------------------

sealed class _Row {
  const _Row();
}

class _SectionHeader extends _Row {
  const _SectionHeader(this.label);
  final String label;
}

class _NotificationRow extends _Row {
  const _NotificationRow(this.notification);
  final AppNotification notification;
}

// ---------------------------------------------------------------------------
// Header strip
// ---------------------------------------------------------------------------

class _UnreadHeader extends StatelessWidget {
  const _UnreadHeader({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    final label = unread == 0
        ? "You're all caught up"
        : '$unread unread notification${unread == 1 ? '' : 's'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      title: 'All caught up',
      subtitle: 'Order updates and offers will show up here.',
    );
  }
}

// ---------------------------------------------------------------------------
// Tile
// ---------------------------------------------------------------------------

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  final AppNotification notification;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = _styleFor(notification.kind);
    final unread = !notification.isRead;
    final tappable = notification.hasOrder ||
        notification.kind == CustomerNotificationKind.promo;

    final surface = isDark ? AppColors.black400 : AppColors.surface;
    final borderColor = unread
        ? AppColors.primary.withValues(alpha: 0.35)
        : (isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Material(
        color: surface,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Unread accent strip.
                  if (unread) Container(width: 4, color: AppColors.primary),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconChip(icon: style.icon, tint: style.tint),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: unread
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (unread)
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 8, top: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                if (notification.body.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.body,
                                    style: textTheme.bodySmall?.copyWith(
                                      height: 1.35,
                                      color: isDark
                                          ? AppColors.white700
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _Pill(label: style.label, color: style.tint),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _relativeTime(notification.createdAt),
                                        style: textTheme.labelSmall?.copyWith(
                                          color: AppColors.textDisabled,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (tappable)
                                      Icon(
                                        Iconsax.arrow_right_3,
                                        size: 16,
                                        color: AppColors.textDisabled,
                                      ),
                                  ],
                                ),
                              ],
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
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.tint});
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: tint),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-category visual treatment
// ---------------------------------------------------------------------------

class _KindStyle {
  const _KindStyle(this.icon, this.tint, this.label);
  final IconData icon;
  final Color tint;
  final String label;
}

_KindStyle _styleFor(CustomerNotificationKind kind) {
  return switch (kind) {
    CustomerNotificationKind.orderPlaced =>
      const _KindStyle(Iconsax.receipt_2, AppColors.info, 'Order placed'),
    CustomerNotificationKind.orderUpdate =>
      const _KindStyle(Iconsax.box, AppColors.info, 'Order update'),
    CustomerNotificationKind.outForDelivery =>
      const _KindStyle(Iconsax.truck_fast, AppColors.warning, 'On the way'),
    CustomerNotificationKind.delivered =>
      const _KindStyle(Iconsax.tick_circle, AppColors.success, 'Delivered'),
    CustomerNotificationKind.deliveryOtp => const _KindStyle(
        Iconsax.security_user, AppColors.success, 'Delivery code'),
    CustomerNotificationKind.promo =>
      const _KindStyle(Iconsax.discount_shape, AppColors.primary, 'Offer'),
    CustomerNotificationKind.system =>
      const _KindStyle(Iconsax.notification, AppColors.textSecondary, 'Update'),
  };
}

/// Compact "time ago" label, falling back to an absolute date past a week.
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return AppHelperFunctions.formatDate(time);
}
