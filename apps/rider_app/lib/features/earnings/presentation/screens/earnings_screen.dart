import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/delivery_row.dart';
import '../../../../core/widgets/feedback/empty_state_view.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/tab_loading_view.dart';
import '../../../../core/widgets/inputs/period_chip_row.dart';
import '../../../../core/widgets/layouts/link_row.dart';
import '../../../../core/widgets/layouts/metric_hero_card.dart';
import '../../../../core/widgets/layouts/rider_tab_scaffold.dart';
import '../../../../core/widgets/layouts/section_header.dart';
import '../../../../core/widgets/layouts/settings_group.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../providers/earnings_summary_provider.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  static const _periods = {
    'day': 'Today',
    'week': 'This Week',
    'month': 'This Month',
    'all': 'All Time',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(earningsSummaryProvider);
    final selectedPeriod = ref.watch(earningsPeriodProvider);

    return RiderTabScaffold(
      title: 'Earnings',
      onRefresh: () => ref.read(earningsSummaryProvider.notifier).refresh(),
      body: earningsAsync.when(
        loading: () => const TabLoadingView(style: TabLoadingStyle.heroAndList),
        error: (err, stack) => ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.read(earningsSummaryProvider.notifier).refresh(),
        ),
        data: (summary) {
          final periodLabel = switch (selectedPeriod) {
            'day' => "Today's earnings",
            'week' => "This week's earnings",
            'month' => "This month's earnings",
            _ => 'Lifetime earnings',
          };
          final availableBalance = summary.pendingBalance ?? 0;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PeriodChipRow(
                  periods: _periods,
                  selected: selectedPeriod,
                  onSelected: (value) =>
                      ref.read(earningsPeriodProvider.notifier).setPeriod(value),
                ),
              ),
              SliverToBoxAdapter(
                child: MetricHeroCard(
                  label: 'Available for payout',
                  value: formatCurrency(availableBalance),
                  subtitle:
                      'Paid out by operations weekly to your registered MFS number.',
                  footer: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                periodLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              formatCurrency(summary.todayTotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              tone: StatTone.onAccent,
                              icon: LucideIcons.bike,
                              value: '${summary.tripCount}',
                              label: 'Trips',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatTile(
                              tone: StatTone.onAccent,
                              icon: LucideIcons.clock,
                              value: summary.hoursOnline,
                              label: 'Online',
                            ),
                          ),
                          if (summary.acceptanceRate != null) ...[
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: StatTile(
                                tone: StatTone.onAccent,
                                icon: LucideIcons.checkCircle,
                                value: '${summary.acceptanceRate!.round()}%',
                                label: 'Accept',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.lg,
                    AppSpacing.screen,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'How your money works'),
                      SettingsGroup(
                        margin: EdgeInsets.zero,
                        children: [
                          const _InfoRow(
                            icon: LucideIcons.wallet,
                            title: 'Digital earnings',
                            subtitle:
                                'Delivery fees credited to your payout balance. '
                                'Operations transfers this to your MFS account.',
                          ),
                          LinkRow(
                            icon: LucideIcons.banknote,
                            title: 'COD cash',
                            subtitle:
                                'Physical cash from customers — separate from '
                                'your payout balance. View collected, remit & fees.',
                            onTap: () => context.push(RoutePaths.cash),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.md,
                    AppSpacing.screen,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'RECENT PAYOUTS',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                      if (summary.payoutReady) _ReadyChip(),
                    ],
                  ),
                ),
              ),
              if (summary.recentPayouts.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyStateView(
                    icon: LucideIcons.circleDollarSign,
                    title: 'No payouts yet',
                    message:
                        'When operations sends your earnings, transfers appear here.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final payout = summary.recentPayouts[index];
                        return DeliveryRow(
                          title: 'Payout sent',
                          subtitle: payout.dateLabel,
                          amount: formatCurrency(payout.amount),
                          icon: LucideIcons.arrowUpRight,
                          isPositive: false,
                          signed: true,
                        );
                      },
                      childCount: summary.recentPayouts.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SectionHeader(title: 'Recent deliveries')),
              if (summary.recentDeliveries.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyStateView(
                    icon: LucideIcons.packageOpen,
                    title: 'No deliveries yet',
                    message: 'Completed deliveries will show up here.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = summary.recentDeliveries[index];
                        return DeliveryRow(
                          title: item.type,
                          subtitle: item.time,
                          amount: formatCurrency(item.amount),
                          icon: LucideIcons.arrowDownLeft,
                          signed: true,
                        );
                      },
                      childCount: summary.recentDeliveries.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
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

class _ReadyChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.online.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: const Text(
        'Ready for payout',
        style: TextStyle(
          color: AppColors.online,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
