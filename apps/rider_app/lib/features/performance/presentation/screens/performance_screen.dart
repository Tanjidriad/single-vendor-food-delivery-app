import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/tab_loading_view.dart';
import '../../../../core/widgets/inputs/period_chip_row.dart';
import '../../../../core/widgets/layouts/app_card.dart';
import '../../../../core/widgets/layouts/metric_hero_card.dart';
import '../../../../core/widgets/layouts/rider_stack_scaffold.dart';
import '../../../../core/widgets/layouts/section_header.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../data/performance_summary.dart';
import '../providers/performance_provider.dart';

/// Rider quality dashboard: acceptance, completion, on-time, and rating.
class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  static const _periods = <String, String>{
    'day': 'Today',
    'week': 'Week',
    'month': 'Month',
    'all': 'All time',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(performanceSummaryProvider);
    final period = ref.watch(performancePeriodProvider);

    return RiderStackScaffold(
      title: 'My performance',
      onRefresh: () =>
          ref.read(performanceSummaryProvider.notifier).refresh(),
      body: Column(
        children: [
          PeriodChipRow(
            periods: _periods,
            selected: period,
            onSelected: (p) =>
                ref.read(performancePeriodProvider.notifier).setPeriod(p),
          ),
          Expanded(
            child: summaryAsync.when(
              loading: () => const TabLoadingView(style: TabLoadingStyle.heroAndList),
              error: (err, _) => ErrorStateView(
                message: err.toString().replaceAll('Exception: ', ''),
                onRetry: () =>
                    ref.read(performanceSummaryProvider.notifier).refresh(),
              ),
              data: (summary) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(performanceSummaryProvider.notifier).refresh(),
                child: _PerformanceBody(summary: summary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceBody extends StatelessWidget {
  const _PerformanceBody({required this.summary});

  final PerformanceSummary summary;

  String get _tip {
    final metrics = {
      'acceptance': summary.acceptanceRate,
      'completion': summary.completionRate,
      'on-time': summary.onTimeRate,
    };
    final lowest = metrics.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );
    return switch (lowest.key) {
      'acceptance' => 'Accept more offers when you are online to improve acceptance rate.',
      'completion' => 'Finish started deliveries to boost your completion rate.',
      _ => 'Plan your route ahead to improve on-time deliveries.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xxxl,
      ),
      children: [
        MetricHeroCard(
          label: 'Average rating',
          value: summary.ratingAvg.toStringAsFixed(2),
          subtitle: summary.ratingCount == 0
              ? 'No ratings yet'
              : '${summary.ratingCount} rating${summary.ratingCount == 1 ? '' : 's'}',
          margin: EdgeInsets.zero,
        ),
        const SectionHeader(title: 'Delivery metrics'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.45,
          children: [
            StatTile(
              icon: LucideIcons.checkCheck,
              value: '${summary.acceptanceRate}%',
              label: 'Acceptance',
              tone: StatTone.card,
            ),
            StatTile(
              icon: LucideIcons.packageCheck,
              value: '${summary.completionRate}%',
              label: 'Completion',
              tone: StatTone.card,
            ),
            StatTile(
              icon: LucideIcons.timer,
              value: '${summary.onTimeRate}%',
              label: 'On-time',
              tone: StatTone.card,
            ),
            StatTile(
              icon: LucideIcons.bike,
              value: '${summary.deliveries}',
              label: 'Deliveries',
              tone: StatTone.card,
            ),
          ],
        ),
        const SectionHeader(title: 'Coaching tip'),
        AppCard(
          margin: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.busy.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  LucideIcons.lightbulb,
                  color: AppColors.busy,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  _tip,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Order activity'),
        AppCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Row(
            children: [
              Expanded(
                child: _Count(
                  label: 'Offered',
                  value: summary.offered,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.borderLight,
              ),
              Expanded(
                child: _Count(
                  label: 'Accepted',
                  value: summary.accepted,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.borderLight,
              ),
              Expanded(
                child: _Count(
                  label: 'Cancelled',
                  value: summary.cancelledCount,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
