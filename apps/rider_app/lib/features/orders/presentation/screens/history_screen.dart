import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/empty_state_view.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/tab_loading_view.dart';
import '../../../../core/widgets/layouts/rider_tab_scaffold.dart';
import '../../../../core/widgets/layouts/section_header.dart';
import '../../data/order_summary.dart';
import '../providers/rider_orders_provider.dart';
import '../widgets/order_summary_card.dart';

enum _HistoryFilter { all, delivered, cancelled }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(pastOrdersProvider);

    return RiderTabScaffold(
      title: 'History',
      subtitle: 'Past deliveries',
      onRefresh: () async => ref.invalidate(riderOrdersProvider),
      // The filter row is pinned at the top and stays visible across every
      // state (loading / empty / error / data), so switching to a filter with
      // no results never hides the chips.
      body: ColoredBox(
        color: AppColors.backgroundLight,
        child: Column(
          children: [
            _FilterRow(
              filter: _filter,
              onChanged: (f) => setState(() => _filter = f),
              labelFor: _filterLabel,
            ),
            Expanded(
              child: ordersAsync.when(
              loading: () => const TabLoadingView(style: TabLoadingStyle.card),
              error: (err, _) => _scrollableFill(
                ErrorStateView(
                  message: err.toString().replaceAll('Exception: ', ''),
                  onRetry: () => ref.invalidate(riderOrdersProvider),
                ),
              ),
              data: (orders) {
                final filtered = _applyFilter(orders);
                if (filtered.isEmpty) {
                  return _scrollableFill(
                    EmptyStateView(
                      icon: LucideIcons.clock,
                      title: 'No deliveries yet',
                      message: _filter == _HistoryFilter.all
                          ? 'Your completed deliveries will show up here.'
                          : 'No ${_filterLabel(_filter).toLowerCase()} deliveries yet.',
                    ),
                  );
                }

                final groups = _groupByDate(filtered);

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.md,
                    AppSpacing.screen,
                    AppSpacing.screen,
                  ),
                  children: [
                    for (final group in groups.entries) ...[
                      SectionHeader(
                        title: group.key,
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      ),
                      for (var i = 0; i < group.value.length; i++) ...[
                        OrderSummaryCard(
                          order: group.value[i],
                          onTap: () => context.push(
                            RoutePaths.deliveredDetailFor(group.value[i].id),
                            extra: group.value[i],
                          ),
                        ),
                        if (i < group.value.length - 1)
                          const SizedBox(height: AppSpacing.lg),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Wraps non-list states so [RefreshIndicator] always has a scrollable child.
  Widget _scrollableFill(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }

  String _filterLabel(_HistoryFilter f) => switch (f) {
        _HistoryFilter.all => 'All',
        _HistoryFilter.delivered => 'Delivered',
        _HistoryFilter.cancelled => 'Cancelled',
      };

  List<OrderSummary> _applyFilter(List<OrderSummary> orders) {
    return switch (_filter) {
      _HistoryFilter.all => orders,
      _HistoryFilter.delivered =>
        orders.where((o) => o.isDelivered).toList(),
      _HistoryFilter.cancelled =>
        orders.where((o) => o.isCancelled).toList(),
    };
  }

  Map<String, List<OrderSummary>> _groupByDate(List<OrderSummary> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<OrderSummary>>{};
    for (final order in orders) {
      final date = order.deliveredAt ?? order.placedAt;
      final label = date == null
          ? 'Earlier'
          : _dateLabel(date, today, yesterday);
      groups.putIfAbsent(label, () => []).add(order);
    }
    return groups;
  }

  String _dateLabel(DateTime date, DateTime today, DateTime yesterday) {
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return 'Earlier';
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.onChanged,
    required this.labelFor,
  });

  final _HistoryFilter filter;
  final ValueChanged<_HistoryFilter> onChanged;
  final String Function(_HistoryFilter) labelFor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        0,
      ),
      child: Row(
        children: [
          for (final entry in _HistoryFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(labelFor(entry)),
                selected: filter == entry,
                onSelected: (_) => onChanged(entry),
                showCheckmark: false,
                backgroundColor: AppColors.surfaceLight,
                side: const BorderSide(color: AppColors.borderLight),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: filter == entry
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
