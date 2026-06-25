import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_icons.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/media/app_food_image.dart';
import '../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../features/notifications/presentation/providers/notifications_providers.dart';

enum HomeTopBarVariant { surface, onPrimary }

class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({
    super.key,
    required this.locationLabel,
    this.variant = HomeTopBarVariant.surface,
    this.onLocationTap,
    this.onNotificationsTap,
  });

  final String locationLabel;
  final HomeTopBarVariant variant;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationsTap;

  bool get _onPrimary => variant == HomeTopBarVariant.onPrimary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).itemCount;
    final hasUnread = ref.watch(unreadNotificationCountProvider) > 0;
    final subtitleColor = _onPrimary ? AppColors.onPrimary.withValues(alpha: 0.85) : AppColors.textSecondary;
    final titleColor = _onPrimary ? AppColors.onPrimary : AppColors.textPrimary;
    final chevronColor = _onPrimary ? AppColors.onPrimary : AppColors.primary;

    return Row(
      children: [
        ClipOval(
          child: AppFoodImage(
            placeholderSeed: 'profile-avatar',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onLocationTap,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _onPrimary ? 'Good to see you' : 'Deliver to',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        fontSize: 12,
                      ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        locationLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: titleColor,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(AppIcons.chevronDown, size: 18, color: chevronColor),
                  ],
                ),
              ],
            ),
          ),
        ),
        _CircleIconButton(
          icon: AppIcons.notification,
          onTap: onNotificationsTap ?? () => context.push(RoutePaths.notifications),
          showBadge: hasUnread,
          onPrimary: _onPrimary,
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          icon: AppIcons.bag,
          onTap: () => context.push(RoutePaths.cart),
          badgeCount: cartCount,
          onPrimary: _onPrimary,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.showBadge = false,
    this.onPrimary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  final bool showBadge;
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPrimary ? AppColors.onPrimary.withValues(alpha: 0.15) : AppColors.surface,
      shape: CircleBorder(
        side: BorderSide(
          color: onPrimary ? AppColors.onPrimary.withValues(alpha: 0.25) : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: onPrimary ? AppColors.onPrimary : AppColors.textPrimary,
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                )
              else if (showBadge)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
