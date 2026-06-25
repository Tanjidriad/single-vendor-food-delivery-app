import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/order_workflow.dart';
import 'dispatch_status_chip.dart';
import 'order_channel_badge.dart';
import 'order_timer.dart';

/// Foodpanda-style collapsed order tile for the KDS kanban.
///
/// Designed for arm's-length scanning: large order number, channel pill,
/// elapsed stage timer, item summary, and a single primary action.
class OrderTile extends StatefulWidget {
  final dynamic order;
  final String? nextStatus;
  final String actionText;
  final VoidCallback onAction;
  final VoidCallback? onReject;
  final VoidCallback onTap;
  final Color accentColor;
  final bool compact;

  const OrderTile({
    super.key,
    required this.order,
    required this.nextStatus,
    required this.actionText,
    required this.onAction,
    required this.onTap,
    this.onReject,
    required this.accentColor,
    this.compact = false,
  });

  @override
  State<OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<OrderTile> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  @override
  void didUpdateWidget(OrderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateElapsed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final anchor = _timerAnchor;
    if (anchor == null) return;
    setState(() {
      _elapsed = DateTime.now().difference(anchor);
    });
  }

  DateTime? get _timerAnchor {
    final order = widget.order as Map<String, dynamic>;
    final canonical = OrderWorkflowMapper.getCanonicalStatus(order);
    final timerType = OrderWorkflowMapper.getTimerType(canonical);
    return OrderWorkflowMapper.getTimerAnchor(order, timerType);
  }

  int get _slaThresholdSeconds {
    final order = widget.order as Map<String, dynamic>;
    final canonical = OrderWorkflowMapper.getCanonicalStatus(order);
    final timerType = OrderWorkflowMapper.getTimerType(canonical);
    return switch (timerType) {
      TimerType.acceptance => order['slaAcceptSeconds'] as int? ?? 300,
      TimerType.preparation => order['slaPrepSeconds'] as int? ?? 1200,
      TimerType.pickupWait => order['slaPickupWaitSeconds'] as int? ?? 900,
      _ => 0,
    };
  }

  Color get _urgencyColor {
    final sla = _slaThresholdSeconds;
    if (sla <= 0) return AppColors.success;
    if (_elapsed.inSeconds < sla ~/ 2) return AppColors.success;
    if (_elapsed.inSeconds < sla) return AppColors.warning;
    return AppColors.error;
  }

  bool get _isOverdue => _slaThresholdSeconds > 0 && _elapsed.inSeconds >= _slaThresholdSeconds;

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final order = widget.order as Map<String, dynamic>;
    final orderNumber = order['orderNumber']?.toString() ?? '---';
    final items = (order['items'] as List<dynamic>?) ?? [];
    final totalQuantity = items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
    final isDark = _isDark(context);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: widget.compact ? 6 : 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white50,
          borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
          border: Border.all(
            color: _isOverdue ? _urgencyColor.withValues(alpha: 0.6) : (isDark ? AppColors.darkBorder : AppColors.gray200),
            width: _isOverdue ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top stripe for overdue warning.
              if (_isOverdue)
                Container(
                  height: 4,
                  color: _urgencyColor,
                ),
              Padding(
                padding: EdgeInsets.all(widget.compact ? 10 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: order #, channel, timer.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  '#$orderNumber',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    height: 1,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 10),
                              OrderChannelBadge(order: order),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildTimerChip(order),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Second row: item summary.
                    _buildItemSummary(items, totalQuantity, isDark),
                    const SizedBox(height: 8),

                    // Dispatch status chip (rider assignment).
                    DispatchStatusChip(order: order),
                    const SizedBox(height: 10),

                    // Third row: primary CTA.
                    _buildActionBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerChip(Map<String, dynamic> order) {
    final canonical = OrderWorkflowMapper.getCanonicalStatus(order);
    final timerType = OrderWorkflowMapper.getTimerType(canonical);
    if (timerType == TimerType.none) return const SizedBox.shrink();

    final anchor = OrderWorkflowMapper.getTimerAnchor(order, timerType);
    final prefix = OrderWorkflowMapper.getTimerLabelPrefix(timerType);
    final slaSeconds = _slaThresholdSeconds;

    return OrderStageTimer(
      timerType: timerType,
      startTime: anchor,
      labelPrefix: prefix,
      slaThresholdSeconds: slaSeconds,
      compact: true,
    );
  }

  Widget _buildItemSummary(List<dynamic> items, int totalQuantity, bool isDark) {
    if (items.isEmpty) {
      return Text(
        widget.order['itemsSummary']?.toString() ?? 'No items provided',
        style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final firstItems = items.take(2).toList();
    final remaining = totalQuantity - firstItems.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$totalQuantity item${totalQuantity == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.gray700 : AppColors.gray700,
          ),
        ),
        const SizedBox(height: 4),
        ...firstItems.map((item) {
          final qty = item['quantity'] ?? 1;
          final name = item['name']?.toString() ?? 'Item';
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '$qty x $name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
        if (remaining > 0)
          Text(
            '+ $remaining more',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.gray700 : AppColors.gray700,
            ),
          ),
      ],
    );
  }

  Widget _buildActionBar() {
    final showReject = widget.onReject != null;

    return Row(
      children: [
        if (showReject) ...[
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: widget.onReject,
                icon: const Icon(Iconsax.close_circle, size: 16),
                label: const Text('Reject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: showReject ? 2 : 1,
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: widget.accentColor == AppColors.warning 
                    ? AppColors.black500 
                    : AppColors.white50,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: widget.onAction,
              child: Text(
                widget.actionText,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
