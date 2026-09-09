import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/kitchen_preferences.dart';
import '../widgets/kitchen_header.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Selected stats period: 'today' | 'week' | 'month'.
final statsPeriodProvider = NotifierProvider<StatsPeriodNotifier, String>(
  StatsPeriodNotifier.new,
);

class StatsPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'today';
  void set(String period) => state = period;
}

final kitchenStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final prefs = ref.watch(kitchenPreferencesProvider);
  final period = ref.watch(statsPeriodProvider);
  final res = await apiClient.get(
    '/orders/kitchen/stats?period=$period&includeTest=${prefs.showTestOrders}',
  );
  return Map<String, dynamic>.from(res.data as Map);
});

/// Raw finalized orders for today — backs the end-of-day Z-report screen,
/// which prints a per-order breakdown and so needs the order list (not the
/// aggregated stats payload).
final dailyStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final prefs = ref.watch(kitchenPreferencesProvider);
  final res = await apiClient.get(
    '/orders/kitchen/history?includeTest=${prefs.showTestOrders}',
  );
  return {'orders': res.data as List<dynamic>};
});

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class DailyStatsView extends ConsumerWidget {
  const DailyStatsView({super.key});

  static final _num = NumberFormat('#,##0');

  String _money(num? v) => '৳${_num.format((v ?? 0).round())}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(kitchenStatsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          const _StatsHeader(),
          Expanded(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Couldn\'t load stats.\n$err',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              data: (s) => RefreshIndicator(
                onRefresh: () => ref.refresh(kitchenStatsProvider.future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: _buildContent(context, ref, s, theme, isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> s,
    ThemeData theme,
    bool isDark,
  ) {
    final period = ref.watch(statsPeriodProvider);
    final netSales = (s['netSales'] as num?)?.toDouble() ?? 0;
    final netSalesPrev = (s['netSalesPrev'] as num?)?.toDouble() ?? 0;
    final orders = (s['orders'] as num?)?.toInt() ?? 0;
    final ordersPrev = (s['ordersPrev'] as num?)?.toInt() ?? 0;
    final completed = (s['completed'] as num?)?.toInt() ?? 0;
    final cancelled = (s['cancelled'] as num?)?.toInt() ?? 0;
    final avgOrder = (s['avgOrderValue'] as num?)?.toDouble() ?? 0;
    final avgPrep = (s['avgPrepMinutes'] as num?)?.toInt() ?? 0;
    final slaPrep = (s['slaPrepMinutes'] as num?)?.toInt() ?? 15;
    final split = (s['paymentSplit'] as Map?) ?? {};
    final online = (split['online'] as num?)?.toDouble() ?? 0;
    final cash = (split['cash'] as num?)?.toDouble() ?? 0;
    final series = (s['series'] as List?) ?? [];
    final topItems = (s['topItems'] as List?) ?? [];

    final finalized = completed + cancelled;
    final completionRate = finalized > 0
        ? (completed / finalized * 100).round()
        : 0;
    final cancelRate = finalized > 0
        ? (cancelled / finalized * 100).round()
        : 0;
    final prevLabel = period == 'week'
        ? 'vs last week'
        : period == 'month'
        ? 'vs last month'
        : 'vs yesterday';

    return [
      // ── Hero: net sales ──────────────────────────────────────────
      _Card(
        isDark: isDark,
        theme: theme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net sales',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(netSales),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: _DeltaChip(current: netSales, previous: netSalesPrev),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$prevLabel ${_money(netSalesPrev)}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // ── 2×2 KPI grid ─────────────────────────────────────────────
      Row(
        children: [
          Expanded(
            child: _MiniStat(
              theme: theme,
              isDark: isDark,
              label: 'Orders',
              value: '$orders',
              delta: orders - ordersPrev,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStat(
              theme: theme,
              isDark: isDark,
              label: 'Avg order',
              value: _money(avgOrder),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _MiniStat(
              theme: theme,
              isDark: isDark,
              label: 'Completed',
              value: '$completionRate%',
              sub: '$completed/$finalized',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStat(
              theme: theme,
              isDark: isDark,
              label: 'Cancelled',
              value: '$cancelled',
              sub: '$cancelRate%',
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),

      // ── Prep vs SLA ──────────────────────────────────────────────
      _PrepCard(
        theme: theme,
        isDark: isDark,
        avgPrep: avgPrep,
        slaPrep: slaPrep,
      ),
      const SizedBox(height: 18),

      // ── Orders by hour/day ───────────────────────────────────────
      if (series.isNotEmpty) ...[
        _SeriesChart(
          series: series,
          period: period,
          theme: theme,
          isDark: isDark,
        ),
        const SizedBox(height: 18),
      ],

      // ── Payment split ────────────────────────────────────────────
      if (online + cash > 0) ...[
        _PaymentSplit(
          theme: theme,
          isDark: isDark,
          online: online,
          cash: cash,
          money: _money,
        ),
        const SizedBox(height: 18),
      ],

      // ── Top items ────────────────────────────────────────────────
      if (topItems.isNotEmpty)
        _TopItems(items: topItems, theme: theme, isDark: isDark),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pink header: title + date + segmented period toggle (matches mockup)
// ─────────────────────────────────────────────────────────────────────────────
class _StatsHeader extends ConsumerWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(statsPeriodProvider);
    const items = [('today', 'Today'), ('week', '7 days'), ('month', 'Month')];
    final title = selected == 'week'
        ? 'Last 7 days'
        : selected == 'month'
        ? 'Last 30 days'
        : 'Today';
    final dateStr = DateFormat('EEE, d MMM').format(DateTime.now());

    return KitchenHeader(
      title: title,
      subtitle: dateStr,
      bottom: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: items.map((it) {
            final active = selected == it.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => ref.read(statsPeriodProvider.notifier).set(it.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    it.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.pandaPink : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card shell
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final ThemeData theme;
  final bool isDark;
  const _Card({required this.child, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.gray200,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : theme.dividerColor,
          width: 0.3,
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delta chip (↑/↓ percentage vs previous)
// ─────────────────────────────────────────────────────────────────────────────
class _DeltaChip extends StatelessWidget {
  final double current;
  final double previous;
  const _DeltaChip({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    if (previous <= 0) return const SizedBox.shrink();
    final pct = ((current - previous) / previous * 100).round();
    final up = pct >= 0;
    final color = up ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${pct.abs()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini stat tile (2×2 grid)
// ─────────────────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final String label;
  final String value;
  final String? sub;
  final int? delta;
  const _MiniStat({
    required this.theme,
    required this.isDark,
    required this.label,
    required this.value,
    this.sub,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.gray200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : theme.dividerColor,
          width: 0.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              if (delta != null && delta != 0)
                Text(
                  '${delta! > 0 ? '+' : ''}$delta',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: delta! > 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              if (sub != null)
                Text(
                  sub!,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Prep vs SLA
// ─────────────────────────────────────────────────────────────────────────────
class _PrepCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final int avgPrep;
  final int slaPrep;
  const _PrepCard({
    required this.theme,
    required this.isDark,
    required this.avgPrep,
    required this.slaPrep,
  });

  @override
  Widget build(BuildContext context) {
    final onTarget = avgPrep <= slaPrep;
    final color = onTarget ? AppColors.success : AppColors.error;
    final frac = slaPrep > 0 ? (avgPrep / slaPrep).clamp(0.0, 1.0) : 0.0;

    return _Card(
      theme: theme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Avg prep time',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  Icon(
                    onTarget ? Icons.check_circle_outline : Icons.error_outline,
                    size: 15,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    onTarget ? 'On target' : 'Over target',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${avgPrep}m',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'target ${slaPrep}m',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 6,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Orders-by-hour / by-day bar chart
// ─────────────────────────────────────────────────────────────────────────────
class _SeriesChart extends StatelessWidget {
  final List<dynamic> series; // [{label, value}]
  final String period;
  final ThemeData theme;
  final bool isDark;
  const _SeriesChart({
    required this.series,
    required this.period,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final values = series
        .map((e) => (e['value'] as num?)?.toInt() ?? 0)
        .toList();
    final maxVal = values.fold<int>(0, (m, v) => v > m ? v : m);
    final peakIdx = maxVal > 0 ? values.indexOf(maxVal) : -1;
    final nowHour = DateTime.now().hour;

    String peakLabel = '';
    if (peakIdx >= 0) {
      if (period == 'today') {
        final h = int.tryParse(series[peakIdx]['label'].toString()) ?? peakIdx;
        peakLabel = 'Peak ${_hourLabel(h)}';
      } else {
        final d = DateTime.tryParse(series[peakIdx]['label'].toString());
        if (d != null) peakLabel = 'Peak ${DateFormat('d MMM').format(d)}';
      }
    }

    return _Card(
      theme: theme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                period == 'today' ? 'Orders by hour' : 'Orders by day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (peakLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pandaPinkLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    peakLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pandaPink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final v = values[i];
                final frac = maxVal > 0 ? v / maxVal : 0.0;
                final isPeak = i == peakIdx && v > 0;
                final isNow =
                    period == 'today' &&
                    (int.tryParse(series[i]['label'].toString()) ?? -1) ==
                        nowHour;
                final color = v == 0
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
                    : isPeak
                    ? AppColors.pandaPink
                    : AppColors.pandaPink.withValues(alpha: 0.35 + 0.35 * frac);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (frac * 56).clamp(v > 0 ? 3.0 : 2.0, 56.0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                            border: isNow
                                ? Border.all(
                                    color: AppColors.pandaPink,
                                    width: 1,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          _axisLabels(values.length),
        ],
      ),
    );
  }

  String _hourLabel(int h) {
    final ampm = h < 12 ? 'a' : 'p';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12$ampm';
  }

  Widget _axisLabels(int count) {
    final style = TextStyle(
      fontSize: 9,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
    );
    final labels = <Widget>[];
    final step = period == 'today' ? 4 : (count <= 7 ? 1 : 5);
    for (var i = 0; i < count; i++) {
      String text = '';
      if (i % step == 0) {
        if (period == 'today') {
          final h = int.tryParse(series[i]['label'].toString()) ?? i;
          text = _hourLabel(h);
        } else {
          final d = DateTime.tryParse(series[i]['label'].toString());
          text = d != null ? DateFormat(count <= 7 ? 'E' : 'd').format(d) : '';
        }
      }
      labels.add(
        Expanded(
          child: Text(text, textAlign: TextAlign.center, style: style),
        ),
      );
    }
    return Row(children: labels);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment split
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentSplit extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final double online;
  final double cash;
  final String Function(num?) money;
  const _PaymentSplit({
    required this.theme,
    required this.isDark,
    required this.online,
    required this.cash,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final total = online + cash;
    final onlineFrac = total > 0 ? online / total : 0.0;

    return _Card(
      theme: theme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment split',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Row(
              children: [
                Expanded(
                  flex: (onlineFrac * 1000).round().clamp(0, 1000),
                  child: Container(height: 10, color: AppColors.pandaPink),
                ),
                Expanded(
                  flex: ((1 - onlineFrac) * 1000).round().clamp(0, 1000),
                  child: Container(height: 10, color: const Color(0xFFF0997B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legend(AppColors.pandaPink, 'Online ${money(online)}'),
              _legend(const Color(0xFFF0997B), 'Cash ${money(cash)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top items
// ─────────────────────────────────────────────────────────────────────────────
class _TopItems extends StatelessWidget {
  final List<dynamic> items; // [{name, count}]
  final ThemeData theme;
  final bool isDark;
  const _TopItems({
    required this.items,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = items.fold<int>(
      0,
      (m, e) =>
          (e['count'] as num).toInt() > m ? (e['count'] as num).toInt() : m,
    );

    return _Card(
      theme: theme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top items',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final rank = entry.key;
            final name = entry.value['name']?.toString() ?? 'Item';
            final count = (entry.value['count'] as num?)?.toInt() ?? 0;
            final frac = maxCount > 0 ? count / maxCount : 0.0;
            final isLast = rank == items.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      '${rank + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: frac,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.06),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.pandaPink.withValues(
                                alpha: 0.45 + 0.4 * frac,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '×$count',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
