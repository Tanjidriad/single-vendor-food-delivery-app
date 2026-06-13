import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens/app_tokens.dart';

/// Structural variants for [WSkeletonLoader].
///
/// - [table]: 5 horizontal bar placeholders matching a data table's rows.
/// - [kpiCards]: a row of rectangular blocks matching the KPI card grid.
/// - [chart]: a single rectangular block matching a chart container height.
/// - [generic]: a single configurable rectangular block.
enum WSkeletonVariant { table, kpiCards, chart, generic }

/// A placeholder UI that mirrors the structural layout of content while data
/// loads, using an animated shimmer effect.
///
/// The shimmer sweep cycles every 1.5 seconds (Requirement 15.1). The rendered
/// structure depends on [variant] (Requirement 15.2):
/// - [WSkeletonVariant.table] → [rowCount] (default 5) horizontal bars at the
///   data-row height.
/// - [WSkeletonVariant.kpiCards] → [cardCount] (default 4) rectangular blocks
///   matching KPI card dimensions.
/// - [WSkeletonVariant.chart] → a single rectangular block matching the chart
///   container height.
/// - [WSkeletonVariant.generic] → a single rectangular block of [height].
class WSkeletonLoader extends StatelessWidget {
  /// The structural variant that determines the placeholder layout.
  final WSkeletonVariant variant;

  /// Number of placeholder rows for [WSkeletonVariant.table]. Defaults to 5.
  final int rowCount;

  /// Number of placeholder cards for [WSkeletonVariant.kpiCards]. Defaults to 4.
  final int cardCount;

  /// Block height for [WSkeletonVariant.generic]. Ignored for other variants.
  final double height;

  const WSkeletonLoader({
    super.key,
    this.variant = WSkeletonVariant.generic,
    this.rowCount = 5,
    this.cardCount = 4,
    this.height = 200,
  });

  /// Shimmer cycle duration (Requirement 15.1).
  static const Duration shimmerPeriod = Duration(milliseconds: 1500);

  /// Data-row height used by the [WSkeletonVariant.table] placeholders.
  static const double _tableRowHeight = 64;

  /// KPI card height used by the [WSkeletonVariant.kpiCards] placeholders.
  static const double _kpiCardHeight = 88;

  /// Chart container height used by the [WSkeletonVariant.chart] placeholder.
  static const double _chartHeight = 300;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Shimmer.fromColors(
      baseColor: colors.gray200,
      highlightColor: colors.gray100,
      period: shimmerPeriod,
      child: _buildContent(colors),
    );
  }

  Widget _buildContent(ColorTokens colors) {
    return switch (variant) {
      WSkeletonVariant.table => _buildTable(colors),
      WSkeletonVariant.kpiCards => _buildKpiCards(colors),
      WSkeletonVariant.chart => _SkeletonBox(
          height: _chartHeight,
          radius: RadiusTokens.borderRadiusLg,
          color: colors.gray200,
        ),
      WSkeletonVariant.generic => _SkeletonBox(
          height: height,
          radius: RadiusTokens.borderRadiusMd,
          color: colors.gray200,
        ),
    };
  }

  /// Builds [rowCount] horizontal bar placeholders at the data-row height.
  Widget _buildTable(ColorTokens colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(rowCount, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == rowCount - 1 ? 0 : SpacingTokens.sm,
          ),
          child: SizedBox(
            height: _tableRowHeight,
            child: Center(
              child: _SkeletonBox(
                height: SpacingTokens.lg, // 16px horizontal bar
                radius: RadiusTokens.borderRadiusSm,
                color: colors.gray200,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Builds a row of [cardCount] rectangular blocks matching KPI card sizing.
  Widget _buildKpiCards(ColorTokens colors) {
    final blocks = <Widget>[];
    for (var i = 0; i < cardCount; i++) {
      blocks.add(
        Expanded(
          child: _SkeletonBox(
            height: _kpiCardHeight,
            radius: RadiusTokens.borderRadiusLg,
            color: colors.gray200,
          ),
        ),
      );
      if (i != cardCount - 1) {
        blocks.add(const SizedBox(width: SpacingTokens.lg)); // 16px gap
      }
    }
    return Row(children: blocks);
  }
}

/// A single opaque placeholder block used as a shimmer mask.
class _SkeletonBox extends StatelessWidget {
  final double height;
  final BorderRadius radius;
  final Color color;

  const _SkeletonBox({
    required this.height,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
      ),
    );
  }
}
