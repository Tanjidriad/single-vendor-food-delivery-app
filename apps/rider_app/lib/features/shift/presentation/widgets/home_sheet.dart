import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/delivery_row.dart';
import '../../../../core/widgets/feedback/app_shimmer_effect.dart';
import '../../../../core/widgets/feedback/empty_state_view.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../earnings/data/earnings_summary.dart';
import '../../../earnings/presentation/providers/earnings_summary_provider.dart';
import 'go_control.dart';

/// The persistent, draggable Home_Sheet that overlays the map on the home
/// screen (Requirement 1).
///
/// Implemented as a non-dismissible [DraggableScrollableSheet] intended to be
/// placed in the home screen's [Stack] above the `AppMapView` (Requirement
/// 1.1). It snaps between two positions — [collapsedSize] and [expandedSize] —
/// and the framework animates the drag between them (Requirement 1.8).
///
/// Content layered top-to-bottom inside the sheet's own [ScrollController]
/// (so dragging the body expands/collapses the sheet):
/// - a drag handle and the [GoControl] centerpiece;
/// - **collapsed** view (Requirement 1.2): today's total earnings and today's
///   trip count;
/// - **expanded** view (Requirement 1.3): the earnings breakdown, acceptance
///   rate, hours online, and recent deliveries.
///
/// The earnings values come from [earningsSummaryProvider] (Requirement 1.4),
/// which drives three render states:
/// - `loading` → [AppShimmerEffect] skeletons in place of the values
///   (Requirement 1.5);
/// - `error`   → an inline [ErrorStateView] whose retry control re-requests the
///   summary via `earningsSummaryProvider.notifier.refresh()` (Requirements
///   1.6, 1.7);
/// - `data`    → the parsed values.
class HomeSheet extends ConsumerWidget {
  const HomeSheet({
    super.key,
    this.collapsedSize = defaultCollapsedSize,
    this.expandedSize = defaultExpandedSize,
  });

  /// Default fraction of the screen height occupied while collapsed.
  ///
  /// Exposed so hosts (e.g. the home screen) can keep map overlays from
  /// colliding with the collapsed sheet (Requirement 2.7).
  static const double defaultCollapsedSize = 0.42;

  /// Default fraction of the screen height occupied while fully expanded.
  static const double defaultExpandedSize = 0.92;

  /// Fraction of the screen height occupied while collapsed (also the initial
  /// and minimum size). Sized to comfortably show the [GoControl] plus the
  /// collapsed earnings stats.
  final double collapsedSize;

  /// Fraction of the screen height occupied while fully expanded (maximum
  /// size), revealing the breakdown and recent deliveries.
  final double expandedSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(earningsSummaryProvider);

    return DraggableScrollableSheet(
      // Persistent + non-dismissible: it always overlays the map (Req 1.1).
      initialChildSize: collapsedSize,
      minChildSize: collapsedSize,
      maxChildSize: expandedSize,
      // Snap + animate between the collapsed and expanded positions (Req 1.8).
      snap: true,
      snapSizes: [collapsedSize, expandedSize],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
            border: const Border(
              top: BorderSide(color: AppColors.borderDark),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          // The inner scrollable MUST use the sheet's controller so dragging
          // the content expands/collapses the sheet (Req 1.8).
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl),
            children: [
              const _DragHandle(),
              const SizedBox(height: AppSpacing.md),
              // The GO control is the centerpiece of the collapsed sheet
              // (Requirement 2.1); it is independent of the earnings state.
              const Center(child: GoControl()),
              const SizedBox(height: AppSpacing.xl),
              // Earnings content switches on the remote-data state.
              ...summaryAsync.when(
                data: (summary) => _buildData(context, summary),
                loading: () => _buildLoading(context),
                error: (error, _) => _buildError(context, ref, error),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Data state (Requirements 1.2, 1.3, 1.4) -----------------------------

  List<Widget> _buildData(BuildContext context, EarningsSummary summary) {
    return [
      // Collapsed view: today's total earnings + trip count (Req 1.2).
      _CollapsedStats(
        todayTotal: Text(
          formatCurrency(summary.todayTotal),
          style: _valueStyle(),
        ),
        tripCount: Text(
          '${summary.tripCount}',
          style: _valueStyle(),
        ),
      ),
      const SizedBox(height: AppSpacing.xxl),
      const _SheetDivider(),
      const SizedBox(height: AppSpacing.xl),
      // Expanded view: breakdown, acceptance rate, hours online (Req 1.3).
      const _SectionTitle('Today\'s breakdown'),
      const SizedBox(height: AppSpacing.md),
      _BreakdownGrid(
        children: [
          StatTile(
            icon: LucideIcons.wallet,
            label: 'Earnings',
            value: formatCurrency(summary.todayTotal),
          ),
          StatTile(
            icon: LucideIcons.bike,
            label: 'Trips',
            value: '${summary.tripCount}',
          ),
          StatTile(
            icon: LucideIcons.percent,
            label: 'Acceptance',
            value: _formatAcceptance(summary.acceptanceRate),
          ),
          StatTile(
            icon: LucideIcons.clock,
            label: 'Hours online',
            value: summary.hoursOnline,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xxl),
      // Recent deliveries (Req 1.3) — empty state when there are none.
      const _SectionTitle('Recent deliveries'),
      const SizedBox(height: AppSpacing.sm),
      if (summary.recentDeliveries.isEmpty)
        const EmptyStateView(
          key: Key('home_sheet_recent_empty'),
          icon: LucideIcons.packageOpen,
          message: 'No deliveries yet today. Go online to start earning.',
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        )
      else
        ...summary.recentDeliveries.map(
          (entry) => DeliveryRow(
            title: entry.type,
            subtitle: entry.time,
            amount: formatCurrency(entry.amount),
          ),
        ),
    ];
  }

  // --- Loading state (Requirement 1.5) -------------------------------------

  List<Widget> _buildLoading(BuildContext context) {
    return [
      // Collapsed values replaced by shimmer skeletons (Req 1.5).
      const _CollapsedStats(
        todayTotal: AppShimmerEffect(width: 96, height: 26, radius: 8),
        tripCount: AppShimmerEffect(width: 48, height: 26, radius: 8),
      ),
      const SizedBox(height: AppSpacing.xxl),
      const _SheetDivider(),
      const SizedBox(height: AppSpacing.xl),
      const _SectionTitle('Today\'s breakdown'),
      const SizedBox(height: AppSpacing.md),
      const _BreakdownGrid(
        children: [
          AppShimmerEffect(width: double.infinity, height: 84, radius: 16),
          AppShimmerEffect(width: double.infinity, height: 84, radius: 16),
          AppShimmerEffect(width: double.infinity, height: 84, radius: 16),
          AppShimmerEffect(width: double.infinity, height: 84, radius: 16),
        ],
      ),
      const SizedBox(height: AppSpacing.xxl),
      const _SectionTitle('Recent deliveries'),
      const SizedBox(height: AppSpacing.md),
      ...List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: AppShimmerEffect(width: double.infinity, height: 60, radius: 16),
        ),
      ),
    ];
  }

  // --- Error state (Requirements 1.6, 1.7) ---------------------------------

  List<Widget> _buildError(BuildContext context, WidgetRef ref, Object error) {
    return [
      ErrorStateView(
        key: const Key('home_sheet_error'),
        message: error.toString().replaceAll('Exception: ', ''),
        // Retry re-requests the Earnings_Summary (Requirements 1.7, 9.4).
        onRetry: () => ref.read(earningsSummaryProvider.notifier).refresh(),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      ),
    ];
  }

  // --- Formatting helpers --------------------------------------------------

  /// Renders the acceptance rate as a percentage, or [kEarningsPlaceholder]
  /// when absent (Requirement 1.3). Tolerates both fractional (0..1) and
  /// already-percentage (0..100) payloads.
  String _formatAcceptance(double? rate) {
    if (rate == null) return kEarningsPlaceholder;
    final percent = rate <= 1 ? rate * 100 : rate;
    return '${percent.toStringAsFixed(0)}%';
  }

  TextStyle _valueStyle() {
    return const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    );
  }
}

/// The grab handle pill at the top of the sheet, signalling it is draggable.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.borderDark,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// Compact collapsed stats: today's total earnings and today's trip count
/// (Requirement 1.2). The value widgets are injected so the same layout can
/// host real values or shimmer skeletons.
class _CollapsedStats extends StatelessWidget {
  const _CollapsedStats({required this.todayTotal, required this.tripCount});

  final Widget todayTotal;
  final Widget tripCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CollapsedStat(
            label: 'Today',
            valueKey: const Key('home_sheet_today_total'),
            value: todayTotal,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _CollapsedStat(
            label: 'Trips',
            valueKey: const Key('home_sheet_trip_count'),
            value: tripCount,
          ),
        ),
      ],
    );
  }
}

class _CollapsedStat extends StatelessWidget {
  const _CollapsedStat({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final Widget value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        KeyedSubtree(key: valueKey, child: value),
      ],
    );
  }
}

/// A two-column responsive grid hosting the breakdown stat tiles. Built with
/// [Wrap] (rather than GridView) so it can live inside the sheet's [ListView]
/// without nested-scroll conflicts.
class _BreakdownGrid extends StatelessWidget {
  const _BreakdownGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const spacing = AppSpacing.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Section heading used between the breakdown and recent-deliveries blocks.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// A hairline divider themed for the dark sheet.
class _SheetDivider extends StatelessWidget {
  const _SheetDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderDark,
    );
  }
}
