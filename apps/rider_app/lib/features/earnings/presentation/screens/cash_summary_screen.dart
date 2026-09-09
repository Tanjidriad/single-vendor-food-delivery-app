import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/tab_loading_view.dart';
import '../../../../core/widgets/inputs/period_chip_row.dart';
import '../../../../core/widgets/layouts/app_card.dart';
import '../../../../core/widgets/layouts/rider_stack_scaffold.dart';
import '../../../../core/widgets/layouts/section_header.dart';
import '../../data/cash_summary.dart';
import '../providers/cash_summary_provider.dart';

/// COD cash reconciliation: shows how much the rider collected, how much to
/// hand to the restaurant, and how much to keep as their delivery earnings.
class CashSummaryScreen extends ConsumerWidget {
  const CashSummaryScreen({super.key});

  static const _periods = <String, String>{
    'day': 'Today',
    'week': 'Week',
    'month': 'Month',
    'all': 'All time',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(cashSummaryProvider);
    final period = ref.watch(cashPeriodProvider);

    return RiderStackScaffold(
      title: 'COD Cash',
      onRefresh: () => ref.read(cashSummaryProvider.notifier).refresh(),
      body: Column(
        children: [
          PeriodChipRow(
            periods: _periods,
            selected: period,
            onSelected: (p) => ref.read(cashPeriodProvider.notifier).setPeriod(p),
          ),
          Expanded(
            child: summaryAsync.when(
              loading: () => const TabLoadingView(style: TabLoadingStyle.heroAndList),
              error: (err, _) => ErrorStateView(
                message: err.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.read(cashSummaryProvider.notifier).refresh(),
              ),
              data: (summary) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(cashSummaryProvider.notifier).refresh(),
                child: _CashBody(summary: summary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashBody extends StatelessWidget {
  const _CashBody({required this.summary});

  final CashSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        _SummaryCard(summary: summary),
        const SizedBox(height: AppSpacing.lg),
        if (summary.entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxxl),
            child: Center(
              child: Text(
                'No COD deliveries in this period.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          )
        else ...[
          const SectionHeader(
            title: 'COD deliveries',
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          for (final entry in summary.entries) _CashRow(entry: entry),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          margin: EdgeInsets.zero,
          child: Text(
            'Hand food payment to the restaurant at end of shift. '
            'Your delivery fee is yours to keep.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final CashSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(LucideIcons.banknote, color: Colors.white, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'COD collected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            formatCurrency(summary.cashCollected),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          Text(
            'From ${summary.ordersCount} COD ${summary.ordersCount == 1 ? 'delivery' : 'deliveries'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: Colors.white.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SplitTile(
                  icon: LucideIcons.store,
                  label: 'Give to restaurant',
                  amount: summary.foodToRemit,
                  amountColor: Colors.redAccent.shade100,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _SplitTile(
                  icon: LucideIcons.wallet,
                  label: 'You keep',
                  amount: summary.deliveryFeeKept,
                  amountColor: Colors.greenAccent.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitTile extends StatelessWidget {
  const _SplitTile({
    required this.icon,
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  final IconData icon;
  final String label;
  final num amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatCurrency(amount),
          style: TextStyle(
            color: amountColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CashRow extends StatelessWidget {
  const _CashRow({required this.entry});

  final CashEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${entry.orderNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(entry.collected),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Give ${formatCurrency(entry.toRemit)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    ' · ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Keep ${formatCurrency(entry.kept)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
