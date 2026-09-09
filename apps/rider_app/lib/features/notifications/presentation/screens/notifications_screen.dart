import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/feedback/empty_state_view.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/tab_loading_view.dart';
import '../../../../core/widgets/layouts/rider_stack_scaffold.dart';
import '../../data/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final hasUnread = ref.watch(unreadNotificationCountProvider) > 0;

    return RiderStackScaffold(
      title: 'Notifications',
      actions: [
        if (hasUnread)
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
      onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
      body: notificationsAsync.when(
        loading: () => const TabLoadingView(),
        error: (err, _) => ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateView(
              icon: LucideIcons.bell,
              title: "You're all caught up",
              message: 'New assignments and updates will appear here.',
            );
          }

          final rows = _groupByDay(notifications);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return switch (row) {
                  _SectionHeader(:final label) => Padding(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : AppSpacing.lg,
                        bottom: AppSpacing.sm,
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                  _NotificationRow(:final notification) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _NotificationTile(
                        notification: notification,
                        onTap: () => _onTap(context, ref, notification),
                      ),
                    ),
                };
              },
            ),
          );
        },
      ),
    );
  }

  /// Tap routing is intentionally strict: only a *live* offer may re-open the
  /// full-screen accept flow. An expired offer (the common "old order that's
  /// already delivered" case) must never relaunch that screen.
  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.isRead) {
      await ref
          .read(notificationsProvider.notifier)
          .markRead(notification.id);
    }
    if (!context.mounted) return;

    if (notification.isActionableOffer) {
      unawaited(context.push(RoutePaths.incomingOrder, extra: notification.data));
      return;
    }

    if (notification.isOffer) {
      // Expired/claimed offer — there is nothing live to open.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('This delivery offer is no longer available.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final orderId = notification.orderId;
    if (orderId != null) {
      unawaited(context.push(RoutePaths.deliveredDetailFor(orderId)));
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

/// A renderable row in the notifications list: either a date header or an item.
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(notification.kind);
    final expiredOffer = notification.isExpiredOffer;
    final unread = !notification.isRead;

    // Expired offers are de-emphasised: they're history, not actions.
    final contentOpacity = expiredOffer ? 0.6 : 1.0;
    final bg = unread ? AppColors.primaryLight : AppColors.surfaceLight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Material(
        color: bg,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: unread ? AppColors.primaryDim : AppColors.borderLight,
              ),
              boxShadow: unread ? null : AppShadows.soft,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Unread accent strip.
                  if (unread)
                    Container(width: 4, color: AppColors.primary),
                  Expanded(
                    child: Opacity(
                      opacity: contentOpacity,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _IconChip(
                              icon: style.icon,
                              tint: expiredOffer
                                  ? AppColors.textDisabled
                                  : style.tint,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _body(style)),
                          ],
                        ),
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

  Widget _body(_KindStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      notification.isRead ? FontWeight.w600 : FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: AppSpacing.sm, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          notification.body,
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _StatusPill(notification: notification, style: style),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatRelativeTime(notification.createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The small status/category pill under the body — communicates whether an
/// offer is live or expired, otherwise labels the category.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.notification, required this.style});

  final AppNotification notification;
  final _KindStyle style;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (notification.kind) {
      NotificationKind.offer => notification.isExpiredOffer
          ? ('Expired', AppColors.textDisabled)
          : ('Tap to accept', AppColors.primary),
      _ => (style.label, style.tint),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
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
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: 20, color: tint),
    );
  }
}

/// Visual treatment per notification category.
class _KindStyle {
  const _KindStyle(this.icon, this.tint, this.label);
  final IconData icon;
  final Color tint;
  final String label;
}

_KindStyle _styleFor(NotificationKind kind) {
  return switch (kind) {
    NotificationKind.offer =>
      const _KindStyle(LucideIcons.package, AppColors.primary, 'Offer'),
    NotificationKind.orderUpdate => const _KindStyle(
        LucideIcons.packageCheck, AppColors.inProgress, 'Order update'),
    NotificationKind.deliveryOtp => const _KindStyle(
        LucideIcons.shieldCheck, AppColors.inProgress, 'Verification'),
    NotificationKind.payout =>
      const _KindStyle(LucideIcons.banknote, AppColors.online, 'Payout'),
    NotificationKind.approval =>
      const _KindStyle(LucideIcons.badgeCheck, AppColors.online, 'Approval'),
    NotificationKind.system =>
      const _KindStyle(LucideIcons.bell, AppColors.textSecondary, 'Update'),
  };
}
