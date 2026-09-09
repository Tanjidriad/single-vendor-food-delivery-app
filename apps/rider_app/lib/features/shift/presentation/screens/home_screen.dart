import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/websockets/socket_service.dart';
import '../../../orders/data/active_order_view.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../orders/presentation/providers/rider_orders_provider.dart';
import '../../../profile/presentation/providers/rider_profile_provider.dart';
import '../providers/rider_online_controller.dart';

/// Minimal home placeholder until the full map-first redesign ships.
/// Shows online toggle, approval status, resume-delivery card, and notifications.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen(orderStatusStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final data = next.value!;

        final activeOrder = ref.read(activeOrderProvider);
        if (activeOrder != null && activeOrder['id'] == data['orderId']) {
          final updatedOrder = Map<String, dynamic>.from(activeOrder);
          data.forEach((key, value) {
            updatedOrder[key] = value;
          });
          ref.read(activeOrderProvider.notifier).set(updatedOrder);
        }
        ref.invalidate(riderOrdersProvider);
      }
    });

    ref.listen(riderOnlineControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppColors.offline,
          ),
        );
      }
    });

    final isOnline = ref.watch(isOnlineProvider);
    final isToggling = ref.watch(
      riderOnlineControllerProvider.select((s) => s.isLoading),
    );
    final activeOrderMap = ref.watch(activeOrderProvider);
    final activeOrder = activeOrderMap == null
        ? null
        : ActiveOrderView.fromJson(activeOrderMap);

    final profileAsync = ref.watch(riderProfileProvider);
    final name = profileAsync.maybeWhen(
      data: (p) => p.fullName,
      orElse: () => 'Rider',
    );
    final avatarUrl = profileAsync.maybeWhen(
      data: (p) => p.avatarUrl,
      orElse: () => null,
    );
    final approvalStatus = profileAsync.maybeWhen(
      data: (p) => p.approvalStatus,
      orElse: () => 'APPROVED',
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ModernHeader(
              name: name,
              avatarUrl: avatarUrl,
              isOnline: isOnline,
              isToggling: isToggling,
              onToggle: () =>
                  ref.read(riderOnlineControllerProvider.notifier).toggle(),
              onNotifications: () => context.push(RoutePaths.notifications),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (approvalStatus != 'APPROVED') ...[
                  _ApprovalBanner(status: approvalStatus),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (activeOrder != null) ...[
                  _PremiumActiveDeliveryCard(
                    order: activeOrder,
                    orderRaw: activeOrderMap!,
                    onOpen: () => context.push(
                      RoutePaths.activeDelivery,
                      extra: activeOrderMap,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (activeOrder == null && isOnline)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppShadows.soft,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          LucideIcons.radio,
                          color: AppColors.online,
                          size: 24,
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            "You're online — waiting for delivery offers.",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (activeOrder == null && !isOnline)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppShadows.soft,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          LucideIcons.power,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Go online to start receiving delivery requests.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color color, String message) = switch (status) {
      'REJECTED' => (
          AppColors.offline,
          'Your application was rejected. Contact support for details.',
        ),
      'SUSPENDED' => (
          AppColors.offline,
          'Your account is suspended. Contact support to resolve.',
        ),
      _ => (
          AppColors.busy,
          'Your account is pending approval. Upload documents in Profile.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({
    required this.avatarUrl,
    required this.name,
    required this.isOnline,
  });

  final String? avatarUrl;
  final String name;
  final bool isOnline;

  String get _initial {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'R';
    return parts.first.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;
    final url = avatarUrl?.trim();
    final fallbackBg = isOnline
        ? Colors.white.withValues(alpha: 0.2)
        : AppColors.primaryLight.withValues(alpha: 0.2);
    final fallbackColor = isOnline ? Colors.white : AppColors.primary;

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: fallbackBg,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: fallbackBg,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: fallbackColor,
        ),
      ),
    );
  }
}

class _ModernHeader extends StatelessWidget {
  const _ModernHeader({
    required this.name,
    this.avatarUrl,
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
    required this.onNotifications,
  });

  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final bool isToggling;
  final VoidCallback onToggle;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    final headerBg = isOnline ? AppColors.primary : Colors.white;
    final textPrimary = isOnline ? Colors.white : AppColors.textPrimary;
    final textSecondary =
        isOnline ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary;
    final iconBg =
        isOnline ? Colors.white.withValues(alpha: 0.2) : AppColors.surfaceElevated;
    final toggleBg =
        isOnline ? Colors.black.withValues(alpha: 0.15) : AppColors.surfaceElevated;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: headerBg,
      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _HeaderAvatar(
                    avatarUrl: avatarUrl,
                    name: name,
                    isOnline: isOnline,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning,',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: onNotifications,
                icon: Icon(
                  LucideIcons.bell,
                  size: 22,
                  color: textPrimary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: iconBg,
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: toggleBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isOnline || isToggling ? onToggle : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isOnline ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: !isOnline
                            ? const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Offline',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                !isOnline ? FontWeight.w700 : FontWeight.w600,
                            color:
                                !isOnline ? AppColors.textPrimary : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: !isOnline || isToggling ? onToggle : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: isOnline
                            ? const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isToggling
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOnline ? AppColors.primary : Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Go Online',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      isOnline ? FontWeight.w700 : FontWeight.w600,
                                  color: isOnline
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumActiveDeliveryCard extends StatelessWidget {
  const _PremiumActiveDeliveryCard({
    required this.order,
    required this.orderRaw,
    required this.onOpen,
  });

  final ActiveOrderView order;
  final Map<String, dynamic> orderRaw;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final orderNumber = (orderRaw['orderNumber'] ?? '').toString();
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.navigation,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACTIVE DELIVERY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          orderNumber.isEmpty
                              ? 'Current order'
                              : 'Order #$orderNumber',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _LocationRow(
                    icon: LucideIcons.store,
                    title: 'Pickup',
                    subtitle: order.restaurantName,
                    isFirst: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 19),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 2,
                        height: 24,
                        color: AppColors.borderLight,
                      ),
                    ),
                  ),
                  _LocationRow(
                    icon: LucideIcons.mapPin,
                    title: 'Dropoff',
                    subtitle: order.deliveryAddress,
                    isFirst: false,
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isFirst,
    this.iconColor = AppColors.textSecondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFirst;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
