import 'package:admin_app/features/dashboard/data/dashboard_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/layouts/breakpoints.dart';
import '../../../../core/widgets/w_error_state.dart';
import '../../../../core/widgets/w_skeleton_loader.dart';

/// Dashboard overview screen.
///
/// A compact, data-dense dashboard composed of a responsive KPI card grid, a
/// revenue line chart, and a recent activity feed (Requirement 7). The screen
/// is purely presentational — it consumes the existing
/// [dashboardMetricsProvider] and preserves the established Riverpod data flow.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Gap between major dashboard sections (Requirement 7.5).
  static const double _sectionGap = SpacingTokens.xxl; // 24px

  /// Gap between KPI cards (Requirement 7.5).
  static const double _kpiGap = SpacingTokens.lg; // 16px

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Container(
      color: colors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mode = Breakpoints.fromWidth(constraints.maxWidth);
          final padding = _contentPadding(mode);

          return metricsAsync.when(
            loading: () => _DashboardLoading(mode: mode, padding: padding),
            error: (err, stack) => Padding(
              padding: EdgeInsets.all(padding),
              child: WErrorState(
                message:
                    "We couldn't load the dashboard data. Please try again.",
                onRetry: () => ref.invalidate(dashboardMetricsProvider),
              ),
            ),
            data: (metrics) => _DashboardContent(
              mode: mode,
              padding: padding,
              metrics: metrics,
            ),
          );
        },
      ),
    );
  }

  /// Content-area padding per breakpoint (Requirement 16.7).
  static double _contentPadding(LayoutMode mode) => switch (mode) {
        LayoutMode.expanded => SpacingTokens.xxxl, // 32px
        LayoutMode.medium => SpacingTokens.xxl, // 24px
        LayoutMode.compact => SpacingTokens.lg, // 16px
      };

  /// KPI grid column count per breakpoint (Requirement 16.5).
  static int _kpiColumns(LayoutMode mode) => switch (mode) {
        LayoutMode.expanded => 4,
        LayoutMode.medium => 2,
        LayoutMode.compact => 1,
      };
}

/// The loaded dashboard layout: header, KPI grid, chart, and activity feed.
class _DashboardContent extends StatelessWidget {
  final LayoutMode mode;
  final double padding;
  final Map<String, dynamic> metrics;

  const _DashboardContent({
    required this.mode,
    required this.padding,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    final revenue = (metrics['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final activeOrders = (metrics['activeOrders'] as num?)?.toInt() ?? 0;
    final availableDrivers =
        (metrics['availableDrivers'] as num?)?.toInt() ?? 0;
    final totalCustomers = (metrics['totalCustomers'] as num?)?.toInt() ?? 0;
    final chartData = (metrics['chartData'] as List<dynamic>? ?? const [])
        .map((e) => (e as num).toDouble())
        .toList();
    final recentActivity =
        (metrics['recentActivity'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .take(10)
            .toList();

    final kpis = <_KpiData>[
      _KpiData(
        label: 'Total Revenue',
        value: '\$${revenue.toStringAsFixed(2)}',
        icon: Iconsax.wallet,
      ),
      _KpiData(
        label: 'Active Orders',
        value: '$activeOrders',
        icon: Iconsax.box,
      ),
      _KpiData(
        label: 'Available Drivers',
        value: '$availableDrivers',
        icon: Iconsax.car,
      ),
      _KpiData(
        label: 'Total Customers',
        value: '$totalCustomers',
        icon: Iconsax.people,
      ),
    ];

    return ListView(
      padding: EdgeInsets.all(padding),
      children: [
        Text(
          'Overview',
          style: tokens.typography.style(
            size: TypographyTokens.xxl,
            weight: TypographyTokens.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: DashboardScreen._sectionGap),

        // KPI card grid (responsive columns).
        _KpiGrid(
          kpis: kpis,
          columns: DashboardScreen._kpiColumns(mode),
        ),
        const SizedBox(height: DashboardScreen._sectionGap),

        // Chart + activity feed.
        if (mode == LayoutMode.compact) ...[
          _RevenueChartCard(chartData: chartData),
          const SizedBox(height: DashboardScreen._sectionGap),
          _RecentActivityCard(activity: recentActivity),
        ] else
          // A plain top-aligned Row (not IntrinsicHeight): the chart uses an
          // internal LayoutBuilder which cannot answer intrinsic-dimension
          // queries, so wrapping it in IntrinsicHeight crashes layout. Both
          // cards size to their own content instead.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _RevenueChartCard(chartData: chartData),
              ),
              const SizedBox(width: DashboardScreen._sectionGap),
              Expanded(
                flex: 1,
                child: _RecentActivityCard(activity: recentActivity),
              ),
            ],
          ),
      ],
    );
  }
}

/// Skeleton placeholder layout shown while dashboard data loads
/// (Requirement 7.6).
class _DashboardLoading extends StatelessWidget {
  final LayoutMode mode;
  final double padding;

  const _DashboardLoading({required this.mode, required this.padding});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return ListView(
      padding: EdgeInsets.all(padding),
      children: [
        Text(
          'Overview',
          style: tokens.typography.style(
            size: TypographyTokens.xxl,
            weight: TypographyTokens.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: DashboardScreen._sectionGap),
        WSkeletonLoader(
          variant: WSkeletonVariant.kpiCards,
          cardCount: DashboardScreen._kpiColumns(mode),
        ),
        const SizedBox(height: DashboardScreen._sectionGap),
        const WSkeletonLoader(variant: WSkeletonVariant.chart),
      ],
    );
  }
}

/// Immutable data holder for a single KPI card.
class _KpiData {
  final String label;
  final String value;
  final IconData icon;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
  });
}

/// Responsive KPI card grid laying cards into rows of [columns] with 16px gaps
/// (Requirements 7.1, 7.5, 16.5).
class _KpiGrid extends StatelessWidget {
  final List<_KpiData> kpis;
  final int columns;

  const _KpiGrid({required this.kpis, required this.columns});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < kpis.length; start += columns) {
      final rowItems = <Widget>[];
      for (var col = 0; col < columns; col++) {
        final index = start + col;
        if (col > 0) {
          rowItems.add(const SizedBox(width: DashboardScreen._kpiGap));
        }
        rowItems.add(
          Expanded(
            child: index < kpis.length
                ? _KpiCard(data: kpis[index])
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: DashboardScreen._kpiGap));
      }
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowItems));
    }
    return Column(children: rows);
  }
}

/// A single KPI card: muted label (sm, secondary), value (xl, w700), and a
/// small 16px secondary icon with no background shape (Requirements 7.1, 7.2).
class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.borderRadiusLg,
        border: Border.all(color: colors.border),
        boxShadow: ElevationTokens.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: tokens.typography.style(
                    size: TypographyTokens.sm,
                    weight: TypographyTokens.medium,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              // Small 16px secondary icon, no background shape (Req 7.1, 7.2).
              Icon(data.icon, size: 16, color: colors.textSecondary),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.style(
              size: TypographyTokens.xl,
              weight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Revenue line chart in a card container (Requirement 7.3).
///
/// Minimum height 300px, compact title (md, w600), axis labels (xs, secondary),
/// and a single primary-colored line at 2px width.
class _RevenueChartCard extends StatelessWidget {
  final List<double> chartData;

  const _RevenueChartCard({required this.chartData});

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    final axisStyle = tokens.typography.style(
      size: TypographyTokens.xs,
      color: colors.textSecondary,
    );

    final maxValue = chartData.isEmpty
        ? 1.0
        : chartData.reduce((a, b) => a > b ? a : b);
    final leftInterval = maxValue <= 0 ? 1.0 : (maxValue / 4).ceilToDouble();

    final spots = <FlSpot>[
      for (var i = 0; i < chartData.length; i++)
        FlSpot(i.toDouble(), chartData[i]),
    ];

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.borderRadiusLg,
        border: Border.all(color: colors.border),
        boxShadow: ElevationTokens.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Revenue Overview',
            style: tokens.typography.style(
              size: TypographyTokens.md,
              weight: TypographyTokens.semibold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
          // Fixed chart height: the LineChart needs bounded constraints (an
          // Expanded inside a min-height Column would leave it unbounded).
          SizedBox(
            height: 240,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'No revenue data',
                      style: tokens.typography.style(
                        size: TypographyTokens.sm,
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: leftInterval,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: colors.border,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: leftInterval,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: axisStyle,
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= chartData.length) {
                                return const SizedBox.shrink();
                              }
                              final label = i < _dayLabels.length
                                  ? _dayLabels[i]
                                  : '${i + 1}';
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: SpacingTokens.sm),
                                child: Text(label, style: axisStyle),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: colors.primary,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: colors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Recent activity feed card (Requirement 7.4).
///
/// Shows up to 10 items, each with an 8px status dot colored by activity type,
/// a description (sm), and a relative timestamp (xs, secondary).
class _RecentActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> activity;

  const _RecentActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.borderRadiusLg,
        border: Border.all(color: colors.border),
        boxShadow: ElevationTokens.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Recent Activity',
            style: tokens.typography.style(
              size: TypographyTokens.md,
              weight: TypographyTokens.semibold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          if (activity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
              child: Text(
                'No recent activity',
                style: tokens.typography.style(
                  size: TypographyTokens.sm,
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            ...activity.map(
              (item) => _ActivityItem(
                description: (item['title'] ?? '').toString(),
                timestamp: (item['time'] ?? '').toString(),
                dotColor: _activityColor((item['type'] ?? '').toString(), colors),
              ),
            ),
        ],
      ),
    );
  }

  /// Maps an activity type to its status-dot color (Requirement 7.4):
  /// success → completed, primary → new orders, error → failures,
  /// warning → alerts, info → general updates.
  static Color _activityColor(String type, ColorTokens colors) {
    return switch (type.toUpperCase()) {
      'SUCCESS' => colors.success,
      'NEW_ORDER' => colors.primary,
      'ERROR' => colors.error,
      'WARNING' => colors.warning,
      _ => colors.info,
    };
  }
}

/// A single recent-activity row: 8px status dot, description, and timestamp.
class _ActivityItem extends StatelessWidget {
  final String description;
  final String timestamp;
  final Color dotColor;

  const _ActivityItem({
    required this.description,
    required this.timestamp,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 8px status dot, vertically nudged to align with the first text line.
          Padding(
            padding: const EdgeInsets.only(top: SpacingTokens.xs + 1),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: tokens.typography.style(
                    size: TypographyTokens.sm,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs / 2),
                Text(
                  timestamp,
                  style: tokens.typography.style(
                    size: TypographyTokens.xs,
                    color: colors.textSecondary,
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
