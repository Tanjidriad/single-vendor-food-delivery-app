import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/websockets/socket_service.dart';
import '../../../earnings/data/earnings_summary.dart';
import '../../../earnings/presentation/providers/earnings_summary_provider.dart';
import '../../../orders/data/active_order_view.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../orders/presentation/providers/rider_orders_provider.dart';
import '../../../profile/presentation/providers/rider_profile_provider.dart';
import '../providers/rider_online_controller.dart';

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

    final name = ref
        .watch(riderProfileProvider)
        .maybeWhen(data: (p) => p.fullName, orElse: () => 'Rider');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern slate-50 background
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ModernHeader(
              name: name,
              isOnline: isOnline,
              isToggling: isToggling,
              onToggle: () =>
                  ref.read(riderOnlineControllerProvider.notifier).toggle(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (activeOrder != null) ...[
                  _PremiumActiveDeliveryCard(
                    order: activeOrder,
                    orderRaw: activeOrderMap!,
                    onOpen: () => context.push(
                      RoutePaths.activeDelivery,
                      extra: activeOrderMap,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const _BentoStatsSummary(),
                const SizedBox(height: 100), // padding for bottom bar
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Standard Premium Header ──────────────────────────────────────────────────
// ── Standard Premium Header ──────────────────────────────────────────────────
class _ModernHeader extends StatelessWidget {
  const _ModernHeader({
    required this.name,
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
  });

  final String name;
  final bool isOnline;
  final bool isToggling;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    
    // Dynamic Colors based on status
    final headerBg = isOnline ? AppColors.primary : Colors.white;
    final textPrimary = isOnline ? Colors.white : AppColors.textPrimary;
    final textSecondary = isOnline ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary;
    final iconBg = isOnline ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9);
    final toggleBg = isOnline ? Colors.black.withValues(alpha: 0.15) : const Color(0xFFF1F5F9);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: headerBg,
      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: Avatar + Name + Notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isOnline 
                        ? Colors.white.withValues(alpha: 0.2) 
                        : AppColors.primaryLight.withValues(alpha: 0.2),
                    child: Icon(
                      LucideIcons.user,
                      size: 20,
                      color: isOnline ? Colors.white : AppColors.primary,
                    ),
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
                onPressed: () {},
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

          // Status & Toggle Section - Clean and Native-feeling
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
                            ? [
                                const BoxShadow(
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
                            fontWeight: !isOnline ? FontWeight.w700 : FontWeight.w600,
                            color: !isOnline ? AppColors.textPrimary : textSecondary,
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
                            ? [
                                const BoxShadow(
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
                                  fontWeight: isOnline ? FontWeight.w700 : FontWeight.w600,
                                  color: isOnline ? AppColors.primary : AppColors.textSecondary,
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

// ── Premium Active Delivery Card ─────────────────────────────────────────────
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
            // Header
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

            // Body
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
                        color: const Color(0xFFE2E8F0),
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
            color: const Color(0xFFF1F5F9),
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

// ── Bento Grid Performance Summary ───────────────────────────────────────────
class _BentoStatsSummary extends ConsumerWidget {
  const _BentoStatsSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(earningsSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        summaryAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Could not load your stats right now.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          data: (summary) => Row(
            children: [
              Expanded(
                flex: 3,
                child: _BentoCard(
                  title: 'Today\'s Earnings',
                  value: formatCurrency(summary.todayTotal),
                  icon: LucideIcons.wallet,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _BentoCard(
                  title: 'Trips',
                  value: '${summary.tripCount}',
                  icon: LucideIcons.bike,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
