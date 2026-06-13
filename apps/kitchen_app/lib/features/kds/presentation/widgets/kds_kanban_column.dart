import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/order_workflow.dart';

/// A single Kanban column for the Foodpanda-style KDS.
class KdsKanbanColumn extends StatelessWidget {
  final String title;
  final KitchenSection section;
  final int count;
  final Color accentColor;
  final List<dynamic> orders;
  final Widget Function(dynamic order) cardBuilder;
  final Widget? emptyState;
  final bool compact;

  const KdsKanbanColumn({
    super.key,
    required this.title,
    required this.section,
    required this.count,
    required this.accentColor,
    required this.orders,
    required this.cardBuilder,
    this.emptyState,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.gray100,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      margin: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: orders.isEmpty
                ? (emptyState ?? _defaultEmptyState(context))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12, vertical: compact ? 4 : 8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return cardBuilder(order)
                          .animate(key: ValueKey(order['id']))
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.05, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 10 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: accentColor.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultEmptyState(BuildContext context) {
    final (icon, headline, subtext) = switch (section) {
      KitchenSection.newOrders => (
          Icons.receipt_long,
          'No new orders',
          'New incoming orders will appear here.',
        ),
      KitchenSection.preparing => (
          Icons.restaurant,
          'Nothing preparing',
          'Accepted orders move here while being prepared.',
        ),
      KitchenSection.ready => (
          Icons.check_circle_outline,
          'Nothing ready',
          'Finished orders waiting for pickup show here.',
        ),
      _ => (
          Icons.receipt_long,
          'No ${title.toLowerCase()}',
          '',
        ),
    };

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: isDark ? AppColors.gray700 : AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.gray700,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtext.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtext,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.gray700 : AppColors.gray600,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
